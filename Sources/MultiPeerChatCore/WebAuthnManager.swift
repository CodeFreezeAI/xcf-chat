import Foundation
import CryptoKit

class WebAuthnManager {
    private var credentials: [String: WebAuthnCredential] = [:]
    private let credentialsFile = "webauthn_credentials.json"
    private let rpId: String
    
    init(rpId: String = "localhost") {
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
                    "userVerification": "preferred",
                    "requireResidentKey": false
                ]
            ]
        ]
        
        return options
    }
    
    func generateAuthenticationOptions(username: String) throws -> [String: Any] {
        guard let credential = credentials[username] else {
            throw WebAuthnError.credentialNotFound
        }
        
        let challenge = generateChallenge()
        
        let options: [String: Any] = [
            "publicKey": [
                "challenge": challenge,
                "timeout": 60000,
                "rpId": rpId,
                "allowCredentials": [
                    [
                        "type": "public-key",
                        "id": credential.id,
                        "transports": ["internal"]
                    ]
                ],
                "userVerification": "preferred"
            ]
        ]
        
        return options
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

        guard let id = credential["id"] as? String else {
            print("[WebAuthn] MISSING id")
            throw WebAuthnError.invalidCredential
        }
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
        // Store the credential
        let newCredential = WebAuthnCredential(
            id: id,
            publicKey: rawId, // In a real implementation, this would be the public key
            signCount: 0,
            username: username
        )
        credentials[username] = newCredential
        saveCredentials()
    }
    
    func verifyAuthentication(username: String, credential: [String: Any]) throws {
        print("[WebAuthn] verifyAuthentication called for username: \(username)")
        print("[WebAuthn] credential received: \(credential)")
        guard let storedCredential = credentials[username] else {
            print("[WebAuthn] credentialNotFound for username: \(username)")
            throw WebAuthnError.credentialNotFound
        }
        guard let id = credential["id"] as? String else {
            print("[WebAuthn] MISSING id")
            throw WebAuthnError.invalidCredential
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
        // In a real implementation, you would:
        // 1. Verify the signature
        // 2. Verify the client data
        // 3. Update the sign count
        if id != storedCredential.id {
            print("[WebAuthn] id does not match storedCredential.id")
            throw WebAuthnError.invalidCredential
        }
        print("[WebAuthn] All required fields present. id=\(id)")
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