import Foundation
import CryptoKit
import SwiftData

public enum WebAuthnStorageBackend {
    case json(String)           // JSON file path
    case swiftData(String)      // Database file path
}

public enum WebAuthnProtocol {
    case fido2CBOR  // FIDO2/WebAuthn with CBOR attestation objects
    case u2fV1A     // Legacy U2F V1A format
}

public struct WebAuthnCredential: Codable {
    let id: String
    let publicKey: String // Now stores the actual public key, not credential ID
    let signCount: UInt32
    let username: String
    let algorithm: Int // COSE algorithm identifier
    let protocolVersion: String // Track which protocol was used
}

@Model
public class WebAuthnCredentialModel {
    @Attribute(.unique) public var id: String
    public var publicKey: String
    public var signCount: UInt32
    @Attribute(.unique) public var username: String
    public var algorithm: Int
    public var protocolVersion: String
    public var createdAt: Date
    
    public init(id: String, publicKey: String, signCount: UInt32, username: String, algorithm: Int, protocolVersion: String) {
        self.id = id
        self.publicKey = publicKey
        self.signCount = signCount
        self.username = username
        self.algorithm = algorithm
        self.protocolVersion = protocolVersion
        self.createdAt = Date()
    }
    
    // Convert to the existing WebAuthnCredential struct for compatibility
    public var webAuthnCredential: WebAuthnCredential {
        return WebAuthnCredential(
            id: id,
            publicKey: publicKey,
            signCount: signCount,
            username: username,
            algorithm: algorithm,
            protocolVersion: protocolVersion
        )
    }
}

public class WebAuthnManager {
    private var credentials: [String: WebAuthnCredential] = [:]
    private var credentialIdToUsername: [String: String] = [:]
    private let webAuthnProtocol: WebAuthnProtocol
    private let storageBackend: WebAuthnStorageBackend
    private var modelContainer: ModelContainer?
    
    private var credentialsFile: String {
        switch storageBackend {
        case .json(let path):
            return path.isEmpty ? defaultJSONPath : path
        case .swiftData:
            return "" // Not used for Swift Data
        }
    }
    
    private var defaultJSONPath: String {
        switch webAuthnProtocol {
        case .fido2CBOR:
            return "webauthn_credentials_fido2.json"
        case .u2fV1A:
            return "webauthn_credentials_u2f.json"
        }
    }
    
    private let rpId: String
    private let rpName: String?
    private let rpIcon: String?
    private let defaultUserIcon: String?
    
    public init(
        rpId: String, 
        webAuthnProtocol: WebAuthnProtocol = .fido2CBOR,
        storageBackend: WebAuthnStorageBackend = .json(""),
        rpName: String? = nil, 
        rpIcon: String? = nil, 
        defaultUserIcon: String? = nil
    ) {
        self.rpId = rpId
        self.webAuthnProtocol = webAuthnProtocol
        self.storageBackend = storageBackend
        self.rpName = rpName
        self.rpIcon = rpIcon
        self.defaultUserIcon = defaultUserIcon
        
        setupStorage()
        loadCredentials()
    }
    
    private func setupStorage() {
        switch storageBackend {
        case .json:
            // No setup needed for JSON
            break
        case .swiftData(let dbPath):
            do {
                let schema = Schema([WebAuthnCredentialModel.self])
                let modelConfiguration: ModelConfiguration
                
                if dbPath.isEmpty {
                    // Use default location
                    modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                } else {
                    // Use specified database file path
                    let dbURL = URL(fileURLWithPath: dbPath)
                    modelConfiguration = ModelConfiguration(schema: schema, url: dbURL)
                }
                
                // Enable encryption for sensitive credential data
                modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("[WebAuthn] ✅ Swift Data container initialized at: \(dbPath.isEmpty ? "default location" : dbPath)")
            } catch {
                print("[WebAuthn] ❌ Failed to initialize Swift Data container: \(error)")
                print("[WebAuthn] ⚠️ Falling back to in-memory storage")
                // Fallback to in-memory storage if database setup fails
                let schema = Schema([WebAuthnCredentialModel.self])
                let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                modelContainer = try? ModelContainer(for: schema, configurations: [memoryConfig])
            }
        }
    }
    
    // MARK: - CBOR Parsing Utilities
    
    public struct CBORDecoder {
        public static func parseAttestationObject(_ base64String: String) throws -> [String: Any] {
            guard let data = Data(base64Encoded: base64String) else {
                throw WebAuthnError.invalidCredential
            }
            
            // Basic CBOR parsing for attestation object
            return try parseCBOR(data)
        }
        
        public static func parseCBOR(_ data: Data) throws -> [String: Any] {
            var index = 0
            return try parseCBORValue(data, index: &index) as! [String: Any]
        }
        
        public static func parseCBORValue(_ data: Data, index: inout Int) throws -> Any {
            guard index < data.count else { throw WebAuthnError.invalidCredential }
            
            let byte = data[index]
            index += 1
            
            let majorType = (byte >> 5) & 0x07
            let additionalInfo = byte & 0x1F
            
            switch majorType {
            case 0: // Positive integer
                return try parsePositiveInteger(additionalInfo, data: data, index: &index)
            case 1: // Negative integer
                let positive = try parsePositiveInteger(additionalInfo, data: data, index: &index) as! UInt64
                return -Int64(positive) - 1
            case 2: // Byte string
                let length = try parseLength(additionalInfo, data: data, index: &index)
                guard index + length <= data.count else { throw WebAuthnError.invalidCredential }
                let result = data.subdata(in: index..<(index + length))
                index += length
                return result
            case 3: // Text string
                let length = try parseLength(additionalInfo, data: data, index: &index)
                guard index + length <= data.count else { throw WebAuthnError.invalidCredential }
                let result = String(data: data.subdata(in: index..<(index + length)), encoding: .utf8) ?? ""
                index += length
                return result
            case 4: // Array
                let count = try parseLength(additionalInfo, data: data, index: &index)
                var array: [Any] = []
                for _ in 0..<count {
                    array.append(try parseCBORValue(data, index: &index))
                }
                return array
            case 5: // Map
                let count = try parseLength(additionalInfo, data: data, index: &index)
                var map: [String: Any] = [:]
                for _ in 0..<count {
                    let key = try parseCBORValue(data, index: &index)
                    let value = try parseCBORValue(data, index: &index)
                    // Handle both string keys and integer keys (convert to string)
                    var keyString: String
                    if let stringKey = key as? String {
                        keyString = stringKey
                    } else if let intKey = key as? Int64 {
                        keyString = String(intKey)
                    } else if let intKey = key as? UInt64 {
                        keyString = String(intKey)
                    } else if let intKey = key as? Int {
                        keyString = String(intKey)
                    } else {
                        // Skip unknown key types
                        continue
                    }
                    map[keyString] = value
                }
                return map
            case 7: // Float, simple, break
                if additionalInfo == 22 { return NSNull() }
                if additionalInfo == 20 { return false }
                if additionalInfo == 21 { return true }
                throw WebAuthnError.invalidCredential
            default:
                throw WebAuthnError.invalidCredential
            }
        }
        
        static func parseLength(_ additionalInfo: UInt8, data: Data, index: inout Int) throws -> Int {
            if additionalInfo < 24 {
                return Int(additionalInfo)
            } else if additionalInfo == 24 {
                guard index < data.count else { throw WebAuthnError.invalidCredential }
                let result = Int(data[index])
                index += 1
                return result
            } else if additionalInfo == 25 {
                guard index + 1 < data.count else { throw WebAuthnError.invalidCredential }
                let result = Int(data[index]) << 8 | Int(data[index + 1])
                index += 2
                return result
            } else if additionalInfo == 26 {
                guard index + 3 < data.count else { throw WebAuthnError.invalidCredential }
                let result = Int(data[index]) << 24 | Int(data[index + 1]) << 16 | Int(data[index + 2]) << 8 | Int(data[index + 3])
                index += 4
                return result
            } else {
                throw WebAuthnError.invalidCredential
            }
        }
        
        static func parsePositiveInteger(_ additionalInfo: UInt8, data: Data, index: inout Int) throws -> Any {
            if additionalInfo < 24 {
                return UInt64(additionalInfo)
            } else if additionalInfo == 24 {
                guard index < data.count else { throw WebAuthnError.invalidCredential }
                let result = UInt64(data[index])
                index += 1
                return result
            } else if additionalInfo == 25 {
                guard index + 1 < data.count else { throw WebAuthnError.invalidCredential }
                let result = UInt64(data[index]) << 8 | UInt64(data[index + 1])
                index += 2
                return result
            } else if additionalInfo == 26 {
                guard index + 3 < data.count else { throw WebAuthnError.invalidCredential }
                let result = UInt64(data[index]) << 24 | UInt64(data[index + 1]) << 16 | UInt64(data[index + 2]) << 8 | UInt64(data[index + 3])
                index += 4
                return result
            } else if additionalInfo == 27 {
                guard index + 7 < data.count else { throw WebAuthnError.invalidCredential }
                var result: UInt64 = 0
                for i in 0..<8 {
                    result = (result << 8) | UInt64(data[index + i])
                }
                index += 8
                return result
            } else {
                throw WebAuthnError.invalidCredential
            }
        }
    }
    
    // MARK: - Public Key Extraction
    
    private func extractPublicKey(from attestationObject: [String: Any]) throws -> (publicKey: String, algorithm: Int) {
        guard let authData = attestationObject["authData"] as? Data else {
            throw WebAuthnError.invalidCredential
        }
        
        // Parse authenticator data
        // Format: rpIdHash(32) + flags(1) + signCount(4) + attestedCredentialData(variable)
        guard authData.count >= 37 else {
            throw WebAuthnError.invalidCredential
        }
        
        let flags = authData[32]
        let attestedCredentialDataIncluded = (flags & 0x40) != 0
        
        guard attestedCredentialDataIncluded else {
            throw WebAuthnError.invalidCredential
        }
        
        // Parse attested credential data
        // Format: aaguid(16) + credentialIdLength(2) + credentialId(L) + credentialPublicKey(variable)
        var offset = 37 // Start after rpIdHash + flags + signCount
        
        // Skip AAGUID (16 bytes)
        offset += 16
        
        // Read credential ID length (2 bytes, big endian)
        guard offset + 1 < authData.count else {
            throw WebAuthnError.invalidCredential
        }
        let credentialIdLength = Int(authData[offset]) << 8 | Int(authData[offset + 1])
        offset += 2
        
        // Skip credential ID
        offset += credentialIdLength
        
        // Parse credential public key (CBOR)
        guard offset < authData.count else {
            throw WebAuthnError.invalidCredential
        }
        
        let publicKeyData = authData.subdata(in: offset..<authData.count)
        var index = 0
        let publicKeyMap = try CBORDecoder.parseCBORValue(publicKeyData, index: &index) as! [String: Any]
        
        // Extract key parameters based on COSE key format
        let ktyValue = publicKeyMap["1"]
        
        let kty: Int
        if let ktyInt = ktyValue as? Int {
            kty = ktyInt
        } else if let ktyUInt64 = ktyValue as? UInt64 {
            kty = Int(ktyUInt64)
        } else if let ktyInt64 = ktyValue as? Int64 {
            kty = Int(ktyInt64)
        } else {
            throw WebAuthnError.invalidCredential
        }
        
        let algValue = publicKeyMap["3"]
        let alg: Int
        if let algInt = algValue as? Int {
            alg = algInt
        } else if let algInt64 = algValue as? Int64 {
            alg = Int(algInt64)
        } else if let algUInt64 = algValue as? UInt64 {
            alg = Int(algUInt64)
        } else {
            throw WebAuthnError.invalidCredential
        }
        
        var publicKeyString: String
        
        if kty == 2 { // EC2 key type
            let curveValue = publicKeyMap["-1"]
            let curve: Int
            if let curveInt = curveValue as? Int {
                curve = curveInt
            } else if let curveUInt64 = curveValue as? UInt64 {
                curve = Int(curveUInt64)
            } else if let curveInt64 = curveValue as? Int64 {
                curve = Int(curveInt64)
            } else {
                throw WebAuthnError.invalidCredential
            }
            
            guard let xData = publicKeyMap["-2"] as? Data,
                  let yData = publicKeyMap["-3"] as? Data else {
                throw WebAuthnError.invalidCredential
            }
            
            // For P-256 curve (curve = 1)
            if curve == 1 && alg == -7 { // ES256
                // Construct uncompressed point format: 0x04 + x + y
                var pointData = Data([0x04])
                pointData.append(xData)
                pointData.append(yData)
                publicKeyString = pointData.base64EncodedString()
            } else {
                throw WebAuthnError.invalidCredential
            }
        } else if kty == 3 { // RSA key type
            guard let nData = publicKeyMap["-1"] as? Data,
                  let eData = publicKeyMap["-2"] as? Data else {
                throw WebAuthnError.invalidCredential
            }
            
            // Store RSA public key as JSON for easier parsing later
            let rsaKey = [
                "kty": "RSA",
                "n": nData.base64EncodedString(),
                "e": eData.base64EncodedString()
            ]
            let rsaKeyData = try JSONSerialization.data(withJSONObject: rsaKey)
            publicKeyString = rsaKeyData.base64EncodedString()
        } else {
            throw WebAuthnError.invalidCredential
        }
        
        return (publicKey: publicKeyString, algorithm: alg)
    }
    
    private func loadCredentials() {
        switch storageBackend {
        case .json:
            loadCredentialsFromJSON()
        case .swiftData:
            loadCredentialsFromSwiftData()
        }
    }
    
    private func loadCredentialsFromJSON() {
        let url = URL(fileURLWithPath: credentialsFile)
        guard FileManager.default.fileExists(atPath: credentialsFile) else { return }
        do {
            let data = try Data(contentsOf: url)
            let arr = try JSONDecoder().decode([WebAuthnCredential].self, from: data)
            for cred in arr {
                credentials[cred.username] = cred
                credentialIdToUsername[cred.id] = cred.username
            }
            print("[WebAuthn] Loaded \(arr.count) credentials from JSON file.")
        } catch {
            print("[WebAuthn] Failed to load credentials from JSON: \(error)")
        }
    }
    
    private func loadCredentialsFromSwiftData() {
        guard let container = modelContainer else {
            print("[WebAuthn] ❌ No model container available")
            return
        }
        
        do {
            let context = ModelContext(container)
            let request = FetchDescriptor<WebAuthnCredentialModel>()
            let models = try context.fetch(request)
            
            for model in models {
                let cred = model.webAuthnCredential
                credentials[cred.username] = cred
                credentialIdToUsername[cred.id] = cred.username
            }
            print("[WebAuthn] Loaded \(models.count) credentials from Swift Data.")
        } catch {
            print("[WebAuthn] Failed to load credentials from Swift Data: \(error)")
        }
    }
    
    private func saveCredentials() {
        switch storageBackend {
        case .json:
            saveCredentialsToJSON()
        case .swiftData:
            saveCredentialsToSwiftData()
        }
    }
    
    private func saveCredentialsToJSON() {
        let arr = Array(credentials.values)
        let url = URL(fileURLWithPath: credentialsFile)
        print("[WebAuthn] 💾 Attempting to save \(arr.count) credentials to JSON: \(credentialsFile)")
        
        do {
            let data = try JSONEncoder().encode(arr)
            print("[WebAuthn] 💾 Encoded \(data.count) bytes of credential data")
            try data.write(to: url)
            print("[WebAuthn] ✅ Successfully saved \(arr.count) credentials to JSON.")
            
            // Verify the file was written correctly
            if FileManager.default.fileExists(atPath: credentialsFile) {
                let fileSize = try FileManager.default.attributesOfItem(atPath: credentialsFile)[.size] as? Int64 ?? 0
                print("[WebAuthn] ✅ File verification: \(credentialsFile) exists, size: \(fileSize) bytes")
            } else {
                print("[WebAuthn] ⚠️ Warning: File does not exist after write: \(credentialsFile)")
            }
        } catch {
            print("[WebAuthn] ❌ Failed to save credentials to JSON: \(error)")
            print("[WebAuthn] ❌ Error type: \(type(of: error))")
            print("[WebAuthn] ❌ Credentials file path: \(credentialsFile)")
            print("[WebAuthn] ❌ Full file URL: \(url)")
        }
    }
    
    private func saveCredentialsToSwiftData() {
        guard let container = modelContainer else {
            print("[WebAuthn] ❌ No model container available for saving")
            return
        }
        
        do {
            let context = ModelContext(container)
            
            // Clear existing credentials and rebuild from memory
            try context.delete(model: WebAuthnCredentialModel.self)
            
            // Insert current credentials
            for cred in credentials.values {
                let model = WebAuthnCredentialModel(
                    id: cred.id,
                    publicKey: cred.publicKey,
                    signCount: cred.signCount,
                    username: cred.username,
                    algorithm: cred.algorithm,
                    protocolVersion: cred.protocolVersion
                )
                context.insert(model)
            }
            
            try context.save()
            print("[WebAuthn] ✅ Successfully saved \(credentials.count) credentials to Swift Data.")
        } catch {
            print("[WebAuthn] ❌ Failed to save credentials to Swift Data: \(error)")
        }
    }
    
    // MARK: - Migration Support
    
    public func migrateFromJSON(jsonPath: String) throws {
        guard case .swiftData = storageBackend else {
            throw WebAuthnError.invalidCredential // Reusing existing error type
        }
        
        // Load credentials from JSON file
        let url = URL(fileURLWithPath: jsonPath)
        guard FileManager.default.fileExists(atPath: jsonPath) else {
            print("[WebAuthn] 📦 No JSON file found at \(jsonPath) - nothing to migrate")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let jsonCredentials = try JSONDecoder().decode([WebAuthnCredential].self, from: data)
            
            print("[WebAuthn] 📦 Migrating \(jsonCredentials.count) credentials from JSON to Swift Data...")
            
            // Add to current credentials (don't overwrite existing)
            var migratedCount = 0
            for cred in jsonCredentials {
                if credentials[cred.username] == nil {
                    credentials[cred.username] = cred
                    credentialIdToUsername[cred.id] = cred.username
                    migratedCount += 1
                } else {
                    print("[WebAuthn] ⚠️ Skipping duplicate credential for \(cred.username)")
                }
            }
            
            // Save to Swift Data
            saveCredentialsToSwiftData()
            
            print("[WebAuthn] ✅ Migration completed: \(migratedCount) credentials migrated")
            
            // Optionally backup the JSON file
            let backupPath = jsonPath + ".backup"
            try? FileManager.default.copyItem(atPath: jsonPath, toPath: backupPath)
            print("[WebAuthn] 📦 JSON file backed up to: \(backupPath)")
            
        } catch {
            print("[WebAuthn] ❌ Migration failed: \(error)")
            throw error
        }
    }
    
    public func generateRegistrationOptions(username: String) throws -> [String: Any] {
        let challenge = generateChallenge()
        let userId = generateUserId()
        
        // Use configured icons or generate sensible defaults
        // Prefer HTTPS for better passkey manager compatibility
        let rpIconUrl = rpIcon ?? "https://\(rpId)/icon-192.png"
        let userIconUrl = defaultUserIcon ?? generateUserIcon(for: username)
        let displayName = rpName ?? rpId
        
        var rpData: [String: Any] = [
            "name": displayName,
            "id": rpId
        ]
        
        // Only add icon if we have one
        if !rpIconUrl.isEmpty {
            rpData["icon"] = rpIconUrl
        }
        
        var userData: [String: Any] = [
            "id": userId,
            "name": username,
            "displayName": username
        ]
        
        // Only add user icon if we have one
        if !userIconUrl.isEmpty {
            userData["icon"] = userIconUrl
        }
        
        let options: [String: Any] = [
            "publicKey": [
                "challenge": challenge,
                "rp": rpData,
                "user": userData,
                "pubKeyCredParams": [
                    ["type": "public-key", "alg": -7],  // ES256
                    ["type": "public-key", "alg": -257] // RS256
                ],
                "timeout": 60000,
                "attestation": "direct",
                "authenticatorSelection": [
                    "authenticatorAttachment": "platform",
                    "userVerification": "required",
                    "requireResidentKey": false
                ]
            ]
        ]
        
        return options
    }
    
    private func generateUserIcon(for username: String) -> String {
        // Generate a user icon URL based on username
        // You could use services like Gravatar, UI Avatars, or your own avatar service
        let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? username
        return "https://ui-avatars.com/api/?name=\(encodedUsername)&background=007bff&color=white&size=64"
    }
    
    public func generateAuthenticationOptions(username: String?) throws -> [String: Any] {
        let challenge = generateChallenge()
        
        var allowCredentials: [[String: Any]] = []
        
        if let username = username {
            // If username is provided, only allow that specific credential
        guard let credential = credentials[username] else {
            throw WebAuthnError.credentialNotFound
        }
            allowCredentials = [[
                "type": "public-key",
                "id": credential.id,
                "transports": ["internal"]
            ]]
        } else {
            // If no username provided, allow all credentials
            allowCredentials = credentials.values.map { credential in
                [
                    "type": "public-key",
                    "id": credential.id,
                    "transports": ["internal"]
                ]
            }
        }
        
        let options: [String: Any] = [
            "publicKey": [
                "challenge": challenge,
                "timeout": 60000,
                "rpId": rpId,
                "allowCredentials": allowCredentials,
                "userVerification": "required"
            ]
        ]
        
        return options
    }
    
    private func base64urlToBase64(_ s: String) -> String {
        var base64 = s.replacingOccurrences(of: "-", with: "+")
                      .replacingOccurrences(of: "_", with: "/")
        let rem = base64.count % 4
        if rem > 0 {
            base64 += String(repeating: "=", count: 4 - rem)
        }
        return base64
    }
    
    public func verifyRegistration(username: String, credential: [String: Any], clientIP: String? = nil) throws {
        print("[WebAuthn] 🔍 verifyRegistration called for username: \(username)")
        print("[WebAuthn] 📍 Client IP: \(clientIP ?? "unknown")")
        
        // Check if username already exists
        if credentials[username] != nil {
            print("[WebAuthn] ❌ Username '\(username)' already exists")
            throw WebAuthnError.duplicateUsername
        }
        
        // Extract emoji from credential data, default to 👤 if not provided
        let emoji = credential["emoji"] as? String ?? "👤"
        
        guard let idRaw = credential["id"] as? String else {
            print("[WebAuthn] MISSING id")
            throw WebAuthnError.invalidCredential
        }
        let id = base64urlToBase64(idRaw)
        
        guard let response = credential["response"] as? [String: Any] else {
            print("[WebAuthn] MISSING response")
            throw WebAuthnError.invalidCredential
        }
        
        // Try FIDO2 format first, then fall back to U2F
        do {
            print("[WebAuthn] 🔍 Attempting FIDO2 registration verification...")
            try verifyFIDO2Registration(username: username, id: id, response: response, clientIP: clientIP, emoji: emoji)
            print("[WebAuthn] ✅ FIDO2 registration successful")
        } catch {
            print("[WebAuthn] ⚠️ FIDO2 verification failed: \(error), trying U2F...")
            do {
                try verifyU2FRegistration(username: username, id: id, response: response, clientIP: clientIP, emoji: emoji)
                print("[WebAuthn] ✅ U2F registration successful")
            } catch {
                print("[WebAuthn] ❌ Both FIDO2 and U2F verification failed")
                throw error
            }
        }
    }
    
    private func verifyFIDO2Registration(username: String, id: String, response: [String: Any], clientIP: String?, emoji: String) throws {
        guard let attestationObjectString = response["attestationObject"] as? String else {
            print("[WebAuthn] MISSING attestationObject")
            throw WebAuthnError.invalidCredential
        }
        
        guard let clientDataJSONString = response["clientDataJSON"] as? String else {
            print("[WebAuthn] MISSING clientDataJSON")
            throw WebAuthnError.invalidCredential
        }
        
        // Verify client data
        try verifyClientData(clientDataJSONString, type: "webauthn.create")
        
        // Parse attestation object and extract public key
        let attestationObject = try CBORDecoder.parseAttestationObject(attestationObjectString)
        let (publicKey, algorithm) = try extractPublicKey(from: attestationObject)
        
        print("[WebAuthn] Successfully extracted public key for \(username)")
        
        // Store the credential with the actual public key
        let newCredential = WebAuthnCredential(
            id: id,
            publicKey: publicKey,
            signCount: 0,
            username: username,
            algorithm: algorithm,
            protocolVersion: "fido2CBOR"
        )
        credentials[username] = newCredential
        credentialIdToUsername[id] = username
        saveCredentials()
        
        // Create admin user record for tracking with emoji
        let userNumber = PersistenceManager.shared.getNextUserNumber()
        let adminUser = AdminUser(
            username: username,
            credentialId: id,
            publicKey: publicKey,
            signCount: 0,
            lastLoginIP: clientIP,
            userNumber: userNumber,
            emoji: emoji
        )
        PersistenceManager.shared.saveAdminUser(adminUser)
        print("[WebAuthn] Created admin user record for \(username) (#\(userNumber)) with emoji \(emoji)")
    }
    
    private func verifyU2FRegistration(username: String, id: String, response: [String: Any], clientIP: String?, emoji: String) throws {
        // U2F V1A registration format
        guard let registrationData = response["registrationData"] as? String,
              let _ = response["clientData"] as? String else {
            print("[WebAuthn] MISSING U2F registration data")
            throw WebAuthnError.invalidCredential
        }
        
        // Parse U2F registration data
        guard let regData = Data(base64Encoded: registrationData) else {
            throw WebAuthnError.invalidCredential
        }
        
        // U2F registration data format:
        // 1 byte: 0x05 (reserved)
        // 65 bytes: user public key
        // 1 byte: key handle length
        // key handle length bytes: key handle
        // ASN.1 DER encoded attestation certificate
        // signature
        
        guard regData.count >= 67 else { // Minimum size
            throw WebAuthnError.invalidCredential
        }
        
        guard regData[0] == 0x05 else {
            throw WebAuthnError.invalidCredential
        }
        
        // Extract public key (65 bytes starting at offset 1)
        let publicKeyData = regData.subdata(in: 1..<66)
        let publicKey = publicKeyData.base64EncodedString()
        
        // Store the credential
        let newCredential = WebAuthnCredential(
            id: id,
            publicKey: publicKey,
            signCount: 0,
            username: username,
            algorithm: -7, // ES256 for U2F
            protocolVersion: "u2fV1A"
        )
        credentials[username] = newCredential
        credentialIdToUsername[id] = username
        saveCredentials()
        
        // Create admin user record for tracking with emoji
        let userNumber = PersistenceManager.shared.getNextUserNumber()
        let adminUser = AdminUser(
            username: username,
            credentialId: id,
            publicKey: publicKey,
            signCount: 0,
            lastLoginIP: clientIP,
            userNumber: userNumber,
            emoji: emoji
        )
        PersistenceManager.shared.saveAdminUser(adminUser)
        print("[WebAuthn] Created admin user record for \(username) (#\(userNumber)) with emoji \(emoji)")
        
        print("[WebAuthn] Successfully registered U2F credential for \(username)")
    }
    
    public func verifyAuthentication(username: String?, credential: [String: Any], clientIP: String? = nil) throws -> String? {
        print("[WebAuthn] verifyAuthentication called for username: \(username ?? "nil")")
        print("[WebAuthn] 📍 Client IP: \(clientIP ?? "unknown")")
        print("[WebAuthn] credential received: \(credential)")
        
        guard let idRaw = credential["id"] as? String else {
            print("[WebAuthn] MISSING id")
            throw WebAuthnError.invalidCredential
        }
        let id = base64urlToBase64(idRaw)
        
        // Look up username by credential ID if not provided
        let usernameToUse = (username?.isEmpty ?? true) ? credentialIdToUsername[id] : username
        guard let finalUsername = usernameToUse else {
            print("[WebAuthn] No username found for credential ID: \(id)")
            throw WebAuthnError.credentialNotFound
        }
        
        // Check if user is disabled
        if !isUserEnabled(username: finalUsername) {
            print("[WebAuthn] ❌ Authentication rejected - user '\(finalUsername)' is disabled")
            throw WebAuthnError.accessDenied
        }
        print("[WebAuthn] ✅ User '\(finalUsername)' is enabled - proceeding with authentication")
        
        guard let storedCredential = credentials[finalUsername] else {
            print("[WebAuthn] credentialNotFound for username: \(finalUsername)")
            throw WebAuthnError.credentialNotFound
        }
        
        guard let response = credential["response"] as? [String: Any] else {
            print("[WebAuthn] MISSING response")
            throw WebAuthnError.invalidCredential
        }
        
        // Use the protocol from the stored credential
        switch storedCredential.protocolVersion {
        case "fido2CBOR":
            try verifyFIDO2Authentication(response: response, storedCredential: storedCredential, id: id, clientIP: clientIP)
        case "u2fV1A":
            try verifyU2FAuthentication(response: response, storedCredential: storedCredential, id: id, clientIP: clientIP)
        default:
            // Fallback to current protocol setting
            switch webAuthnProtocol {
            case .fido2CBOR:
                try verifyFIDO2Authentication(response: response, storedCredential: storedCredential, id: id, clientIP: clientIP)
            case .u2fV1A:
                try verifyU2FAuthentication(response: response, storedCredential: storedCredential, id: id, clientIP: clientIP)
            }
        }
        
        print("[WebAuthn] Authentication successful for \(finalUsername)")
        return (username?.isEmpty ?? true) ? finalUsername : nil
    }
    
    private func verifyFIDO2Authentication(response: [String: Any], storedCredential: WebAuthnCredential, id: String, clientIP: String?) throws {
        guard let clientDataJSONString = response["clientDataJSON"] as? String else {
            print("[WebAuthn] MISSING clientDataJSON")
            throw WebAuthnError.invalidCredential
        }
        
        guard let authenticatorDataString = response["authenticatorData"] as? String else {
            print("[WebAuthn] MISSING authenticatorData")
            throw WebAuthnError.invalidCredential
        }
        
        guard let signatureString = response["signature"] as? String else {
            print("[WebAuthn] MISSING signature")
            throw WebAuthnError.invalidCredential
        }
        
        print("[WebAuthn] 🔍 Starting FIDO2 authentication verification...")
        
        // Verify client data
        do {
            print("[WebAuthn] ✅ Verifying client data...")
            try verifyClientData(clientDataJSONString, type: "webauthn.get")
            print("[WebAuthn] ✅ Client data verification passed")
        } catch {
            print("[WebAuthn] ❌ Client data verification failed: \(error)")
            throw error
        }
        
        // Parse authenticator data to extract sign count
        guard let authenticatorData = Data(base64Encoded: authenticatorDataString) else {
            print("[WebAuthn] ❌ Failed to decode authenticator data")
            throw WebAuthnError.invalidCredential
        }
        
        // Extract and validate sign count
        let newSignCount: UInt32
        do {
            print("[WebAuthn] ✅ Extracting and validating sign count...")
            newSignCount = try extractAndValidateSignCount(from: authenticatorData, storedCredential: storedCredential)
            print("[WebAuthn] ✅ Sign count extraction passed: \(newSignCount)")
        } catch {
            print("[WebAuthn] ❌ Sign count validation failed: \(error)")
            throw error
        }
        
        // Verify the signature
        do {
            print("[WebAuthn] ✅ Verifying signature...")
            try verifySignature(
                authenticatorData: authenticatorDataString,
                clientDataJSON: clientDataJSONString,
                signature: signatureString,
                storedCredential: storedCredential
            )
            print("[WebAuthn] ✅ Signature verification passed")
        } catch {
            print("[WebAuthn] ❌ Signature verification failed: \(error)")
            throw error
        }
        
        if id != storedCredential.id {
            print("[WebAuthn] ❌ Credential ID mismatch: \(id) != \(storedCredential.id)")
            throw WebAuthnError.invalidCredential
        }
        print("[WebAuthn] ✅ Credential ID verification passed")
        
        // Update the stored credential with new sign count
        do {
            print("[WebAuthn] ✅ Updating credential sign count...")
            try updateCredentialSignCount(credential: storedCredential, newSignCount: newSignCount, clientIP: clientIP)
            print("[WebAuthn] ✅ Sign count update completed successfully")
        } catch {
            print("[WebAuthn] ❌ Failed to update sign count: \(error)")
            throw error
        }
    }
    
    private func extractAndValidateSignCount(from authenticatorData: Data, storedCredential: WebAuthnCredential) throws -> UInt32 {
        // Authenticator data format: rpIdHash(32) + flags(1) + signCount(4) + ...
        guard authenticatorData.count >= 37 else {
            print("[WebAuthn] ❌ Authenticator data too short: \(authenticatorData.count) bytes, need at least 37")
            throw WebAuthnError.invalidCredential
        }
        
        print("[WebAuthn] 🔍 Authenticator data length: \(authenticatorData.count) bytes")
        print("[WebAuthn] 🔍 Authenticator data (hex): \(authenticatorData.map { String(format: "%02x", $0) }.joined())")
        
        // Extract sign count (4 bytes at offset 33, big endian)
        let signCountBytes = authenticatorData.subdata(in: 33..<37)
        print("[WebAuthn] 🔍 Sign count bytes (hex): \(signCountBytes.map { String(format: "%02x", $0) }.joined())")
        
        let newSignCount = signCountBytes.withUnsafeBytes { bytes in
            UInt32(bigEndian: bytes.bindMemory(to: UInt32.self).first!)
        }
        
        print("[WebAuthn] 🔍 Extracted sign count: \(newSignCount)")
        print("[WebAuthn] 🔍 Stored sign count: \(storedCredential.signCount)")
        
        // Check if this is a platform authenticator that doesn't use sign count
        // Platform authenticators (Touch ID, Face ID, Windows Hello, etc.) often return 0 consistently
        if newSignCount == 0 {
            print("[WebAuthn] ⚠️ Platform authenticator detected - sign count is 0 (normal for Touch ID/Face ID/Windows Hello)")
            // For platform authenticators that don't increment, increment our own counter for security
            // This provides replay attack protection even when the authenticator doesn't increment
            return storedCredential.signCount + 1
        }
        
        // For hardware authenticators that do increment sign count
        // Validate sign count (must be greater than stored value, unless stored is 0 for first use)
        if storedCredential.signCount > 0 && newSignCount <= storedCredential.signCount {
            print("[WebAuthn] Sign count validation failed: new=\(newSignCount), stored=\(storedCredential.signCount)")
            throw WebAuthnError.signCountInvalid
        }
        
        print("[WebAuthn] Sign count validation passed: new=\(newSignCount), stored=\(storedCredential.signCount)")
        return newSignCount
    }
    
    private func updateCredentialSignCount(credential: WebAuthnCredential, newSignCount: UInt32, clientIP: String? = nil) throws {
        print("[WebAuthn] 📊 updateCredentialSignCount called for \(credential.username)")
        print("[WebAuthn] 📊 Old sign count: \(credential.signCount), New sign count: \(newSignCount)")
        print("[WebAuthn] 📍 Client IP: \(clientIP ?? "unknown")")
        
        // Update the credential with new sign count
        let updatedCredential = WebAuthnCredential(
            id: credential.id,
            publicKey: credential.publicKey,
            signCount: newSignCount,
            username: credential.username,
            algorithm: credential.algorithm,
            protocolVersion: credential.protocolVersion
        )
        
        credentials[credential.username] = updatedCredential
        
        // Update admin user record with new sign count and login information
        if let existingAdminUser = PersistenceManager.shared.getAdminUser(by: credential.username) {
            let updatedAdminUser = existingAdminUser.updatedWithLogin(ip: clientIP, signCount: newSignCount)
            PersistenceManager.shared.saveAdminUser(updatedAdminUser)
            print("[WebAuthn] Updated admin user record for \(credential.username) with sign count \(newSignCount) and IP \(clientIP ?? "unknown")")
        }
        
        saveCredentials()
        print("[WebAuthn] ✅ Sign count update completed successfully")
    }
    
    private func verifyU2FAuthentication(response: [String: Any], storedCredential: WebAuthnCredential, id: String, clientIP: String?) throws {
        guard let signatureData = response["signatureData"] as? String,
              let clientData = response["clientData"] as? String else {
            print("[WebAuthn] MISSING U2F authentication data")
            throw WebAuthnError.invalidCredential
        }
        
        // Parse U2F signature data
        guard let sigData = Data(base64Encoded: signatureData),
              let clientDataBytes = Data(base64Encoded: clientData) else {
            throw WebAuthnError.invalidCredential
        }
        
        // U2F signature data format:
        // 1 byte: user presence (0x01)
        // 4 bytes: counter
        // signature
        
        guard sigData.count >= 5 else {
            throw WebAuthnError.invalidCredential
        }
        
        let userPresence = sigData[0]
        guard userPresence == 0x01 else {
            throw WebAuthnError.invalidCredential
        }
        
        // Extract and validate U2F counter (4 bytes at offset 1, big endian)
        let counterBytes = sigData.subdata(in: 1..<5)
        let newSignCount = counterBytes.withUnsafeBytes { bytes in
            UInt32(bigEndian: bytes.bindMemory(to: UInt32.self).first!)
        }
        
        // Validate sign count (must be greater than stored value, unless stored is 0 for first use)
        if storedCredential.signCount > 0 && newSignCount <= storedCredential.signCount {
            print("[WebAuthn] U2F sign count validation failed: new=\(newSignCount), stored=\(storedCredential.signCount)")
            throw WebAuthnError.signCountInvalid
        }
        
        print("[WebAuthn] U2F sign count validation passed: new=\(newSignCount), stored=\(storedCredential.signCount)")
        
        // Extract signature (remaining bytes after user presence + counter)
        let signature = sigData.subdata(in: 5..<sigData.count)
        
        // Create signed data for U2F
        let applicationParameter = Data(SHA256.hash(data: rpId.data(using: .utf8)!))
        let challengeParameter = Data(SHA256.hash(data: clientDataBytes))
        
        var signedData = Data()
        signedData.append(applicationParameter)
        signedData.append(sigData.subdata(in: 0..<5)) // user presence + counter
        signedData.append(challengeParameter)
        
        // Verify U2F signature
        try verifyU2FSignature(signedData: signedData, signature: signature, publicKey: storedCredential.publicKey)
        
        if id != storedCredential.id {
            print("[WebAuthn] id does not match storedCredential.id")
            throw WebAuthnError.invalidCredential
        }
        
        // Update the stored credential with new sign count
        try updateCredentialSignCount(credential: storedCredential, newSignCount: newSignCount, clientIP: clientIP)
    }
    
    private func verifyU2FSignature(signedData: Data, signature: Data, publicKey: String) throws {
        guard let publicKeyData = Data(base64Encoded: publicKey),
              publicKeyData.count == 65,
              publicKeyData[0] == 0x04 else {
            throw WebAuthnError.invalidCredential
        }
        
        // U2F uses the same P-256 verification as FIDO2
        do {
            let p256PublicKey = try P256.Signing.PublicKey(x963Representation: publicKeyData)
            
            // U2F signatures can be either DER or raw format
            // Try raw format first (more common), then DER if that fails
            var ecdsaSignature: P256.Signing.ECDSASignature?
            
            // Try raw format first (64 bytes: r + s)
            if signature.count == 64 {
                print("[WebAuthn] U2F trying raw signature format (64 bytes)")
                ecdsaSignature = try? P256.Signing.ECDSASignature(rawRepresentation: signature)
            }
            
            // If raw format failed or signature is not 64 bytes, try DER format
            if ecdsaSignature == nil {
                print("[WebAuthn] U2F trying DER signature format (\(signature.count) bytes)")
                ecdsaSignature = try? P256.Signing.ECDSASignature(derRepresentation: signature)
            }
            
            guard let finalSignature = ecdsaSignature else {
                print("[WebAuthn] U2F signature verification failed: could not parse signature in either raw or DER format")
                throw WebAuthnError.verificationFailed
            }
            
            let isValid = p256PublicKey.isValidSignature(finalSignature, for: signedData)
            if !isValid {
                print("[WebAuthn] U2F signature verification failed: signature validation failed")
                throw WebAuthnError.verificationFailed
            }
            
            print("[WebAuthn] ✅ U2F signature verification successful")
        } catch {
            print("[WebAuthn] U2F signature verification failed: \(error)")
            throw WebAuthnError.verificationFailed
        }
    }
    
    // MARK: - Verification Helpers
    
    private func verifyClientData(_ clientDataJSONString: String, type: String) throws {
        guard let clientDataJSON = Data(base64Encoded: clientDataJSONString),
              let clientData = try? JSONSerialization.jsonObject(with: clientDataJSON) as? [String: Any] else {
            throw WebAuthnError.invalidCredential
        }
        
        guard let clientType = clientData["type"] as? String,
              clientType == type else {
            throw WebAuthnError.invalidCredential
        }
        
        guard let origin = clientData["origin"] as? String else {
            throw WebAuthnError.invalidCredential
        }
        
        // Verify origin matches expected RP ID with flexible port handling
        let isValidOrigin = isOriginValid(origin: origin, rpId: rpId)
        guard isValidOrigin else {
            print("[WebAuthn] 🚨 Origin mismatch: \(origin) not valid for RP ID: \(rpId)")
            throw WebAuthnError.invalidCredential
        }
    }
    
    private func isOriginValid(origin: String, rpId: String) -> Bool {
        // Parse the origin URL
        guard let originURL = URL(string: origin) else {
            print("[WebAuthn] 🚨 Invalid origin URL: \(origin)")
            return false
        }
        
        // Extract scheme and host from origin
        guard let scheme = originURL.scheme,
              let host = originURL.host else {
            print("[WebAuthn] 🚨 Could not extract scheme/host from origin: \(origin)")
            return false
        }
        
        // Special handling for localhost with ports
        let hostMatches: Bool
        if rpId.lowercased() == "localhost" && host.lowercased() == "localhost" {
            // For localhost, ignore the port - any localhost port is valid
            hostMatches = true
            print("[WebAuthn] ✅ Localhost origin validation: accepting any localhost port")
        } else {
            // For other domains, require exact match
            hostMatches = host.lowercased() == rpId.lowercased()
        }
        
        // Allow both HTTP and HTTPS schemes
        let schemeMatches = scheme == "http" || scheme == "https"
        
        let isValid = hostMatches && schemeMatches
        
        if !isValid {
            print("[WebAuthn] 🚨 Origin validation failed:")
            print("[WebAuthn]   Origin: \(origin)")
            print("[WebAuthn]   Parsed host: \(host)")
            print("[WebAuthn]   Parsed scheme: \(scheme)")
            print("[WebAuthn]   RP ID: \(rpId)")
            print("[WebAuthn]   Host matches: \(hostMatches)")
            print("[WebAuthn]   Scheme matches: \(schemeMatches)")
        } else {
            print("[WebAuthn] ✅ Origin validation passed: \(origin) is valid for RP ID: \(rpId)")
        }
        
        return isValid
    }
    
    private func verifySignature(authenticatorData: String, clientDataJSON: String, signature: String, storedCredential: WebAuthnCredential) throws {
        guard let authDataBytes = Data(base64Encoded: authenticatorData),
              let clientDataBytes = Data(base64Encoded: clientDataJSON),
              let signatureBytes = Data(base64Encoded: signature) else {
            throw WebAuthnError.invalidCredential
        }
        
        // Create signed data: authenticatorData + SHA256(clientDataJSON)
        let clientDataHash = SHA256.hash(data: clientDataBytes)
        var signedData = authDataBytes
        signedData.append(Data(clientDataHash))
        
        // Verify signature based on algorithm
        switch storedCredential.algorithm {
        case -7: // ES256
            try verifyES256Signature(signedData: signedData, signature: signatureBytes, publicKey: storedCredential.publicKey)
        case -257: // RS256
            try verifyRS256Signature(signedData: signedData, signature: signatureBytes, publicKey: storedCredential.publicKey)
        default:
            throw WebAuthnError.invalidCredential
        }
    }
    
    private func verifyES256Signature(signedData: Data, signature: Data, publicKey: String) throws {
        guard let publicKeyData = Data(base64Encoded: publicKey),
              publicKeyData.count == 65,
              publicKeyData[0] == 0x04 else {
            throw WebAuthnError.invalidCredential
        }
        
        // Create P256 public key
        do {
            let p256PublicKey = try P256.Signing.PublicKey(x963Representation: publicKeyData)
            
            // WebAuthn signatures can be either raw format (64 bytes) or DER format
            // Try raw format first, then DER if that fails
            var ecdsaSignature: P256.Signing.ECDSASignature?
            
            // Try raw format first (64 bytes: r + s concatenated)
            if signature.count == 64 {
                print("[WebAuthn] ES256 trying raw signature format (64 bytes)")
                ecdsaSignature = try? P256.Signing.ECDSASignature(rawRepresentation: signature)
            }
            
            // If raw format failed or signature is not 64 bytes, try DER format
            if ecdsaSignature == nil {
                print("[WebAuthn] ES256 trying DER signature format (\(signature.count) bytes)")
                ecdsaSignature = try? P256.Signing.ECDSASignature(derRepresentation: signature)
            }
            
            guard let finalSignature = ecdsaSignature else {
                print("[WebAuthn] ES256 signature verification failed: could not parse signature in either raw or DER format")
                throw WebAuthnError.verificationFailed
            }
            
            let isValid = p256PublicKey.isValidSignature(finalSignature, for: signedData)
            if !isValid {
                print("[WebAuthn] ES256 signature verification failed: signature validation failed")
                throw WebAuthnError.verificationFailed
            }
            
            print("[WebAuthn] ✅ ES256 signature verification successful")
        } catch {
            print("[WebAuthn] ES256 signature verification failed: \(error)")
            throw WebAuthnError.verificationFailed
        }
    }
    
    private func verifyRS256Signature(signedData: Data, signature: Data, publicKey: String) throws {
        // For RSA verification, we would need to implement RSA signature verification
        // This is a placeholder - in production you'd use Security framework or CryptoKit
        print("[WebAuthn] RS256 signature verification not fully implemented")
        // For now, just pass - this should be implemented with proper RSA verification
    }
    
    private func generateChallenge() -> String {
        let challenge = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        return challenge.base64EncodedString()
    }
    
    private func generateUserId() -> String {
        let userId = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
        return userId.base64EncodedString()
    }
    
    public func isUsernameRegistered(_ username: String) -> Bool {
        return credentials[username] != nil
    }
    
    // Check if user exists and is enabled
    public func isUserEnabled(username: String) -> Bool {
        guard let adminUser = PersistenceManager.shared.getAdminUser(by: username) else {
            return false // User doesn't exist
        }
        return adminUser.isEnabled
    }
    
    // Check if user exists and is enabled by credential ID
    public func isUserEnabledByCredential(_ credentialId: String) -> Bool {
        guard let adminUser = PersistenceManager.shared.getAdminUser(byCredentialId: credentialId) else {
            return false // User doesn't exist
        }
        return adminUser.isEnabled
    }
    
    // Update user emoji
    public func updateUserEmoji(username: String, emoji: String) -> Bool {
        guard let adminUser = PersistenceManager.shared.getAdminUser(by: username) else {
            print("[WebAuthn] ❌ User \(username) not found for emoji update")
            return false
        }
        
        let updatedUser = adminUser.withEmoji(emoji)
        PersistenceManager.shared.saveAdminUser(updatedUser)
        print("[WebAuthn] ✅ Updated emoji for \(username) to \(emoji)")
        return true
    }
    
    // Get user emoji
    public func getUserEmoji(username: String) -> String? {
        guard let adminUser = PersistenceManager.shared.getAdminUser(by: username) else {
            print("[WebAuthn] ❌ User \(username) not found for emoji retrieval")
            return nil
        }
        return adminUser.emoji
    }
}

public enum WebAuthnError: Error, Equatable {
    case credentialNotFound
    case invalidCredential
    case verificationFailed
    case duplicateUsername
    case signCountInvalid
    case accessDenied
} 
