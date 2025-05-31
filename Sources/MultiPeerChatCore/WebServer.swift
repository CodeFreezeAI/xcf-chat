import Foundation
import Network
import Combine

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
    
    private let webAuthnManager = WebAuthnManager()
    
    public init() {}
    
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
            response = generateChatJS()
            contentType = "application/javascript"
        case ("GET", "/style.css"):
            response = generateCSS()
            contentType = "text/css"
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
              let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
              let username = json["username"] as? String else {
            sendErrorResponse(connection, error: "Invalid request body")
            return
        }
        
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
            try webAuthnManager.verifyAuthentication(username: username, credential: json)
            sendJSONResponse(connection, json: "{\"success\":true}")
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

// Import CommonCrypto for SHA1
import CommonCrypto 