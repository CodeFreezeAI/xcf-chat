import Foundation
import Network
import CommonCrypto

public protocol WebServerDelegate: AnyObject {
    func webServer(_ server: WebServer, didReceiveMessage message: String, from client: WebSocketClient)
    func webServer(_ server: WebServer, clientDidConnect client: WebSocketClient)
    func webServer(_ server: WebServer, clientDidDisconnect client: WebSocketClient)
}

public class WebServer: ObservableObject {
    public weak var delegate: WebServerDelegate?
    
    private var listener: NWListener?
    private var clients: [WebSocketClient] = []
    private let queue = DispatchQueue(label: "WebServer", qos: .userInitiated)
    
    @Published public var isRunning = false
    @Published public var connectedClients: Int = 0
    
    private let rpId: String
    private let webAuthnManager: WebAuthnManager
    
    public init(rpId: String) {
        self.rpId = rpId
        self.webAuthnManager = WebAuthnManager(rpId: rpId)
    }
    
    public func start(on port: UInt16) {
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            
            // Set socket options for port reuse
            if let options = parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options {
                options.version = .v4
                options.hopLimit = 64
            }
            
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }
            
            listener?.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self?.isRunning = true
                        print("🌐 Web server listening on port \(port)")
                    case .failed(let error):
                        self?.isRunning = false
                        if error == .posix(.EADDRINUSE) {
                            print("🔴 Port \(port) is already in use. Please choose a different port.")
                            exit(1)
                        } else {
                            print("🔴 Web server failed: \(error)")
                        }
                    case .cancelled:
                        self?.isRunning = false
                        print("🟡 Web server stopped")
                    default:
                        break
                    }
                }
            }
            
            listener?.start(queue: queue)
            
        } catch let error as NWError {
            if error == .posix(.EADDRINUSE) {
                print("🔴 Port \(port) is already in use. Please choose a different port.")
                exit(1)
            } else {
                print("🔴 Failed to start web server: \(error)")
            }
        } catch {
            print("🔴 Failed to start web server: \(error)")
        }
    }
    
    public func stop() {
        listener?.cancel()
        listener = nil
        
        for client in clients {
            client.disconnect()
        }
        clients.removeAll()
        
        DispatchQueue.main.async {
            self.isRunning = false
            self.connectedClients = 0
        }
    }
    
    public func broadcast(_ message: String) {
        for client in clients {
            client.send(message)
        }
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        
        // Read the HTTP request headers first
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, isComplete, error in
            guard let self = self, let data = data else { return }
            
            let request = String(data: data, encoding: .utf8) ?? ""
            
            if request.contains("Upgrade: websocket") {
                // Handle WebSocket upgrade
                self.handleWebSocketUpgrade(connection, request: request)
            } else if request.contains("POST /upload") {
                // Handle file upload with special processing
                self.handleFileUploadRequest(connection, initialData: data, request: request)
            } else if request.starts(with: "POST") {
                // Handle POST requests: ensure we read the full body
                // Find Content-Length
                let lines = request.components(separatedBy: "\r\n")
                var contentLength: Int? = nil
                for line in lines {
                    if line.lowercased().hasPrefix("content-length:") {
                        let value = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true).last?.trimmingCharacters(in: .whitespaces)
                        contentLength = Int(value ?? "")
                        break
                    }
                }
                guard let contentLength = contentLength else {
                    self.handleHTTPRequest(connection, request: request)
                    return
                }
                // Find where headers end
                guard let headerEndRange = data.range(of: "\r\n\r\n".data(using: .utf8)!) else {
                    self.handleHTTPRequest(connection, request: request)
                    return
                }
                let bodyStart = headerEndRange.upperBound
                let bodyBytesReceived = data.count - bodyStart
                if bodyBytesReceived >= contentLength {
                    // All body received
                    self.handleHTTPRequest(connection, request: request)
                } else {
                    // Need to read more
                    var fullData = data
                    func readMore() {
                        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { moreData, _, _, _ in
                            if let moreData = moreData {
                                fullData.append(moreData)
                                let totalBodyBytes = fullData.count - bodyStart
                                if totalBodyBytes >= contentLength {
                                    let fullRequest = String(data: fullData, encoding: .utf8) ?? ""
                                    self.handleHTTPRequest(connection, request: fullRequest)
                                } else {
                                    readMore()
                                }
                            } else {
                                let fullRequest = String(data: fullData, encoding: .utf8) ?? ""
                                self.handleHTTPRequest(connection, request: fullRequest)
                            }
                        }
                    }
                    readMore()
                }
            } else {
                // Handle regular HTTP request
                self.handleHTTPRequest(connection, request: request)
            }
        }
    }
    
    private func handleHTTPRequest(_ connection: NWConnection, request: String) {
        let lines = request.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return }
        
        let components = requestLine.components(separatedBy: " ")
        guard components.count >= 2 else { return }
        
        let method = components[0]
        let path = components[1]
        
        let response: String
        let contentType: String
        var statusCode = "200 OK"
        
        switch (method, path) {
        case ("GET", "/"):
            response = generateIndexHTML()
            contentType = "text/html"
        case ("GET", "/chat.js"):
            response = generateChatJS(adminName: ADMIN_USERNAME)
            contentType = "application/javascript"
        case ("GET", "/style.css"):
            response = generateCSS()
            contentType = "text/css"
        case ("GET", "/manifest.json"):
            response = generateWebManifest()
            contentType = "application/json"
        case ("GET", "/browserconfig.xml"):
            response = generateBrowserConfig()
            contentType = "application/xml"
        case ("GET", "/favicon.ico"):
            handleFaviconRequest(connection)
            return
        case ("GET", "/chat-preview.png"):
            response = generatePreviewImageSVG()
            contentType = "image/svg+xml"
        case ("GET", let path) where path.hasPrefix("/icons/"):
            response = generateIconSVG(for: path)
            contentType = "image/svg+xml"
        case ("GET", let path) where path.hasPrefix("/files/"):
            handleFileServing(connection, path: path)
            return
        case ("GET", let path) where path.hasPrefix("/thumbnails/"):
            handleThumbnailServing(connection, path: path)
            return
        case ("POST", "/webauthn/register/begin"):
            handleWebAuthnRegisterBegin(connection, request: request)
            return
        case ("POST", "/webauthn/register/complete"):
            handleWebAuthnRegisterComplete(connection, request: request)
            return
        case ("POST", "/webauthn/authenticate/begin"):
            handleWebAuthnAuthenticateBegin(connection, request: request)
            return
        case ("POST", "/webauthn/authenticate/complete"):
            handleWebAuthnAuthenticateComplete(connection, request: request)
            return
        case ("POST", "/webauthn/username/check"):
            handleWebAuthnUsernameCheck(connection, request: request)
            return
        default:
            response = "404 Not Found"
            contentType = "text/plain"
            statusCode = "404 Not Found"
        }
        
        let httpResponse = """
        HTTP/1.1 \(statusCode)\r
        Content-Type: \(contentType)\r
        Content-Length: \(response.utf8.count)\r
        Connection: close\r
        Access-Control-Allow-Origin: *\r
        Access-Control-Allow-Methods: GET, POST, OPTIONS\r
        Access-Control-Allow-Headers: Content-Type\r
        \r
        \(response)
        """
        
        connection.send(content: httpResponse.data(using: .utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    private func handleWebAuthnRegisterBegin(_ connection: NWConnection, request: String) {
        print("[WebAuthn] RAW REQUEST:\n\(request)")
        // Extract request body
        guard let bodyStart = request.range(of: "\r\n\r\n")?.upperBound else {
            print("[WebAuthn] Could not find header/body separator in request")
            sendErrorResponse(connection, error: "Invalid request format")
            return
        }
        let bodyString = String(request[bodyStart...])
        print("[WebAuthn] BODY STRING:\n\(bodyString)")
        guard let bodyData = bodyString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
              let username = json["username"] as? String else {
            print("[WebAuthn] Could not parse JSON or missing username")
            sendErrorResponse(connection, error: "Invalid request body")
            return
        }
        
        do {
            let options = try webAuthnManager.generateRegistrationOptions(username: username)
            let responseData = try JSONSerialization.data(withJSONObject: options)
            sendJSONResponse(connection, json: String(data: responseData, encoding: .utf8) ?? "{}")
        } catch {
            sendErrorResponse(connection, error: "Failed to generate registration options")
        }
    }
    
    private func handleWebAuthnRegisterComplete(_ connection: NWConnection, request: String) {
        // Extract request body
        guard let bodyStart = request.range(of: "\r\n\r\n")?.upperBound else {
            sendErrorResponse(connection, error: "Invalid request format")
            return
        }
        
        let bodyString = String(request[bodyStart...])
        guard let bodyData = bodyString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
              let username = json["username"] as? String else {
            sendErrorResponse(connection, error: "Invalid request body")
            return
        }
        
        do {
            try webAuthnManager.verifyRegistration(username: username, credential: json)
            sendJSONResponse(connection, json: "{\"success\":true}")
        } catch {
            sendErrorResponse(connection, error: "Registration verification failed")
        }
    }
    
    private func handleWebAuthnAuthenticateBegin(_ connection: NWConnection, request: String) {
        // Extract request body
        guard let bodyStart = request.range(of: "\r\n\r\n")?.upperBound else {
            sendErrorResponse(connection, error: "Invalid request format")
            return
        }
        
        let bodyString = String(request[bodyStart...])
        guard let bodyData = bodyString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] else {
            sendErrorResponse(connection, error: "Invalid request body")
            return
        }
        
        let username = json["username"] as? String
        
        do {
            let options = try webAuthnManager.generateAuthenticationOptions(username: username)
            let responseData = try JSONSerialization.data(withJSONObject: options)
            sendJSONResponse(connection, json: String(data: responseData, encoding: .utf8) ?? "{}")
        } catch {
            sendErrorResponse(connection, error: "Failed to generate authentication options")
        }
    }
    
    private func handleWebAuthnAuthenticateComplete(_ connection: NWConnection, request: String) {
        // Extract request body
        guard let bodyStart = request.range(of: "\r\n\r\n")?.upperBound else {
            sendErrorResponse(connection, error: "Invalid request format")
            return
        }
        
        let bodyString = String(request[bodyStart...])
        guard let bodyData = bodyString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
              let username = json["username"] as? String else {
            sendErrorResponse(connection, error: "Invalid request body")
            return
        }
        
        do {
            let foundUsername = try webAuthnManager.verifyAuthentication(username: username, credential: json)
            let response: [String: Any] = [
                "success": true,
                "username": foundUsername ?? username
            ]
            let responseData = try JSONSerialization.data(withJSONObject: response)
            sendJSONResponse(connection, json: String(data: responseData, encoding: .utf8) ?? "{}")
        } catch {
            sendErrorResponse(connection, error: "Authentication verification failed")
        }
    }
    
    private func handleWebAuthnUsernameCheck(_ connection: NWConnection, request: String) {
        guard let bodyStart = request.range(of: "\r\n\r\n")?.upperBound else {
            sendErrorResponse(connection, error: "Invalid request format")
            return
        }
        let bodyString = String(request[bodyStart...])
        guard let bodyData = bodyString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
              let username = json["username"] as? String else {
            sendErrorResponse(connection, error: "Invalid request body")
            return
        }
        if webAuthnManager.isUsernameRegistered(username) == false {
            sendJSONResponse(connection, json: "{\"available\":true}")
        } else {
            sendJSONResponse(connection, json: "{\"available\":false,\"error\":\"Username already registered\"}")
        }
    }
    
    private func handleFileUploadRequest(_ connection: NWConnection, initialData: Data, request: String) {
        print("📥 Received upload request")

        // Find where headers end in the initial data
        guard let headerEndRange = initialData.range(of: "\r\n\r\n".data(using: .utf8)!) else {
            print("❌ Invalid HTTP request format (no header end)")
            sendErrorResponse(connection, error: "Invalid HTTP request format")
            return
        }

        let bodyData = initialData.subdata(in: headerEndRange.upperBound..<initialData.count)
        var allData = Data()
        allData.append(bodyData)
        
        // Get Content-Length from headers
        let contentLength: Int? = {
            let lines = request.components(separatedBy: "\r\n")
            for line in lines {
                if line.lowercased().hasPrefix("content-length:") {
                    let value = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true).last?.trimmingCharacters(in: .whitespaces)
                    return Int(value ?? "")
                }
            }
            return nil
        }()
        
        // Get boundary from Content-Type
        let boundary: String? = {
            let lines = request.components(separatedBy: "\r\n")
            for line in lines {
                if line.lowercased().hasPrefix("content-type:") && line.contains("boundary=") {
                    if let b = line.components(separatedBy: "boundary=").last {
                        return b.trimmingCharacters(in: .whitespaces)
                    }
                }
            }
            return nil
        }()
        
        print("📦 Content-Length:", contentLength ?? "none")
        print("🔍 Boundary:", boundary ?? "none")
        
        guard let expectedLength = contentLength, let boundary = boundary else {
            print("❌ Missing Content-Length or boundary")
            sendErrorResponse(connection, error: "Missing Content-Length or boundary")
            return
        }

        func readMore() {
            connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { data, _, isComplete, error in
                if let data = data, !data.isEmpty {
                    allData.append(data)
                    print("📦 Received additional data:", data.count, "bytes")
                }
                
                if allData.count >= expectedLength {
                    print("📦 Total data received:", allData.count, "bytes")
                    
                    // Parse multipart data
                    let parts = String(data: allData, encoding: .utf8)?
                        .components(separatedBy: "--\(boundary)")
                        .filter { !$0.isEmpty && !$0.contains("--") } ?? []
                    
                    print("📦 Found \(parts.count) parts")
                    
                    var fileData: Data?
                    var fileName: String?
                    var mimeType: String?
                    
                    for part in parts {
                        if part.contains("Content-Disposition: form-data") {
                            // Extract filename
                            if let filenameRange = part.range(of: "filename=\""),
                               let endQuoteRange = part[filenameRange.upperBound...].firstIndex(of: "\"") {
                                fileName = String(part[filenameRange.upperBound..<endQuoteRange])
                                print("📄 Original filename:", fileName ?? "none")
                            }
                            
                            // Extract Content-Type
                            if let contentTypeRange = part.range(of: "Content-Type: "),
                               let newlineRange = part[contentTypeRange.upperBound...].firstIndex(of: "\r\n") {
                                mimeType = String(part[contentTypeRange.upperBound..<newlineRange])
                                print("📄 MIME type:", mimeType ?? "none")
                            }
                            
                            // Extract file data
                            if let dataStart = part.range(of: "\r\n\r\n")?.upperBound {
                                let dataString = String(part[dataStart...])
                                fileData = dataString.data(using: .utf8)
                                print("📄 File data size:", fileData?.count ?? 0, "bytes")
                            }
                        }
                    }
                    
                    guard let data = fileData,
                          let originalName = fileName,
                          let mime = mimeType else {
                        print("❌ Missing required file data")
                        self.sendErrorResponse(connection, error: "Missing required file data")
                        return
                    }
                    
                    // Generate a unique filename
                    let fileExtension = (originalName as NSString).pathExtension
                    let uniqueFileName = "\(UUID().uuidString).\(fileExtension)"
                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let uploadsPath = documentsPath.appendingPathComponent("uploads")
                    let filePath = uploadsPath.appendingPathComponent(uniqueFileName)
                    
                    print("💾 Saving file to:", filePath.path)
                    
                    do {
                        try FileManager.default.createDirectory(at: uploadsPath, withIntermediateDirectories: true)
                        try data.write(to: filePath)
                        print("✅ File saved successfully")
                        
                        // Create and save the attachment
                        let attachment = FileAttachment(
                            fileName: uniqueFileName,
                            originalFileName: originalName,
                            mimeType: mime,
                            fileSize: Int64(data.count),
                            filePath: "uploads/\(uniqueFileName)",
                            thumbnailPath: nil
                        )
                        
                        // Save the attachment
                        PersistenceManager.shared.saveStandaloneAttachment(attachment)
                        print("✅ Attachment saved to persistence")
                        
                        // Return success response
                        let response: [String: Any] = [
                            "success": true,
                            "attachment": [
                                "id": attachment.id.uuidString,
                                "fileName": attachment.fileName,
                                "originalFileName": attachment.originalFileName,
                                "mimeType": attachment.mimeType,
                                "fileSize": attachment.fileSize,
                                "isImage": mime.starts(with: "image/")
                            ]
                        ]
                        
                        if let jsonData = try? JSONSerialization.data(withJSONObject: response),
                           let jsonString = String(data: jsonData, encoding: .utf8) {
                            print("📤 Sending response:", jsonString)
                            self.sendJSONResponse(connection, json: jsonString)
                        } else {
                            print("❌ Failed to create JSON response")
                            self.sendErrorResponse(connection, error: "Failed to create response")
                        }
                    } catch {
                        print("❌ Failed to save file:", error)
                        self.sendErrorResponse(connection, error: "Failed to save file: \(error.localizedDescription)")
                    }
                } else if error == nil {
                    readMore()
                } else {
                    print("❌ Error during upload:", error?.localizedDescription ?? "unknown error")
                    self.sendErrorResponse(connection, error: "Upload failed: \(error?.localizedDescription ?? "unknown error")")
                }
            }
        }
        
        readMore()
    }
    
    private func handleFileServing(_ connection: NWConnection, path: String) {
        let fileName = String(path.dropFirst(7)) // Remove "/files/"
        
        // Find the attachment by filename
        let allAttachments = PersistenceManager.shared.getAllAttachments()
        guard let attachment = allAttachments.first(where: { $0.fileName == fileName }) else {
            sendErrorResponse(connection, error: "File not found", statusCode: "404 Not Found")
            return
        }
        
        do {
            let fileData = try ChatFileManager.shared.getFileData(for: attachment)
            sendFileResponse(connection, data: fileData, mimeType: attachment.mimeType, fileName: attachment.originalFileName)
        } catch {
            sendErrorResponse(connection, error: "Failed to read file", statusCode: "500 Internal Server Error")
        }
    }
    
    private func handleThumbnailServing(_ connection: NWConnection, path: String) {
        let thumbnailPath = String(path.dropFirst(1)) // Remove leading "/"
        
        // Find the attachment by thumbnail path
        let allAttachments = PersistenceManager.shared.getAllAttachments()
        guard let attachment = allAttachments.first(where: { $0.thumbnailPath == thumbnailPath }) else {
            sendErrorResponse(connection, error: "Thumbnail not found", statusCode: "404 Not Found")
            return
        }
        
        do {
            if let thumbnailData = try ChatFileManager.shared.getThumbnailData(for: attachment) {
                sendFileResponse(connection, data: thumbnailData, mimeType: "image/jpeg", fileName: "thumbnail.jpg")
            } else {
                sendErrorResponse(connection, error: "Thumbnail not available", statusCode: "404 Not Found")
            }
        } catch {
            sendErrorResponse(connection, error: "Failed to read thumbnail", statusCode: "500 Internal Server Error")
        }
    }
    
    private func sendJSONResponse(_ connection: NWConnection, json: String) {
        let httpResponse = """
        HTTP/1.1 200 OK\r
        Content-Type: application/json\r
        Content-Length: \(json.utf8.count)\r
        Connection: close\r
        Access-Control-Allow-Origin: *\r
        \r
        \(json)
        """
        
        connection.send(content: httpResponse.data(using: .utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    private func sendFileResponse(_ connection: NWConnection, data: Data, mimeType: String, fileName: String) {
        let httpResponse = """
        HTTP/1.1 200 OK\r
        Content-Type: \(mimeType)\r
        Content-Length: \(data.count)\r
        Content-Disposition: inline; filename="\(fileName)"\r
        Connection: close\r
        Access-Control-Allow-Origin: *\r
        \r
        
        """
        
        var responseData = httpResponse.data(using: .utf8)!
        responseData.append(data)
        
        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    private func sendErrorResponse(_ connection: NWConnection, error: String, statusCode: String = "400 Bad Request") {
        let errorJSON = """
        {
            "success": false,
            "error": "\(error)"
        }
        """
        
        let httpResponse = """
        HTTP/1.1 \(statusCode)\r
        Content-Type: application/json\r
        Content-Length: \(errorJSON.utf8.count)\r
        Connection: close\r
        Access-Control-Allow-Origin: *\r
        \r
        \(errorJSON)
        """
        
        connection.send(content: httpResponse.data(using: .utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    private func handleWebSocketUpgrade(_ connection: NWConnection, request: String) {
        // Extract WebSocket key for handshake
        let lines = request.components(separatedBy: "\r\n")
        var webSocketKey = ""
        
        for line in lines {
            if line.hasPrefix("Sec-WebSocket-Key:") {
                webSocketKey = String(line.dropFirst(18).trimmingCharacters(in: .whitespaces))
                break
            }
        }
        
        // Generate WebSocket accept key
        let acceptKey = generateWebSocketAcceptKey(webSocketKey)
        
        let response = """
        HTTP/1.1 101 Switching Protocols\r
        Upgrade: websocket\r
        Connection: Upgrade\r
        Sec-WebSocket-Accept: \(acceptKey)\r
        \r
        
        """
        
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
            // Create WebSocket client
            let client = WebSocketClient(connection: connection)
            self.clients.append(client)
            
            DispatchQueue.main.async {
                self.connectedClients = self.clients.count
            }
            
            client.onMessage = { [weak self] message in
                self?.delegate?.webServer(self!, didReceiveMessage: message, from: client)
            }
            
            client.onDisconnect = { [weak self] in
                self?.clients.removeAll { $0 === client }
                DispatchQueue.main.async {
                    self?.connectedClients = self?.clients.count ?? 0
                }
                self?.delegate?.webServer(self!, clientDidDisconnect: client)
            }
            
            self.delegate?.webServer(self, clientDidConnect: client)
            client.startReceiving()
        })
    }
    
    private func generateWebSocketAcceptKey(_ key: String) -> String {
        let magicString = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        let combined = key + magicString
        let hash = combined.data(using: .utf8)!.sha1()
        return hash.base64EncodedString()
    }
    
    private func setupRoutes() {
        // Routes are now handled in handleHTTPRequest
    }
    
    // MARK: - Asset Generation Functions
    
    private func handleFaviconRequest(_ connection: NWConnection) {
        let faviconData = generateFaviconICO()
        let httpResponse = """
        HTTP/1.1 200 OK\r
        Content-Type: image/x-icon\r
        Content-Length: \(faviconData.count)\r
        Connection: close\r
        Access-Control-Allow-Origin: *\r
        Cache-Control: public, max-age=31536000\r
        \r
        """
        
        var responseData = Data()
        responseData.append(httpResponse.data(using: .utf8)!)
        responseData.append(faviconData)
        
        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    private func generateWebManifest() -> String {
        return """
        {
          "name": "XCF Chat - Secure Real-time Chat",
          "short_name": "XCF Chat",
          "description": "Secure real-time chat with emoji avatars and file sharing",
          "start_url": "/",
          "display": "standalone",
          "background_color": "#121212",
          "theme_color": "#007AFF",
          "orientation": "portrait-primary",
          "scope": "/",
          "icons": [
            {
              "src": "/icons/android-icon-36x36.png",
              "sizes": "36x36",
              "type": "image/png",
              "density": "0.75"
            },
            {
              "src": "/icons/android-icon-48x48.png",
              "sizes": "48x48",
              "type": "image/png",
              "density": "1.0"
            },
            {
              "src": "/icons/android-icon-72x72.png",
              "sizes": "72x72",
              "type": "image/png",
              "density": "1.5"
            },
            {
              "src": "/icons/android-icon-96x96.png",
              "sizes": "96x96",
              "type": "image/png",
              "density": "2.0"
            },
            {
              "src": "/icons/android-icon-144x144.png",
              "sizes": "144x144",
              "type": "image/png",
              "density": "3.0"
            },
            {
              "src": "/icons/android-icon-192x192.png",
              "sizes": "192x192",
              "type": "image/png",
              "density": "4.0"
            },
            {
              "src": "/icons/android-icon-512x512.png",
              "sizes": "512x512",
              "type": "image/png",
              "purpose": "any maskable"
            }
          ],
          "categories": ["social", "communication"],
          "lang": "en-US"
        }
        """
    }
    
    private func generateBrowserConfig() -> String {
        return """
        <?xml version="1.0" encoding="utf-8"?>
        <browserconfig>
          <msapplication>
            <tile>
              <square70x70logo src="/icons/ms-icon-70x70.png"/>
              <square150x150logo src="/icons/ms-icon-150x150.png"/>
              <square310x310logo src="/icons/ms-icon-310x310.png"/>
              <TileColor>#007AFF</TileColor>
            </tile>
          </msapplication>
        </browserconfig>
        """
    }
    
    private func generateFaviconICO() -> Data {
        // Generate a simple 16x16 ICO file with chat bubble emoji
        // ICO file format is complex, so we'll create a minimal one
        let iconData = Data([
            // ICO Header (6 bytes)
            0x00, 0x00, // Reserved
            0x01, 0x00, // Type (1 = ICO)
            0x01, 0x00, // Number of images
            
            // Image Directory Entry (16 bytes)
            0x10, // Width (16)
            0x10, // Height (16)
            0x00, // Color count (0 = >256 colors)
            0x00, // Reserved
            0x01, 0x00, // Color planes
            0x20, 0x00, // Bits per pixel (32)
            0x00, 0x04, 0x00, 0x00, // Image size (1024 bytes)
            0x16, 0x00, 0x00, 0x00, // Image offset (22 bytes)
            
            // PNG data (simplified - this would normally be a full PNG)
            // For simplicity, we'll use a minimal bitmap
        ] + Array(repeating: UInt8(0x00), count: 1024))
        
        return iconData
    }
    
    private func generatePreviewImageSVG() -> String {
        return """
        <svg width="1200" height="630" viewBox="0 0 1200 630" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <!-- Exact dark mode gradient from CSS -->
            <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" style="stop-color:#4a5568;stop-opacity:1" />
              <stop offset="100%" style="stop-color:#2d3748;stop-opacity:1" />
            </linearGradient>
            
            <!-- Dark modal backdrop -->
            <filter id="blur">
              <feGaussianBlur in="SourceGraphic" stdDeviation="2"/>
            </filter>
          </defs>
          
          <!-- Background - exact gradient from CSS -->
          <rect width="1200" height="630" fill="url(#bg)"/>
          
          <!-- Header - matches .header styling -->
          <rect x="50" y="50" width="1100" height="70" rx="12" fill="rgba(30, 30, 30, 0.95)" filter="url(#blur)"/>
          <text x="80" y="95" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="24" font-weight="600" fill="#cbd5e0">💬 XCF Chat</text>
          <!-- Fixed positioning for right-side text -->
          <text x="1050" y="78" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="14" font-weight="500" fill="#30D158" text-anchor="end">✅ Connected</text>
          <text x="1050" y="98" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="12" fill="#cbd5e0" text-anchor="end">3 users online</text>
          
          <!-- Main chat container - dark mode styling -->
          <rect x="50" y="140" width="1100" height="420" rx="15" fill="#1e1e1e" stroke="#2d3748" stroke-width="1"/>
          
          <!-- Sidebar - dark background -->
          <rect x="70" y="160" width="300" height="380" rx="12" fill="#121212"/>
          
          <!-- FIXED: User info section - proper emoji and text alignment -->
          <rect x="90" y="180" width="260" height="65" rx="8" fill="rgba(0,122,255,0.2)" stroke="#2d3748" stroke-width="1"/>
          <text x="110" y="218" font-size="20" fill="#e2e8f0" dominant-baseline="middle">👤</text>
          <text x="145" y="218" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="16" font-weight="600" fill="#e2e8f0" dominant-baseline="middle">You</text>
          
          <!-- Rooms section header -->
          <text x="110" y="280" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="18" font-weight="600" fill="#cbd5e0">Rooms</text>
          
          <!-- Active room (Lobby) - blue active state -->
          <rect x="90" y="295" width="260" height="45" rx="8" fill="#007AFF"/>
          <text x="110" y="323" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="16" font-weight="500" fill="white">Lobby</text>
          
          <!-- Inactive rooms - dark styling -->
          <rect x="90" y="350" width="260" height="45" rx="8" fill="#1e1e1e" stroke="#2d3748" stroke-width="1"/>
          <text x="110" y="378" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="14" fill="#e2e8f0">General</text>
          
          <rect x="90" y="405" width="260" height="45" rx="8" fill="#1e1e1e" stroke="#2d3748" stroke-width="1"/>
          <text x="110" y="433" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="14" fill="#e2e8f0">Random</text>
          
          <!-- Chat area - dark background -->
          <rect x="390" y="160" width="740" height="380" rx="12" fill="#1e1e1e"/>
          
          <!-- Chat header - dark styling -->
          <rect x="390" y="160" width="740" height="60" rx="12" fill="#1e1e1e" stroke="#2d3748" stroke-width="0 0 1 0"/>
          <text x="410" y="195" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="18" font-weight="600" fill="#e2e8f0">Lobby</text>
          
          <!-- Messages area with correct dark mode styling -->
          <g transform="translate(410, 240)">
            <!-- Message 1 - Other user (.message.other) - black background -->
            <rect x="0" y="0" width="300" height="50" rx="12" fill="#000000"/>
            <text x="15" y="20" font-size="14" fill="#e2e8f0">🐶</text>
            <text x="40" y="20" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="12" font-weight="600" fill="#e2e8f0">Alice</text>
            <text x="220" y="20" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="10" fill="#d1d5db">2:30 PM</text>
            <text x="15" y="40" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="12" fill="#e2e8f0">Hey everyone!</text>
            
            <!-- Message 2 - Own message (.message.own) - correct blue -->
            <rect x="420" y="60" width="280" height="50" rx="12" fill="#0a84ff"/>
            <text x="435" y="80" font-size="14" fill="white">👤</text>
            <text x="460" y="80" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="12" font-weight="600" fill="white">You</text>
            <text x="620" y="80" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="10" fill="rgba(255,255,255,0.8)">2:31 PM</text>
            <text x="435" y="100" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="12" fill="white">Hello! How's it going?</text>
            
            <!-- Message 3 - Other user -->
            <rect x="0" y="120" width="320" height="50" rx="12" fill="#000000"/>
            <text x="15" y="140" font-size="14" fill="#e2e8f0">🦊</text>
            <text x="40" y="140" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="12" font-weight="600" fill="#e2e8f0">Bob</text>
            <text x="240" y="140" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="10" fill="#d1d5db">2:32 PM</text>
            <text x="15" y="160" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="12" fill="#e2e8f0">Great! Love this chat app</text>
          </g>
          
          <!-- Message input area - 40px height -->
          <rect x="410" y="485" width="600" height="40" rx="20" fill="#2d3748" stroke="#2d3748" stroke-width="1"/>
          <text x="430" y="509" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="12" fill="#9ca3af">Type a message...</text>
          
          <!-- FIXED: Send button with properly aligned text -->
          <rect x="1020" y="485" width="100" height="40" rx="20" fill="#007AFF"/>
          <text x="1070" y="505" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="14" font-weight="500" fill="white" text-anchor="middle" dominant-baseline="central">Send</text>
          
          <!-- Title - repositioned to bottom -->
          <text x="600" y="600" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="28" font-weight="700" fill="white" text-anchor="middle">Secure Real-time Chat</text>
          
          <!-- Subtitle at very bottom -->
          <text x="600" y="620" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="14" fill="rgba(255,255,255,0.8)" text-anchor="middle">Anonymous • Passwordless • Emoji Avatars • WebAuthn FIDO2 Passkeys</text>
        </svg>
        """
    }
    
    private func generateIconSVG(for path: String) -> String {
        // Extract size from path (e.g., "/icons/apple-icon-60x60.png" -> "60")
        let components = path.components(separatedBy: "/")
        let filename = components.last ?? ""
        let sizeStr = filename.components(separatedBy: "-").last?.components(separatedBy: "x").first ?? "32"
        let size = Int(sizeStr) ?? 32
        
        return """
        <svg width="\(size)" height="\(size)" viewBox="0 0 \(size) \(size)" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="iconGrad" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" style="stop-color:#007AFF;stop-opacity:1" />
              <stop offset="100%" style="stop-color:#0056CC;stop-opacity:1" />
            </linearGradient>
          </defs>
          
          <!-- Background Circle -->
          <circle cx="\(size/2)" cy="\(size/2)" r="\(size/2 - 1)" fill="url(#iconGrad)"/>
          
          <!-- Chat Emoji 💬 -->
          <text x="\(size/2)" y="\(size/2 + size/8)" font-size="\(size * 3/4)" text-anchor="middle" dominant-baseline="middle">💬</text>
        </svg>
        """
    }
}

public class WebSocketClient {
    private let connection: NWConnection
    public var onMessage: ((String) -> Void)?
    public var onDisconnect: (() -> Void)?
    public var username: String?
    public var currentRoom: String?
    
    init(connection: NWConnection) {
        self.connection = connection
    }
    
    public func send(_ message: String) {
        let frame = createWebSocketFrame(message)
        connection.send(content: frame, completion: .contentProcessed { _ in })
    }
    
    public func disconnect() {
        connection.cancel()
    }
    
    func startReceiving() {
        receiveWebSocketFrame()
    }
    
    private func receiveWebSocketFrame() {
        connection.receive(minimumIncompleteLength: 2, maximumLength: 8192) { [weak self] data, _, isComplete, error in
            guard let self = self, let data = data, data.count >= 2 else {
                self?.onDisconnect?()
                return
            }
            
            if let message = self.parseWebSocketFrame(data) {
                self.onMessage?(message)
            }
            
            // Continue receiving
            self.receiveWebSocketFrame()
        }
    }
    
    private func parseWebSocketFrame(_ data: Data) -> String? {
        guard data.count >= 2 else { return nil }
        
        let firstByte = data[0]
        let secondByte = data[1]
        
        let opcode = firstByte & 0x0F
        let masked = (secondByte & 0x80) != 0
        var payloadLength = Int(secondByte & 0x7F)
        
        var offset = 2
        
        // Handle extended payload length
        if payloadLength == 126 {
            guard data.count >= offset + 2 else { return nil }
            payloadLength = Int(data[offset]) << 8 | Int(data[offset + 1])
            offset += 2
        } else if payloadLength == 127 {
            guard data.count >= offset + 8 else { return nil }
            // For simplicity, we'll limit to smaller messages
            return nil
        }
        
        // Handle masking
        var maskingKey: [UInt8] = []
        if masked {
            guard data.count >= offset + 4 else { return nil }
            maskingKey = Array(data[offset..<offset + 4])
            offset += 4
        }
        
        // Extract payload
        guard data.count >= offset + payloadLength else { return nil }
        var payload = Array(data[offset..<offset + payloadLength])
        
        // Unmask if necessary
        if masked {
            for i in 0..<payload.count {
                payload[i] ^= maskingKey[i % 4]
            }
        }
        
        // Convert to string (assuming text frame)
        if opcode == 1 {
            return String(data: Data(payload), encoding: .utf8)
        }
        
        return nil
    }
    
    private func createWebSocketFrame(_ message: String) -> Data {
        let payload = message.data(using: .utf8)!
        var frame = Data()
        
        // First byte: FIN (1) + RSV (000) + Opcode (0001 for text)
        frame.append(0x81)
        
        // Second byte: MASK (0) + Payload length
        if payload.count < 126 {
            frame.append(UInt8(payload.count))
        } else if payload.count < 65536 {
            frame.append(126)
            frame.append(UInt8(payload.count >> 8))
            frame.append(UInt8(payload.count & 0xFF))
        } else {
            // For simplicity, we'll limit message size
            frame.append(126)
            frame.append(UInt8(65535 >> 8))
            frame.append(UInt8(65535 & 0xFF))
        }
        
        // Payload
        frame.append(payload)
        
        return frame
    }
}

// Extension for SHA1 hashing
extension Data {
    func sha1() -> Data {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(self.count), &digest)
        }
        return Data(digest)
    }
}
