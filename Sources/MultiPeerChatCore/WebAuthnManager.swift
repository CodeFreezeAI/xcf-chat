import Foundation

class WebAuthnManager {
    private var credentials: [String: WebAuthnCredential] = [:]
    private var credentialIdToUsername: [String: String] = [:]
    private let credentialsFile = "webauthn_credentials.json"
    private let rpId: String
    
    init(rpId: String) {
        self.rpId = rpId
        loadCredentials()
    }
    
    struct WebAuthnCredential: Codable {
        let id: String
        let publicKey: String
        let signCount: UInt32
        let username: String
    }
    
    private func loadCredentials() {
        let url = URL(fileURLWithPath: credentialsFile)
        guard FileManager.default.fileExists(atPath: credentialsFile) else { return }
        do {
            let data = try Data(contentsOf: url)
            let arr = try JSONDecoder().decode([WebAuthnCredential].self, from: data)
            for cred in arr {
                credentials[cred.username] = cred
                credentialIdToUsername[cred.id] = cred.username
            }
            print("[WebAuthn] Loaded \(arr.count) credentials from disk.")
        } catch {
            print("[WebAuthn] Failed to load credentials: \(error)")
        }
    }
    
    private func saveCredentials() {
        let arr = Array(credentials.values)
        let url = URL(fileURLWithPath: credentialsFile)
        do {
            let data = try JSONEncoder().encode(arr)
            try data.write(to: url)
            print("[WebAuthn] Saved \(arr.count) credentials to disk.")
        } catch {
            print("[WebAuthn] Failed to save credentials: \(error)")
        }
    }
    
    func generateRegistrationOptions(username: String) throws -> [String: Any] {
        let challenge = generateChallenge()
        let userId = generateUserId()
        
        let options: [String: Any] = [
            "publicKey": [
                "challenge": challenge,
                "rp": [
                    "name": rpId,
                    "id": rpId
                ],
                "user": [
                    "id": userId,
                    "name": username,
                    "displayName": username
                ],
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
    
    func generateAuthenticationOptions(username: String?) throws -> [String: Any] {
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
    
    func verifyRegistration(username: String, credential: [String: Any]) throws {
        if credentials[username] != nil {
            print("[WebAuthn] Registration failed: duplicate username \(username)")
            throw WebAuthnError.duplicateUsername
        }
        print("[WebAuthn] verifyRegistration called for username: \(username)")
        print("[WebAuthn] credential received: \(credential)")
        // In a real implementation, you would:
        // 1. Verify the attestation object
        // 2. Verify the client data
        // 3. Store the credential

        guard let idRaw = credential["id"] as? String else {
            print("[WebAuthn] MISSING id")
            throw WebAuthnError.invalidCredential
        }
        let id = base64urlToBase64(idRaw)
        guard let rawId = credential["rawId"] as? String else {
            print("[WebAuthn] MISSING rawId")
            throw WebAuthnError.invalidCredential
        }
        guard let response = credential["response"] as? [String: Any] else {
            print("[WebAuthn] MISSING response")
            throw WebAuthnError.invalidCredential
        }
        guard let _ = response["attestationObject"] as? String else {
            print("[WebAuthn] MISSING attestationObject")
            throw WebAuthnError.invalidCredential
        }
        guard let _ = response["clientDataJSON"] as? String else {
            print("[WebAuthn] MISSING clientDataJSON")
            throw WebAuthnError.invalidCredential
        }
        print("[WebAuthn] All required fields present. id=\(id) rawId=\(rawId)")
        // Store the credential and mapping for authentication
        let newCredential = WebAuthnCredential(
            id: id,
            publicKey: rawId, // In a real implementation, this would be the public key
            signCount: 0,
            username: username
        )
        credentials[username] = newCredential
        credentialIdToUsername[id] = username // Store mapping for authentication
        saveCredentials()
    }
    
    func verifyAuthentication(username: String?, credential: [String: Any]) throws -> String? {
        print("[WebAuthn] verifyAuthentication called for username: \(username ?? "nil")")
        print("[WebAuthn] credential received: \(credential)")
        
        guard let idRaw = credential["id"] as? String else {
            print("[WebAuthn] MISSING id")
            throw WebAuthnError.invalidCredential
        }
        let id = base64urlToBase64(idRaw)
        // If username is not provided, look it up by credentialId (WebAuthn standard)
        let usernameToUse = (username?.isEmpty ?? true) ? credentialIdToUsername[id] : username
        guard let finalUsername = usernameToUse else {
            print("[WebAuthn] No username found for credential ID: \(id)")
            throw WebAuthnError.credentialNotFound
        }
        guard let storedCredential = credentials[finalUsername] else {
            print("[WebAuthn] credentialNotFound for username: \(finalUsername)")
            throw WebAuthnError.credentialNotFound
        }
        guard let response = credential["response"] as? [String: Any] else {
            print("[WebAuthn] MISSING response")
            throw WebAuthnError.invalidCredential
        }
        guard let _ = response["clientDataJSON"] as? String else {
            print("[WebAuthn] MISSING clientDataJSON")
            throw WebAuthnError.invalidCredential
        }
        guard let _ = response["authenticatorData"] as? String else {
            print("[WebAuthn] MISSING authenticatorData")
            throw WebAuthnError.invalidCredential
        }
        guard let _ = response["signature"] as? String else {
            print("[WebAuthn] MISSING signature")
            throw WebAuthnError.invalidCredential
        }
        if id != storedCredential.id {
            print("[WebAuthn] id does not match storedCredential.id (auth: \(id), stored: \(storedCredential.id))")
            throw WebAuthnError.invalidCredential
        }
        print("[WebAuthn] All required fields present. id=\(id)")
        // Return the username if it was found from the credential ID
        return (username?.isEmpty ?? true) ? finalUsername : nil
    }
    
    private func generateChallenge() -> String {
        let challenge = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        return challenge.base64EncodedString()
    }
    
    private func generateUserId() -> String {
        let userId = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
        return userId.base64EncodedString()
    }
    
    func isUsernameRegistered(_ username: String) -> Bool {
        return credentials[username] != nil
    }
}

enum WebAuthnError: Error {
    case credentialNotFound
    case invalidCredential
    case verificationFailed
    case duplicateUsername
} 
