import Foundation
import Network
import CommonCrypto

// MARK: - String Extension for Regex Matching
extension String {
    func matches(_ pattern: String) -> Bool {
        return range(of: pattern, options: .regularExpression) != nil
    }
}

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
    private let adminUsername: String
    private let webAuthnManager: WebAuthnManager
    private let port: UInt16?
    
    // Simple session storage for admin authentication
    private var adminSessions: [String: AdminSession] = [:]
    private let sessionTimeout: TimeInterval = 3600 // 1 hour
    
    private struct AdminSession {
        let sessionId: String
        let username: String
        let loginTime: Date
        let clientIP: String
        
        var isExpired: Bool {
            Date().timeIntervalSince(loginTime) > 3600 // 1 hour timeout
        }
    }
    
    public init(rpId: String, port: UInt16? = nil, adminUsername: String = "XCF Admin", storageBackend: WebAuthnStorageBackend = .json("")) {
        self.rpId = rpId
        self.adminUsername = adminUsername
        self.port = port
        
        // Try using a publicly accessible icon for better compatibility
        // For localhost, include the port number in the URL
        let iconUrl: String
        if rpId.lowercased() == "localhost", let port = port {
            iconUrl = "http://localhost:\(port)/icon-192.png"
        } else {
            iconUrl = "https://ui-avatars.com/api/?name=💬Chat&background=007AFF&color=white&size=192&format=png"
        }
        
        self.webAuthnManager = WebAuthnManager(
            rpId: rpId,
            storageBackend: storageBackend,
            rpName: "Multi-Peer Chat",
            rpIcon: iconUrl,
            defaultUserIcon: nil // Will use the automatic generation
        )
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
            
            // First check if this might be a binary upload by looking at the headers only
            let headerEndMarker = "\r\n\r\n".data(using: .utf8)!
            
            if let headerEndRange = data.range(of: headerEndMarker) {
                let headerData = data.subdata(in: 0..<headerEndRange.upperBound)
                if let headerString = String(data: headerData, encoding: .utf8) {
                    print("🔍 HEADER CHECK - Length: \(headerString.count)")
                    // Only check for uploads on POST requests with multipart data
                    if headerString.contains("POST /upload") || (headerString.contains("POST ") && headerString.lowercased().contains("multipart/form-data")) {
                        print("📤 Binary upload detected - using special binary handling")
                        self.handleFileUploadBinary(connection, initialData: data, headerString: headerString)
                        return
                    }
                }
            }
            
            let request = String(data: data, encoding: .utf8) ?? ""
            
            // Add comprehensive debugging for Cloudflare issues
            print("🔍 RAW REQUEST DATA (first 500 chars):")
            print(String(request.prefix(500)))
            print("🔍 REQUEST LENGTH: \(request.count)")
            
            // Parse request line to extract method and path
            let lines = request.components(separatedBy: "\r\n")
            let requestLine = lines.first ?? ""
            print("🔍 REQUEST LINE: '\(requestLine)'")
            let components = requestLine.components(separatedBy: " ")
            print("🔍 REQUEST COMPONENTS: \(components)")
            let method = components.count > 0 ? components[0] : ""
            let path = components.count > 1 ? components[1] : ""
            
            // Add logging for debugging Cloudflare issues
            print("🌐 Received request: \(method) \(path)")
            if method == "POST" && path == "/upload" {
                print("📤 Upload request detected - using special handling")
            }
            
            // Check for multipart upload regardless of path
            let isMultipartUpload = request.lowercased().contains("content-type: multipart/form-data")
            if isMultipartUpload {
                print("📤 Multipart upload detected by Content-Type")
            }
            
            if request.contains("Upgrade: websocket") {
                // Handle WebSocket upgrade
                self.handleWebSocketUpgrade(connection, request: request)
            } else if method == "OPTIONS" {
                // Handle CORS preflight
                self.handleCORSPreflight(connection, path: path)
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
        case ("GET", "/chatv1k.js"):
            response = generateChatJS(adminName: adminUsername)
            contentType = "application/javascript"
        case ("GET", "/stylev1k.css"):
            response = generateCSS()
            contentType = "text/css"
        // Admin Routes - REQUIRES AUTHENTICATION
        case ("GET", "/admin/index.html"), ("GET", "/admin/"), ("GET", "/admin"):
            // ALWAYS show login page first - no exceptions
            response = generateAdminLoginHTML()
            contentType = "text/html"
        case ("GET", "/admin/panel.html"):
            // Only show admin panel if authenticated
            if isAdminRequest(request) {
                response = generateAdminIndexHTML()
                contentType = "text/html"
            } else {
                response = "404 Not Found"
                contentType = "text/plain"
                statusCode = "404 Not Found"
            }
        case ("GET", "/admin/login.html"):
            response = generateAdminLoginHTML()
            contentType = "text/html"
        case ("GET", "/admin/admin.css"):
            response = generateAdminCSS()
            contentType = "text/css"
        case ("GET", "/admin/admin.js"):
            if isAdminRequest(request) {
                response = generateAdminJS()
                contentType = "application/javascript"
            } else {
                response = "401 Unauthorized"
                contentType = "text/plain"
                statusCode = "401 Unauthorized"
            }
        case ("GET", "/admin/admin-login.js"):
            response = generateAdminLoginJS()
            contentType = "application/javascript"
        case ("POST", "/admin/api/login"):
            handleAdminLogin(connection, request: request)
            return
        case ("GET", "/admin/api/users"):
            if isAdminRequest(request) || hasValidAdminSession(request) {
                handleAdminAPIUsers(connection, request: request)
                return
            } else {
                response = "401 Unauthorized"
                contentType = "text/plain"
                statusCode = "401 Unauthorized"
            }
        case ("POST", let path) where path.matches(#"/admin/api/users/[^/]+/toggle"#):
            if isAdminRequest(request) || hasValidAdminSession(request) {
                handleAdminAPIToggleUser(connection, request: request, path: path)
                return
            } else {
                response = "404 Not Found"
                contentType = "text/plain"
                statusCode = "404 Not Found"
            }
        case ("DELETE", let path) where path.matches(#"/admin/api/users/[^/]+"#):
            if isAdminRequest(request) || hasValidAdminSession(request) {
                handleAdminAPIDeleteUser(connection, request: request, path: path)
                return
            } else {
                response = "404 Not Found"
                contentType = "text/plain"
                statusCode = "404 Not Found"
            }
        case ("POST", "/admin/api/users/disable-by-ip"):
            if isAdminRequest(request) || hasValidAdminSession(request) {
                handleAdminAPIDisableByIP(connection, request: request)
                return
            } else {
                response = "404 Not Found"
                contentType = "text/plain"
                statusCode = "404 Not Found"
            }
        case ("GET", "/manifest.json"):
            response = generateWebManifest()
            contentType = "application/json"
        case ("GET", "/browserconfig.xml"):
            response = generateBrowserConfig()
            contentType = "application/xml"
        case ("GET", "/favicon.ico"):
            handleFaviconRequest(connection)
            return
        case ("GET", "/favicon.png"):
            handleSimpleFaviconPNG(connection)
            return
        case ("GET", let path) where (path.hasPrefix("/favicon-") && path.hasSuffix(".png")) || (path.hasPrefix("/icons/favicon-") && path.hasSuffix(".png")):
            handleFaviconPNGRequest(connection, path: path)
            return
        case ("GET", "/icon-192.png"):
            handleIconPNGRequest(connection, size: 192)
            return
        case ("GET", "/icon-512.png"):
            handleIconPNGRequest(connection, size: 512)
            return
        case ("GET", "/icon-180.png"):
            handleIconPNGRequest(connection, size: 180)
            return
        case ("GET", "/icon-152.png"):
            handleIconPNGRequest(connection, size: 152)
            return
        case ("GET", "/icon-144.png"):
            handleIconPNGRequest(connection, size: 144)
            return
        case ("GET", "/icon-120.png"):
            handleIconPNGRequest(connection, size: 120)
            return
        case ("GET", "/icon-114.png"):
            handleIconPNGRequest(connection, size: 114)
            return
        case ("GET", "/icon-96.png"):
            handleIconPNGRequest(connection, size: 96)
            return
        case ("GET", "/icon-72.png"):
            handleIconPNGRequest(connection, size: 72)
            return
        case ("GET", "/icon-64.png"):
            handleIconPNGRequest(connection, size: 64)
            return
        case ("GET", "/icon-60.png"):
            handleIconPNGRequest(connection, size: 60)
            return
        case ("GET", "/icon-57.png"):
            handleIconPNGRequest(connection, size: 57)
            return
        case ("GET", "/icon-48.png"):
            handleIconPNGRequest(connection, size: 48)
            return
        case ("GET", "/icon-32.png"):
            handleIconPNGRequest(connection, size: 32)
            return
        case ("GET", "/chat-preview.png"):
            response = generatePreviewImageSVG()
            contentType = "image/svg+xml"
        case ("GET", let path) where path.hasPrefix("/icons/"):
            handleAppleIconRequest(connection, path: path)
            return
        case ("GET", let path) where path.hasPrefix("/files/"):
            handleFileServing(connection, path: path)
            return
        case ("GET", let path) where path.hasPrefix("/thumbnails/"):
            handleThumbnailServing(connection, path: path)
            return
        case ("POST", "/upload"):
            // Handle file uploads using WebAuthn-style processing 
            handleFileUploadSimple(connection, request: request)
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
        // Extract client IP address
        let clientIP = extractClientIP(request, connection: connection)
        print("[WebServer] 📍 Registration IP: \(clientIP ?? "unknown")")
        
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
            try webAuthnManager.verifyRegistration(username: username, credential: json, clientIP: clientIP)
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
        print("[WebServer] 🔍 Received authentication completion request")
        
        // Extract client IP address
        let clientIP = extractClientIP(request, connection: connection)
        print("[WebServer] 📍 Client IP: \(clientIP ?? "unknown")")
        
        // Extract request body
        guard let bodyStart = request.range(of: "\r\n\r\n")?.upperBound else {
            print("[WebServer] ❌ Invalid request format - no body separator")
            sendErrorResponse(connection, error: "Invalid request format")
            return
        }
        
        let bodyString = String(request[bodyStart...])
        print("[WebServer] 📦 Request body length: \(bodyString.count)")
        
        guard let bodyData = bodyString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
              let username = json["username"] as? String else {
            print("[WebServer] ❌ Failed to parse request body or missing username")
            sendErrorResponse(connection, error: "Invalid request body")
            return
        }
        
        print("[WebServer] 🆔 Authentication request for username: '\(username)'")
        print("[WebServer] 📋 Credential data: \(json)")
        
        do {
            print("[WebServer] ✅ Calling WebAuthnManager.verifyAuthentication...")
            let foundUsername = try webAuthnManager.verifyAuthentication(username: username, credential: json, clientIP: clientIP)
            print("[WebServer] ✅ Authentication successful! Found username: \(foundUsername ?? "nil")")
            
            let response: [String: Any] = [
                "success": true,
                "username": foundUsername ?? username
            ]
            let responseData = try JSONSerialization.data(withJSONObject: response)
            if let jsonString = String(data: responseData, encoding: .utf8) {
                print("[WebServer] 📤 Sending success response: \(jsonString)")
                sendJSONResponse(connection, json: jsonString)
            } else {
                print("[WebServer] ❌ Failed to create JSON response")
                sendErrorResponse(connection, error: "Failed to create response")
            }
        } catch {
            print("[WebServer] ❌ Authentication verification failed with error: \(error)")
            print("[WebServer] ❌ Error type: \(type(of: error))")
            sendErrorResponse(connection, error: "Authentication verification failed: \(error)")
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
                        let extractedBoundary = b.trimmingCharacters(in: .whitespaces)
                        // The boundary in multipart data is just the extracted boundary, not with extra dashes
                        return extractedBoundary
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
                    
                    // Don't convert the entire data to string - it contains binary content
                    // Instead, find the boundary markers in the raw data
                    
                    let boundaryData = boundary.data(using: .utf8)!
                    print("🔍 EXTRACTED BOUNDARY: '\(boundary)'")
                    print("🔍 Looking for boundary in binary data...")
                    
                    // Find the first occurrence of the boundary
                    guard let firstBoundaryRange = allData.range(of: boundaryData) else {
                        print("❌ Could not find boundary in data")
                        self.sendErrorResponse(connection, error: "Invalid multipart format")
                        return
                    }
                    
                    print("✅ Found boundary at position \(firstBoundaryRange.lowerBound)")
                    
                    // Look for the form-data part after the first boundary
                    let afterFirstBoundary = allData[firstBoundaryRange.upperBound...]
                    
                    // Convert just the headers part to string to parse them
                    // Headers end at the first occurrence of \r\n\r\n
                    let headerEndMarker = "\r\n\r\n".data(using: .utf8)!
                    
                    guard let headerEndRange = afterFirstBoundary.range(of: headerEndMarker) else {
                        print("❌ Could not find end of headers")
                        self.sendErrorResponse(connection, error: "Invalid multipart headers")
                        return
                    }
                    
                    // Extract just the headers as string
                    let headerData = Data(afterFirstBoundary[..<headerEndRange.lowerBound])
                    guard let headerString = String(data: headerData, encoding: .utf8) else {
                        print("❌ Could not parse headers as UTF-8")
                        self.sendErrorResponse(connection, error: "Invalid header encoding")
                        return
                    }
                    
                    print("📄 Headers: \(headerString)")
                    
                    // Parse headers to extract filename and content type
                    var fileName: String?
                    var mimeType: String?
                    
                    if headerString.contains("Content-Disposition: form-data") {
                        // Extract filename
                        if let filenameMatch = headerString.range(of: "filename=\"") {
                            let fromFilename = headerString[filenameMatch.upperBound...]
                            if let endQuote = fromFilename.firstIndex(of: "\"") {
                                fileName = String(fromFilename[..<endQuote])
                                print("📄 Extracted filename: '\(fileName!)'")
                            }
                        }
                        
                        // Extract Content-Type - be more flexible with line endings
                        let contentTypePatterns = ["Content-Type: ", "content-type: "]
                        for pattern in contentTypePatterns {
                            if let contentTypeMatch = headerString.range(of: pattern, options: .caseInsensitive) {
                                let fromContentType = headerString[contentTypeMatch.upperBound...]
                                let mimeTypeString = String(fromContentType)
                                
                                // Try different line ending patterns
                                if let endLine = mimeTypeString.firstIndex(of: "\r") {
                                    mimeType = String(mimeTypeString[..<endLine])
                                } else if let endLine = mimeTypeString.firstIndex(of: "\n") {
                                    mimeType = String(mimeTypeString[..<endLine])
                                } else {
                                    // Take the whole remaining string if no line ending found
                                    mimeType = mimeTypeString.trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                                
                                if !mimeType!.isEmpty {
                                    print("📄 Extracted MIME type: '\(mimeType!)'")
                                    break
                                }
                            }
                        }
                        
                        // If still no MIME type found, try to infer from filename
                        if mimeType == nil || mimeType!.isEmpty {
                            print("⚠️ No MIME type found in headers, inferring from filename")
                            if let name = fileName {
                                let ext = (name as NSString).pathExtension.lowercased()
                                switch ext {
                                case "png": mimeType = "image/png"
                                case "jpg", "jpeg": mimeType = "image/jpeg"
                                case "gif": mimeType = "image/gif"
                                case "pdf": mimeType = "application/pdf"
                                case "txt": mimeType = "text/plain"
                                case "zip": mimeType = "application/zip"
                                default: mimeType = "application/octet-stream"
                                }
                                print("📄 Inferred MIME type: '\(mimeType!)'")
                            }
                        }
                    }
                    
                    // Extract the file data - it starts right after the header end marker
                    let fileDataStart = firstBoundaryRange.upperBound + headerData.count + headerEndMarker.count
                    
                    // Find the ending boundary
                    let endBoundaryPattern = "\r\n\(boundary)".data(using: .utf8)!
                    let fileDataSearchStart = fileDataStart
                    let remainingData = allData[fileDataSearchStart...]
                    
                    var fileData: Data
                    if let endBoundaryRange = remainingData.range(of: endBoundaryPattern) {
                        // Extract data up to the end boundary
                        fileData = Data(remainingData[..<endBoundaryRange.lowerBound])
                        print("📄 Extracted file data size: \(fileData.count) bytes (with end boundary)")
                    } else {
                        // No end boundary found, take all remaining data and trim manually
                        fileData = Data(remainingData)
                        
                        // Try to remove trailing boundary by looking at the end
                        if fileData.count > boundary.count + 10 {
                            let endPortion = Data(fileData.suffix(boundary.count + 10))
                            if let endString = String(data: endPortion, encoding: .utf8) {
                                if let lastBoundaryIndex = endString.lastIndex(of: "-") {
                                    let boundary_start = endString[..<lastBoundaryIndex].lastIndex(of: "\n") ?? endString.startIndex
                                    let trimLength = endString.distance(from: boundary_start, to: endString.endIndex)
                                    fileData = Data(fileData.dropLast(trimLength))
                                }
                            }
                        }
                        print("📄 Extracted file data size: \(fileData.count) bytes (manual trim)")
                    }
                    
                    guard let originalName = fileName,
                          let mime = mimeType,
                          !fileData.isEmpty else {
                        print("❌ Missing required file data - filename: \(fileName ?? "nil"), mimeType: \(mimeType ?? "nil"), dataSize: \(fileData.count)")
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
                        try fileData.write(to: filePath)
                        print("✅ File saved successfully")
                        
                        // Create and save the attachment
                        let attachment = FileAttachment(
                            fileName: uniqueFileName,
                            originalFileName: originalName,
                            mimeType: mime,
                            fileSize: Int64(fileData.count),
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
                        
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: response)
                            if let jsonString = String(data: jsonData, encoding: .utf8) {
                                print("📤 Sending response:", jsonString)
                                self.sendJSONResponse(connection, json: jsonString)
                            } else {
                                print("❌ Failed to convert JSON to string")
                                self.sendErrorResponse(connection, error: "Failed to create response")
                            }
                        } catch {
                            print("❌ Failed to serialize JSON response")
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
    
    private func handleFileUploadSimple(_ connection: NWConnection, request: String) {
        print("📥 Simple upload handler - received request")
        print("📦 Request length: \(request.count)")
        
        // For now, just return a success response to test if the route works
        let response: [String: Any] = [
            "success": true,
            "message": "Upload endpoint reached successfully",
            "requestLength": request.count
        ]
        
        do {
            let responseData = try JSONSerialization.data(withJSONObject: response)
            sendJSONResponse(connection, json: String(data: responseData, encoding: .utf8) ?? "{}")
        } catch {
            sendErrorResponse(connection, error: "Failed to create response")
        }
    }
    
    private func handleFileUploadBinary(_ connection: NWConnection, initialData: Data, headerString: String) {
        print("📥 Binary upload handler started")
        print("📦 Initial data length: \(initialData.count)")
        print("📦 Header length: \(headerString.count)")
        
        // Extract Content-Length from headers
        let contentLength: Int? = {
            let lines = headerString.components(separatedBy: "\r\n")
            for line in lines {
                if line.lowercased().hasPrefix("content-length:") {
                    let value = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true).last?.trimmingCharacters(in: .whitespaces)
                    return Int(value ?? "")
                }
            }
            return nil
        }()
        
        print("📦 Expected content length: \(contentLength ?? -1)")
        
        // Find where headers end
        let headerEndMarker = "\r\n\r\n".data(using: .utf8)!
        guard let headerEndRange = initialData.range(of: headerEndMarker) else {
            print("❌ Could not find header end in binary data")
            sendErrorResponse(connection, error: "Invalid HTTP request format")
            return
        }
        
        let bodyStart = headerEndRange.upperBound
        let initialBodyData = initialData.subdata(in: bodyStart..<initialData.count)
        var allBodyData = Data()
        allBodyData.append(initialBodyData)
        
        print("📦 Initial body data length: \(initialBodyData.count)")
        
        // If we have a content length, read until we have all the data
        if let expectedLength = contentLength {
            func readMoreBinary() {
                if allBodyData.count >= expectedLength {
                    print("📦 All binary data received: \(allBodyData.count) bytes")
                    processBinaryUpload(connection, bodyData: allBodyData, headerString: headerString)
                    return
                }
                
                connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { data, _, _, error in
                    if let data = data, !data.isEmpty {
                        allBodyData.append(data)
                        print("📦 Received more binary data: \(data.count) bytes, total: \(allBodyData.count)")
                        readMoreBinary()
                    } else {
                        print("📦 Binary read complete with \(allBodyData.count) bytes")
                        self.processBinaryUpload(connection, bodyData: allBodyData, headerString: headerString)
                    }
                }
            }
            readMoreBinary()
        } else {
            print("❌ No content length found")
            sendErrorResponse(connection, error: "Missing Content-Length header")
        }
    }
    
    private func processBinaryUpload(_ connection: NWConnection, bodyData: Data, headerString: String) {
        print("📦 Processing binary upload: \(bodyData.count) bytes")
        
        // Get boundary from Content-Type header
        let boundary: String? = {
            let lines = headerString.components(separatedBy: "\r\n")
            for line in lines {
                if line.lowercased().hasPrefix("content-type:") && line.contains("boundary=") {
                    if let b = line.components(separatedBy: "boundary=").last {
                        let extractedBoundary = b.trimmingCharacters(in: .whitespaces)
                        return extractedBoundary
                    }
                }
            }
            return nil
        }()
        
        guard let boundary = boundary else {
            print("❌ Missing boundary in multipart data")
            sendErrorResponse(connection, error: "Missing boundary")
            return
        }
        
        print("🔍 EXTRACTED BOUNDARY: '\(boundary)'")
        
        // Simple file extraction - look for filename and file data
        let allData = bodyData
        let boundaryData = boundary.data(using: .utf8)!
        
        // Find the first occurrence of the boundary
        guard let firstBoundaryRange = allData.range(of: boundaryData) else {
            print("❌ Could not find boundary in data")
            sendErrorResponse(connection, error: "Invalid multipart format")
            return
        }
        
        // Look for the form-data part after the first boundary
        let afterFirstBoundary = allData[firstBoundaryRange.upperBound...]
        
        // Find headers end
        let headerEndMarker = "\r\n\r\n".data(using: .utf8)!
        guard let headerEndRange = afterFirstBoundary.range(of: headerEndMarker) else {
            print("❌ Could not find end of headers")
            sendErrorResponse(connection, error: "Invalid multipart headers")
            return
        }
        
        // Extract headers
        let headerData = Data(afterFirstBoundary[..<headerEndRange.lowerBound])
        guard let headerString = String(data: headerData, encoding: .utf8) else {
            print("❌ Could not parse headers as UTF-8")
            sendErrorResponse(connection, error: "Invalid header encoding")
            return
        }
        
        print("📄 Headers: \(headerString)")
        
        // Parse filename and content type
        var fileName: String?
        var mimeType: String?
        
        if headerString.contains("Content-Disposition: form-data") {
            // Extract filename
            if let filenameMatch = headerString.range(of: "filename=\"") {
                let fromFilename = headerString[filenameMatch.upperBound...]
                if let endQuote = fromFilename.firstIndex(of: "\"") {
                    fileName = String(fromFilename[..<endQuote])
                    print("📄 Extracted filename: '\(fileName!)'")
                }
            }
            
            // Extract Content-Type
            if let contentTypeMatch = headerString.range(of: "Content-Type: ", options: .caseInsensitive) {
                let fromContentType = headerString[contentTypeMatch.upperBound...]
                let mimeTypeString = String(fromContentType)
                
                if let endLine = mimeTypeString.firstIndex(of: "\r") {
                    mimeType = String(mimeTypeString[..<endLine])
                } else if let endLine = mimeTypeString.firstIndex(of: "\n") {
                    mimeType = String(mimeTypeString[..<endLine])
                } else {
                    mimeType = mimeTypeString.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                if !mimeType!.isEmpty {
                    print("📄 Extracted MIME type: '\(mimeType!)'")
                }
            }
        }
        
        // Extract file data
        let fileDataStart = firstBoundaryRange.upperBound + headerData.count + headerEndMarker.count
        let remainingData = allData[fileDataStart...]
        
        // Find ending boundary
        let endBoundaryPattern = "\r\n\(boundary)".data(using: .utf8)!
        var fileData: Data
        if let endBoundaryRange = remainingData.range(of: endBoundaryPattern) {
            fileData = Data(remainingData[..<endBoundaryRange.lowerBound])
            print("📄 Extracted file data size: \(fileData.count) bytes (with end boundary)")
        } else {
            fileData = Data(remainingData)
            // Try to remove trailing boundary manually
            if fileData.count > boundary.count + 10 {
                let endPortion = Data(fileData.suffix(boundary.count + 10))
                if let endString = String(data: endPortion, encoding: .utf8) {
                    if let lastBoundaryIndex = endString.lastIndex(of: "-") {
                        let boundary_start = endString[..<lastBoundaryIndex].lastIndex(of: "\n") ?? endString.startIndex
                        let trimLength = endString.distance(from: boundary_start, to: endString.endIndex)
                        fileData = Data(fileData.dropLast(trimLength))
                    }
                }
            }
            print("📄 Extracted file data size: \(fileData.count) bytes (manual trim)")
        }
        
        // Infer MIME type if missing
        if mimeType == nil || mimeType!.isEmpty {
            if let name = fileName {
                let ext = (name as NSString).pathExtension.lowercased()
                switch ext {
                case "png": mimeType = "image/png"
                case "jpg", "jpeg": mimeType = "image/jpeg"
                case "gif": mimeType = "image/gif"
                case "pdf": mimeType = "application/pdf"
                case "txt": mimeType = "text/plain"
                case "zip": mimeType = "application/zip"
                default: mimeType = "application/octet-stream"
                }
                print("📄 Inferred MIME type: '\(mimeType!)'")
            }
        }
        
        guard let originalName = fileName,
              let mime = mimeType,
              !fileData.isEmpty else {
            print("❌ Missing required file data - filename: \(fileName ?? "nil"), mimeType: \(mimeType ?? "nil"), dataSize: \(fileData.count)")
            sendErrorResponse(connection, error: "Missing required file data")
            return
        }
        
        // Generate unique filename and save
        let fileExtension = (originalName as NSString).pathExtension
        let uniqueFileName = "\(UUID().uuidString).\(fileExtension)"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let uploadsPath = documentsPath.appendingPathComponent("uploads")
        let filePath = uploadsPath.appendingPathComponent(uniqueFileName)
        
        print("💾 Saving file to:", filePath.path)
        
        do {
            try FileManager.default.createDirectory(at: uploadsPath, withIntermediateDirectories: true)
            try fileData.write(to: filePath)
            print("✅ File saved successfully")
            
            // Create and save the attachment
            let attachment = FileAttachment(
                fileName: uniqueFileName,
                originalFileName: originalName,
                mimeType: mime,
                fileSize: Int64(fileData.count),
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
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: response)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("📤 Sending response:", jsonString)
                    self.sendJSONResponse(connection, json: jsonString)
                } else {
                    print("❌ Failed to convert JSON to string")
                    self.sendErrorResponse(connection, error: "Failed to create response")
                }
            } catch {
                print("❌ Failed to serialize JSON response")
                self.sendErrorResponse(connection, error: "Failed to create response")
            }
        } catch {
            print("❌ Failed to save file:", error)
            self.sendErrorResponse(connection, error: "Failed to save file: \(error.localizedDescription)")
        }
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
    
    private func handleCORSPreflight(_ connection: NWConnection, path: String) {
        let httpResponse = """
        HTTP/1.1 200 OK\r
        Access-Control-Allow-Origin: *\r
        Access-Control-Allow-Methods: GET, POST, OPTIONS\r
        Access-Control-Allow-Headers: Content-Type, Content-Length\r
        Access-Control-Max-Age: 86400\r
        Content-Length: 0\r
        Connection: close\r
        \r
        
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
        // Serve a simple SVG favicon that Safari will accept
        let faviconData = generateSimpleFaviconSVG()
        let httpResponse = """
        HTTP/1.1 200 OK\r
        Content-Type: image/svg+xml\r
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
    
    private func generateSimpleFaviconSVG() -> Data {
        // Generate a simple SVG favicon for Safari tabs
        let faviconSVG = """
        <svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
          <rect width="32" height="32" rx="6" fill="#007AFF"/>
          <circle cx="11" cy="14" r="6" fill="white" opacity="0.9"/>
          <circle cx="21" cy="18" r="4" fill="white" opacity="0.7"/>
          <circle cx="9" cy="14" r="1.5" fill="#007AFF"/>
          <circle cx="11" cy="14" r="1.5" fill="#007AFF"/>
          <circle cx="13" cy="14" r="1.5" fill="#007AFF"/>
        </svg>
        """
        
        return faviconSVG.data(using: .utf8) ?? Data()
    }
    
    private func handleSimpleFaviconPNG(_ connection: NWConnection) {
        // Create a simple base64 PNG data URL for maximum Safari compatibility
        let pngData = generateSimplePNGFavicon()
        let httpResponse = """
        HTTP/1.1 200 OK\r
        Content-Type: image/png\r
        Content-Length: \(pngData.count)\r
        Connection: close\r
        Access-Control-Allow-Origin: *\r
        Cache-Control: public, max-age=31536000\r
        \r
        """
        
        var responseData = Data()
        responseData.append(httpResponse.data(using: .utf8)!)
        responseData.append(pngData)
        
        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    private func generateSimplePNGFavicon() -> Data {
        // For maximum compatibility, return a minimal PNG-like data structure
        // This is a simple blue square encoded as a small PNG
        let simplePNG = """
        <svg width="32" height="32" xmlns="http://www.w3.org/2000/svg">
          <rect width="32" height="32" fill="#007AFF"/>
          <text x="16" y="20" text-anchor="middle" fill="white" font-size="16">💬</text>
        </svg>
        """
        
        return simplePNG.data(using: .utf8) ?? Data()
    }
    
    private func handleFaviconPNGRequest(_ connection: NWConnection, path: String) {
        // Extract size from favicon-32x32.png or /icons/favicon-32x32.png format
        let filename = path.replacingOccurrences(of: "/icons/", with: "").replacingOccurrences(of: "/", with: "")
        let sizeStr: String
        if filename.contains("favicon-") {
            let parts = filename.replacingOccurrences(of: "favicon-", with: "")
                             .replacingOccurrences(of: ".png", with: "")
            sizeStr = parts.components(separatedBy: "x").first ?? "32"
        } else {
            sizeStr = "32"
        }
        
        let size = Int(sizeStr) ?? 32
        
        // Generate proper macOS-compatible favicon SVG (but serve as SVG for Safari)
        let iconData = generateMacOSFaviconSVG(size: size)
        
        let httpResponse = """
        HTTP/1.1 200 OK\r
        Content-Type: image/svg+xml\r
        Content-Length: \(iconData.count)\r
        Connection: close\r
        Access-Control-Allow-Origin: *\r
        Cache-Control: public, max-age=31536000\r
        \r
        """
        
        var responseData = Data()
        responseData.append(httpResponse.data(using: .utf8)!)
        responseData.append(iconData)
        
        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    private func generateMacOSFaviconSVG(size: Int) -> Data {
        // Generate a macOS-specific favicon that looks like a proper app icon
        let gradientId = "macOSGrad\(size)" // Make ID unique per size
        let faviconSVG = """
        <svg width="\(size)" height="\(size)" viewBox="0 0 \(size) \(size)" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="\(gradientId)" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" style="stop-color:#007AFF;stop-opacity:1" />
              <stop offset="100%" style="stop-color:#0051D5;stop-opacity:1" />
            </linearGradient>
          </defs>
          
          <!-- macOS-style rounded rectangle background -->
          <rect width="\(size)" height="\(size)" rx="\(size/5)" fill="url(#\(gradientId))"/>
          
          <!-- Chat bubble icon optimized for small sizes -->
          <g transform="translate(\(size/2), \(size/2))">
            <!-- Main chat bubble -->
            <circle cx="-\(size/8)" cy="-\(size/16)" r="\(size/4)" fill="white" opacity="0.95"/>
            <!-- Smaller bubble -->
            <circle cx="\(size/8)" cy="\(size/16)" r="\(size/6)" fill="white" opacity="0.8"/>
            <!-- Chat dots -->
            <circle cx="-\(size/6)" cy="-\(size/16)" r="\(max(1, size/24))" fill="#007AFF"/>
            <circle cx="-\(size/8)" cy="-\(size/16)" r="\(max(1, size/24))" fill="#007AFF"/>
            <circle cx="-\(size/12)" cy="-\(size/16)" r="\(max(1, size/24))" fill="#007AFF"/>
          </g>
        </svg>
        """
        
        return faviconSVG.data(using: .utf8) ?? Data()
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
              "src": "/favicon.ico",
              "sizes": "16x16 32x32",
              "type": "image/x-icon"
            },
            {
              "src": "/icons/favicon-16x16.png",
              "sizes": "16x16",
              "type": "image/png"
            },
            {
              "src": "/icons/favicon-32x32.png",
              "sizes": "32x32",
              "type": "image/png"
            },
            {
              "src": "/icons/apple-icon-57x57.png",
              "sizes": "57x57",
              "type": "image/png"
            },
            {
              "src": "/icons/apple-icon-60x60.png",
              "sizes": "60x60",
              "type": "image/png"
            },
            {
              "src": "/icons/apple-icon-72x72.png",
              "sizes": "72x72",
              "type": "image/png"
            },
            {
              "src": "/icons/apple-icon-76x76.png",
              "sizes": "76x76",
              "type": "image/png"
            },
            {
              "src": "/icons/favicon-96x96.png",
              "sizes": "96x96",
              "type": "image/png"
            },
            {
              "src": "/icons/apple-icon-114x114.png",
              "sizes": "114x114",
              "type": "image/png"
            },
            {
              "src": "/icons/apple-icon-120x120.png",
              "sizes": "120x120",
              "type": "image/png"
            },
            {
              "src": "/icons/apple-icon-144x144.png",
              "sizes": "144x144",
              "type": "image/png"
            },
            {
              "src": "/icons/apple-icon-152x152.png",
              "sizes": "152x152",
              "type": "image/png"
            },
            {
              "src": "/icons/apple-icon-180x180.png",
              "sizes": "180x180",
              "type": "image/png"
            },
            {
              "src": "/icons/android-icon-192x192.png",
              "sizes": "192x192",
              "type": "image/png",
              "purpose": "any maskable"
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
        // Create a proper ICO file with embedded PNG data for macOS compatibility
        // ICO format: header + directory + PNG data
        
        // Generate a 32x32 PNG icon
        let pngData = generateMacOSFaviconPNG()
        
        // ICO Header (6 bytes)
        var icoData = Data([
            0x00, 0x00, // Reserved (must be 0)
            0x01, 0x00, // Type (1 = ICO)
            0x01, 0x00  // Number of images
        ])
        
        // Directory Entry (16 bytes)
        let pngSize = UInt32(pngData.count)
        let offset = UInt32(22) // 6 + 16 = 22 bytes header + directory
        
        icoData.append(contentsOf: [
            32,    // Width (32 pixels)
            32,    // Height (32 pixels)
            0,     // Color count (0 for PNG)
            0,     // Reserved
            1, 0,  // Color planes (little endian)
            32, 0, // Bits per pixel (little endian)
        ])
        
        // PNG size (little endian)
        icoData.append(UInt8(pngSize & 0xFF))
        icoData.append(UInt8((pngSize >> 8) & 0xFF))
        icoData.append(UInt8((pngSize >> 16) & 0xFF))
        icoData.append(UInt8((pngSize >> 24) & 0xFF))
        
        // Offset to PNG data (little endian)
        icoData.append(UInt8(offset & 0xFF))
        icoData.append(UInt8((offset >> 8) & 0xFF))
        icoData.append(UInt8((offset >> 16) & 0xFF))
        icoData.append(UInt8((offset >> 24) & 0xFF))
        
        // Append PNG data
        icoData.append(pngData)
        
        return icoData
    }
    
    private func generateMacOSFaviconPNG() -> Data {
        // Create a simple PNG-like data for macOS favicon
        // Since we can't easily generate real PNG without external libraries,
        // we'll create a minimal data structure
        
        // For now, return a minimal SVG that many systems will accept
        let faviconSVG = """
        <svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
          <rect width="32" height="32" rx="6" fill="#007AFF"/>
          <g transform="translate(16, 16)">
            <circle cx="-4" cy="-2" r="6" fill="white" opacity="0.9"/>
            <circle cx="3" cy="2" r="4" fill="white" opacity="0.7"/>
            <circle cx="-5" cy="-2" r="1" fill="#007AFF"/>
            <circle cx="-3" cy="-2" r="1" fill="#007AFF"/>
            <circle cx="-1" cy="-2" r="1" fill="#007AFF"/>
          </g>
        </svg>
        """
        
        return faviconSVG.data(using: .utf8) ?? Data()
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
    
    private func handleIconPNGRequest(_ connection: NWConnection, size: Int) {
        // Generate a simple PNG icon data
        let iconData = generateAppIconPNG(size: size)
        
        let httpResponse = """
        HTTP/1.1 200 OK\r
        Content-Type: image/svg+xml\r
        Content-Length: \(iconData.count)\r
        Connection: close\r
        Access-Control-Allow-Origin: *\r
        Cache-Control: public, max-age=31536000\r
        \r
        """
        
        var responseData = Data()
        responseData.append(httpResponse.data(using: .utf8)!)
        responseData.append(iconData)
        
        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    private func generateAppIconPNG(size: Int) -> Data {
        // Create a minimal PNG with a blue background and chat emoji
        // This is a simplified approach - in production you'd use a proper PNG library
        
        // For now, let's generate an SVG and indicate it's a PNG
        let svgIcon = """
        <svg width="\(size)" height="\(size)" viewBox="0 0 \(size) \(size)" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="iconGrad" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" style="stop-color:#007AFF;stop-opacity:1" />
              <stop offset="100%" style="stop-color:#0056CC;stop-opacity:1" />
            </linearGradient>
          </defs>
          
          <!-- Background Circle -->
          <circle cx="\(size/2)" cy="\(size/2)" r="\(size/2 - 2)" fill="url(#iconGrad)" stroke="#0056CC" stroke-width="2"/>
          
          <!-- Chat Emoji -->
          <text x="\(size/2)" y="\(size/2 + size/8)" font-size="\(size * 3/4)" text-anchor="middle" dominant-baseline="middle">💬</text>
        </svg>
        """
        
        return svgIcon.data(using: .utf8) ?? Data()
    }
    
    private func handleAppleIconRequest(_ connection: NWConnection, path: String) {
        // Extract size from path (e.g. "/icons/apple-icon-180x180.png" -> "180")
        let filename = path.components(separatedBy: "/").last ?? ""
        
        // Extract size from various Apple icon formats
        let sizeStr: String
        if filename.contains("apple-icon-") {
            // Extract from apple-icon-180x180.png
            let parts = filename.replacingOccurrences(of: "apple-icon-", with: "")
                             .replacingOccurrences(of: ".png", with: "")
            sizeStr = parts.components(separatedBy: "x").first ?? "180"
        } else if filename.contains("android-icon-") {
            // Extract from android-icon-192x192.png
            let parts = filename.replacingOccurrences(of: "android-icon-", with: "")
                             .replacingOccurrences(of: ".png", with: "")
            sizeStr = parts.components(separatedBy: "x").first ?? "192"
        } else if filename.contains("ms-icon-") {
            // Extract from ms-icon-144x144.png
            let parts = filename.replacingOccurrences(of: "ms-icon-", with: "")
                             .replacingOccurrences(of: ".png", with: "")
            sizeStr = parts.components(separatedBy: "x").first ?? "144"
        } else if filename.contains("favicon-") {
            // Extract from favicon-32x32.png
            let parts = filename.replacingOccurrences(of: "favicon-", with: "")
                             .replacingOccurrences(of: ".png", with: "")
            sizeStr = parts.components(separatedBy: "x").first ?? "32"
        } else {
            sizeStr = "180" // Default size
        }
        
        let size = Int(sizeStr) ?? 180
        
        // Generate a proper app icon for Apple Passwords
        let iconData = generateAppleAppIconData(size: size)
        
        let httpResponse = """
        HTTP/1.1 200 OK\r
        Content-Type: image/png\r
        Content-Length: \(iconData.count)\r
        Connection: close\r
        Access-Control-Allow-Origin: *\r
        Cache-Control: public, max-age=31536000\r
        \r
        """
        
        var responseData = Data()
        responseData.append(httpResponse.data(using: .utf8)!)
        responseData.append(iconData)
        
        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    private func generateAppleAppIconData(size: Int) -> Data {
        // Create a minimal PNG data structure for the icon
        // This is a simplified approach - we'll create an SVG but serve it as PNG
        // Many systems accept SVG with PNG content-type
        
        let svgIcon = """
        <svg width="\(size)" height="\(size)" viewBox="0 0 \(size) \(size)" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="iconGrad" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" style="stop-color:#007AFF;stop-opacity:1" />
              <stop offset="100%" style="stop-color:#0051D5;stop-opacity:1" />
            </linearGradient>
            <filter id="shadow" x="-50%" y="-50%" width="200%" height="200%">
              <feDropShadow dx="0" dy="2" stdDeviation="4" flood-color="#000000" flood-opacity="0.3"/>
            </filter>
          </defs>
          
          <!-- Background with rounded corners for modern app icon look -->
          <rect x="0" y="0" width="\(size)" height="\(size)" rx="\(size/5)" ry="\(size/5)" fill="url(#iconGrad)" filter="url(#shadow)"/>
          
          <!-- Chat bubble icon centered -->
          <g transform="translate(\(size/2), \(size/2))">
            <!-- Main chat bubble -->
            <circle cx="-\(size/8)" cy="-\(size/12)" r="\(size/4)" fill="white" opacity="0.9"/>
            <!-- Smaller chat bubble -->
            <circle cx="\(size/8)" cy="\(size/12)" r="\(size/6)" fill="white" opacity="0.7"/>
            <!-- Chat dots -->
            <circle cx="-\(size/6)" cy="-\(size/12)" r="\(size/32)" fill="#007AFF"/>
            <circle cx="-\(size/8)" cy="-\(size/12)" r="\(size/32)" fill="#007AFF"/>
            <circle cx="-\(size/12)" cy="-\(size/12)" r="\(size/32)" fill="#007AFF"/>
          </g>
        </svg>
        """
        
        return svgIcon.data(using: .utf8) ?? Data()
    }
    
    // MARK: - Admin Authentication and API Methods
    
    private func isAdminRequest(_ request: String) -> Bool {
        // Extract session ID from request headers or cookies
        let sessionId = extractSessionId(from: request)
        
        guard let sessionId = sessionId,
              let session = adminSessions[sessionId],
              !session.isExpired else {
            print("[WebServer] 🔒 No valid admin session found")
            return false
        }
        
        // Verify the user is still enabled (check against regular chat users, not admin users)
        guard webAuthnManager.isUserEnabled(username: session.username) else {
            // Remove invalid session
            adminSessions.removeValue(forKey: sessionId)
            print("[WebServer] 🔒 User \(session.username) not found or disabled in chat system")
            return false
        }
        
        // CRITICAL: Verify the authenticated user matches the configured admin username
        guard session.username == adminUsername else {
            print("[WebServer] 🔒 Session user '\(session.username)' does not match configured admin '\(adminUsername)'")
            adminSessions.removeValue(forKey: sessionId) // Remove invalid session
            return false
        }
        
        
        print("[WebServer] ✅ Valid admin session for \(session.username)")
        return true
    }
    
    private func extractSessionId(from request: String) -> String? {
        // Check for session ID in Cookie header first (most common)
        let lines = request.components(separatedBy: "\r\n")
        for line in lines {
            if line.lowercased().hasPrefix("cookie:") {
                let cookies = line.dropFirst(7).components(separatedBy: ";")
                for cookie in cookies {
                    let parts = cookie.trimmingCharacters(in: .whitespaces).components(separatedBy: "=")
                    if parts.count == 2 && parts[0] == "adminSessionId" {
                        return parts[1]
                    }
                }
            }
        }
        
        // Check for session ID in Authorization header
        for line in lines {
            if line.lowercased().hasPrefix("authorization: bearer ") {
                return String(line.dropFirst(22).trimmingCharacters(in: .whitespaces))
            }
        }
        
        return nil
    }
    
    private func extractClientIP(_ request: String, connection: NWConnection) -> String? {
        // First try to get IP from connection endpoint
        if let endpoint = connection.currentPath?.remoteEndpoint {
            switch endpoint {
            case .hostPort(let host, _):
                return String(describing: host)
            default:
                break
            }
        }
        
        // Fallback to headers for proxy scenarios
        let lines = request.components(separatedBy: "\r\n")
        
        // Check for X-Forwarded-For header (for proxies)
        for line in lines {
            if line.lowercased().hasPrefix("x-forwarded-for:") {
                let value = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true).last?.trimmingCharacters(in: .whitespaces)
                return value?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces)
            }
        }
        
        // Check for X-Real-IP header
        for line in lines {
            if line.lowercased().hasPrefix("x-real-ip:") {
                let value = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true).last?.trimmingCharacters(in: .whitespaces)
                return value
            }
        }
        
        // If we can't extract from connection or headers, return localhost
        return "127.0.0.1"
    }
    
    private func handleAdminAPIUsers(_ connection: NWConnection, request: String) {
        let adminUsers = PersistenceManager.shared.loadAdminUsers()
        
        // Convert to JSON-serializable format
        let usersData = adminUsers.map { user in
            return [
                "id": user.id.uuidString,
                "username": user.username,
                "credentialId": user.credentialId,
                "publicKey": user.publicKey,
                "signCount": user.signCount,
                "createdAt": ISO8601DateFormatter().string(from: user.createdAt),
                "lastLoginAt": user.lastLoginAt.map { ISO8601DateFormatter().string(from: $0) } as Any,
                "lastLoginIP": user.lastLoginIP as Any,
                "isEnabled": user.isEnabled,
                "userNumber": user.userNumber
            ] as [String: Any]
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: usersData)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "[]"
            sendJSONResponse(connection, json: jsonString)
        } catch {
            sendErrorResponse(connection, error: "Failed to serialize users data")
        }
    }
    
    private func handleAdminAPIToggleUser(_ connection: NWConnection, request: String, path: String) {
        // Extract user ID from path /admin/api/users/{id}/toggle
        let pathComponents = path.components(separatedBy: "/")
        guard pathComponents.count >= 5,
              let userId = UUID(uuidString: pathComponents[4]) else {
            sendErrorResponse(connection, error: "Invalid user ID")
            return
        }
        
        // Extract request body
        guard let bodyStart = request.range(of: "\r\n\r\n")?.upperBound else {
            sendErrorResponse(connection, error: "Invalid request format")
            return
        }
        
        let bodyString = String(request[bodyStart...])
        guard let bodyData = bodyString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
              let enabled = json["enabled"] as? Bool else {
            sendErrorResponse(connection, error: "Invalid request body")
            return
        }
        
        // Update user status
        let adminUsers = PersistenceManager.shared.loadAdminUsers()
        guard let userIndex = adminUsers.firstIndex(where: { $0.id == userId }) else {
            sendErrorResponse(connection, error: "User not found")
            return
        }
        
        let updatedUser = adminUsers[userIndex].withEnabledStatus(enabled)
        PersistenceManager.shared.saveAdminUser(updatedUser)
        
        sendJSONResponse(connection, json: "{\"success\":true}")
    }
    
    private func handleAdminAPIDeleteUser(_ connection: NWConnection, request: String, path: String) {
        // Extract user ID from path /admin/api/users/{id}
        let pathComponents = path.components(separatedBy: "/")
        guard pathComponents.count >= 4,
              let userId = UUID(uuidString: pathComponents[4]) else {
            sendErrorResponse(connection, error: "Invalid user ID")
            return
        }
        
        // Delete user
        PersistenceManager.shared.deleteAdminUser(userId)
        sendJSONResponse(connection, json: "{\"success\":true}")
    }
    
    private func handleAdminAPIDisableByIP(_ connection: NWConnection, request: String) {
        // Extract request body
        guard let bodyStart = request.range(of: "\r\n\r\n")?.upperBound else {
            sendErrorResponse(connection, error: "Invalid request format")
            return
        }
        
        let bodyString = String(request[bodyStart...])
        guard let bodyData = bodyString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
              let ipAddress = json["ipAddress"] as? String else {
            sendErrorResponse(connection, error: "Invalid request body")
            return
        }
        
        // Disable all users with the specified IP
        PersistenceManager.shared.disableAdminUsersByIP(ipAddress)
        sendJSONResponse(connection, json: "{\"success\":true}")
    }
    
    // MARK: - Admin Content Generation
    
    private func generateAdminIndexHTML() -> String {
        return WebAdminContent.generateAdminIndexHTML()
    }
    
    private func generateAdminCSS() -> String {
        return WebAdminContent.generateAdminCSS()
    }
    
    private func generateAdminJS() -> String {
        return WebAdminContent.generateAdminJS()
    }
    
    // More permissive admin session check
    private func hasValidAdminSession(_ request: String) -> Bool {
        // If we have any valid admin sessions, allow access
        let validSessions = adminSessions.values.filter { !$0.isExpired }
        
        if !validSessions.isEmpty {
            print("[WebServer] ✅ Found valid admin sessions - allowing admin API access")
            return true
        }
        
        // Also check for session cookie
        let sessionId = extractSessionId(from: request)
        if let sessionId = sessionId,
           let session = adminSessions[sessionId],
           !session.isExpired,
           session.username == adminUsername {
            print("[WebServer] ✅ Valid session cookie found for admin API")
            return true
        }
        
        print("[WebServer] 🔒 No valid admin sessions found")
        return false
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
// MARK: - Additional Admin Functions (added for authentication)
extension WebServer {
    private func generateAdminLoginHTML() -> String {
        return WebAdminContent.generateAdminLoginHTML()
    }
    
    private func generateAdminLoginJS() -> String {
        return WebAdminContent.generateAdminLoginJS()
    }
    
    private func handleAdminLogin(_ connection: NWConnection, request: String) {
        print("[WebServer] 🔑 Admin login attempt")
        
        // Extract client IP
        let clientIP = extractClientIP(request, connection: connection)
        
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
        
        // CRITICAL: Only allow the configured admin username to access admin functions
        guard username == adminUsername else {
            print("[WebServer] ❌ Username \(username) does not match configured admin \(adminUsername)")
            sendErrorResponse(connection, error: "Access denied - invalid admin username", statusCode: "404 Not Found")
            return
        }
        
        print("[WebServer] 🔑 Admin login for username: \(username)")
        
        do {
            // Verify authentication using existing WebAuthn system
            let authenticatedUsername = try webAuthnManager.verifyAuthentication(
                username: username, 
                credential: json, 
                clientIP: clientIP
            )
            
            let finalUsername = authenticatedUsername ?? username
            
            // Double-check the authenticated username still matches the configured admin
            guard finalUsername == adminUsername else {
                print("[WebServer] ❌ Authenticated username \(finalUsername) does not match configured admin \(adminUsername)")
                sendErrorResponse(connection, error: "Access denied - authentication mismatch", statusCode: "404 Not Found")
                return
            }
            
            // Verify user is an admin and enabled
            let adminUsers = PersistenceManager.shared.loadAdminUsers()
            guard let adminUser = adminUsers.first(where: { $0.username == finalUsername }),
                  adminUser.isEnabled else {
                print("[WebServer] ❌ User \(finalUsername) is not an admin or is disabled")
                sendErrorResponse(connection, error: "Access denied", statusCode: "403 Forbidden")
                return
            }
            
            // Create admin session
            let sessionId = UUID().uuidString
            let session = AdminSession(
                sessionId: sessionId,
                username: finalUsername,
                loginTime: Date(),
                clientIP: clientIP ?? "unknown"
            )
            
            // Store session
            adminSessions[sessionId] = session
            
            print("[WebServer] ✅ Admin login successful for \(finalUsername)")
            
            // Return success with session ID
            let response: [String: Any] = [
                "success": true,
                "sessionId": sessionId,
                "username": finalUsername
            ]
            
            let responseData = try JSONSerialization.data(withJSONObject: response)
            let responseString = String(data: responseData, encoding: .utf8) ?? "{\"success\":true}"
            
            // Send response with Set-Cookie header for session
            let httpResponse = """
            HTTP/1.1 200 OK\r
            Content-Type: application/json\r
            Content-Length: \(responseString.utf8.count)\r
            Set-Cookie: adminSessionId=\(sessionId); HttpOnly; SameSite=Strict; Path=/admin\r
            Connection: close\r
            Access-Control-Allow-Origin: *\r
            \r
            \(responseString)
            """
            
            connection.send(content: httpResponse.data(using: .utf8), completion: .contentProcessed { _ in
                connection.cancel()
            })
            
        } catch {
            print("[WebServer] ❌ Admin authentication failed: \(error)")
            sendErrorResponse(connection, error: "Authentication failed", statusCode: "401 Unauthorized")
        }
    }
}
