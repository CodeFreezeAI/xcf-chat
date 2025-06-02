import XCTest
import Foundation
import CryptoKit
@testable import MultiPeerChatCore

final class WebAuthnManagerTests: XCTestCase {
    
    var webAuthnManager: WebAuthnManager!
    let testRpId = "example.com"
    
    override func setUp() {
        super.setUp()
        webAuthnManager = WebAuthnManager(rpId: testRpId)
        
        // Clean up any existing test credentials
        let testCredentialsFile = "webauthn_credentials.json"
        if FileManager.default.fileExists(atPath: testCredentialsFile) {
            try? FileManager.default.removeItem(atPath: testCredentialsFile)
        }
    }
    
    override func tearDown() {
        // Clean up test files
        let testCredentialsFile = "webauthn_credentials.json"
        try? FileManager.default.removeItem(atPath: testCredentialsFile)
        super.tearDown()
    }
    
    // MARK: - Mock Data Helpers
    
    func createMockES256PublicKey() -> (privateKey: P256.Signing.PrivateKey, publicKeyData: Data, coseKey: [String: Any]) {
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        let publicKeyData = publicKey.x963Representation
        
        // Extract x and y coordinates for COSE key format
        let x = publicKeyData.subdata(in: 1..<33)
        let y = publicKeyData.subdata(in: 33..<65)
        
        let coseKey: [String: Any] = [
            "1": 2,  // kty: EC2
            "3": -7, // alg: ES256
            "-1": 1, // crv: P-256
            "-2": x, // x coordinate
            "-3": y  // y coordinate
        ]
        
        return (privateKey, publicKeyData, coseKey)
    }
    
    func encodeCBOR(_ value: Any) -> Data {
        // Simple CBOR encoder for test data
        if let map = value as? [String: Any] {
            var data = Data([0xA0 | UInt8(map.count)]) // Map with count
            for (key, val) in map.sorted(by: { $0.key < $1.key }) {
                if let intKey = Int(key) {
                    data.append(encodeCBORInteger(intKey))
                } else {
                    data.append(encodeCBORString(key))
                }
                data.append(encodeCBOR(val))
            }
            return data
        } else if let data = value as? Data {
            var result = Data()
            if data.count < 24 {
                result.append(0x40 | UInt8(data.count))
            } else if data.count < 256 {
                result.append(0x58)
                result.append(UInt8(data.count))
            } else {
                result.append(0x59)
                result.append(UInt8(data.count >> 8))
                result.append(UInt8(data.count & 0xFF))
            }
            result.append(data)
            return result
        } else if let int = value as? Int {
            return encodeCBORInteger(int)
        } else if let string = value as? String {
            return encodeCBORString(string)
        }
        return Data()
    }
    
    private func encodeCBORInteger(_ value: Int) -> Data {
        if value >= 0 {
            if value < 24 {
                return Data([UInt8(value)])
            } else if value < 256 {
                return Data([0x18, UInt8(value)])
            } else {
                return Data([0x19, UInt8(value >> 8), UInt8(value & 0xFF)])
            }
        } else {
            let positive = -value - 1
            if positive < 24 {
                return Data([0x20 | UInt8(positive)])
            } else if positive < 256 {
                return Data([0x38, UInt8(positive)])
            } else {
                return Data([0x39, UInt8(positive >> 8), UInt8(positive & 0xFF)])
            }
        }
    }
    
    private func encodeCBORString(_ value: String) -> Data {
        let stringData = value.data(using: .utf8)!
        var result = Data()
        if stringData.count < 24 {
            result.append(0x60 | UInt8(stringData.count))
        } else if stringData.count < 256 {
            result.append(0x78)
            result.append(UInt8(stringData.count))
        }
        result.append(stringData)
        return result
    }
    
    func createMockAttestationObject(coseKey: [String: Any]) -> Data {
        let credentialId = Data(repeating: 0x01, count: 16)
        
        // Create authenticator data
        let rpIdHash = Data(SHA256.hash(data: testRpId.data(using: .utf8)!))
        let flags: UInt8 = 0x45 // UP | UV | AT flags
        let signCount = Data([0x00, 0x00, 0x00, 0x00])
        let aaguid = Data(repeating: 0x00, count: 16)
        let credentialIdLength = Data([0x00, UInt8(credentialId.count)])
        let publicKeyData = encodeCBOR(coseKey)
        
        var authData = Data()
        authData.append(rpIdHash)
        authData.append(flags)
        authData.append(signCount)
        authData.append(aaguid)
        authData.append(credentialIdLength)
        authData.append(credentialId)
        authData.append(publicKeyData)
        
        let attestationObject: [String: Any] = [
            "fmt": "none",
            "attStmt": [:] as [String: Any],
            "authData": authData
        ]
        
        return encodeCBOR(attestationObject)
    }
    
    func createMockClientDataJSON(type: String, challenge: String, origin: String) -> Data {
        let clientData: [String: Any] = [
            "type": type,
            "challenge": challenge,
            "origin": origin,
            "crossOrigin": false
        ]
        
        return try! JSONSerialization.data(withJSONObject: clientData)
    }
    
    // MARK: - Registration Options Tests
    
    func testGenerateRegistrationOptions() throws {
        let username = "testuser"
        let options = try webAuthnManager.generateRegistrationOptions(username: username)
        
        XCTAssertNotNil(options["publicKey"])
        
        let publicKey = options["publicKey"] as! [String: Any]
        XCTAssertNotNil(publicKey["challenge"])
        XCTAssertNotNil(publicKey["rp"])
        XCTAssertNotNil(publicKey["user"])
        XCTAssertNotNil(publicKey["pubKeyCredParams"])
        
        let rp = publicKey["rp"] as! [String: Any]
        XCTAssertEqual(rp["id"] as! String, testRpId)
        
        let user = publicKey["user"] as! [String: Any]
        XCTAssertEqual(user["name"] as! String, username)
        XCTAssertEqual(user["displayName"] as! String, username)
    }
    
    // MARK: - CBOR Parsing Tests
    
    func testCBORParsing() throws {
        let (_, _, coseKey) = createMockES256PublicKey()
        let attestationObjectData = createMockAttestationObject(coseKey: coseKey)
        let base64AttestationObject = attestationObjectData.base64EncodedString()
        
        // This should not throw
        let parsed = try WebAuthnManager.CBORDecoder.parseAttestationObject(base64AttestationObject)
        
        XCTAssertNotNil(parsed["authData"])
        XCTAssertNotNil(parsed["fmt"])
        XCTAssertEqual(parsed["fmt"] as! String, "none")
    }
    
    // MARK: - Registration Tests
    
    func testValidRegistration() throws {
        let username = "testuser"
        let (privateKey, publicKeyData, coseKey) = createMockES256PublicKey()
        
        let attestationObjectData = createMockAttestationObject(coseKey: coseKey)
        let clientDataJSON = createMockClientDataJSON(
            type: "webauthn.create",
            challenge: "test-challenge",
            origin: "https://\(testRpId)"
        )
        
        let credentialId = Data(repeating: 0x01, count: 16).base64EncodedString()
        
        let credential: [String: Any] = [
            "id": credentialId,
            "rawId": credentialId,
            "response": [
                "attestationObject": attestationObjectData.base64EncodedString(),
                "clientDataJSON": clientDataJSON.base64EncodedString()
            ],
            "type": "public-key"
        ]
        
        // This should not throw
        try webAuthnManager.verifyRegistration(username: username, credential: credential)
        
        // Verify the user is now registered
        XCTAssertTrue(webAuthnManager.isUsernameRegistered(username))
    }
    
    func testDuplicateRegistration() throws {
        let username = "testuser"
        let (_, _, coseKey) = createMockES256PublicKey()
        
        let attestationObjectData = createMockAttestationObject(coseKey: coseKey)
        let clientDataJSON = createMockClientDataJSON(
            type: "webauthn.create",
            challenge: "test-challenge",
            origin: "https://\(testRpId)"
        )
        
        let credentialId = Data(repeating: 0x01, count: 16).base64EncodedString()
        
        let credential: [String: Any] = [
            "id": credentialId,
            "rawId": credentialId,
            "response": [
                "attestationObject": attestationObjectData.base64EncodedString(),
                "clientDataJSON": clientDataJSON.base64EncodedString()
            ],
            "type": "public-key"
        ]
        
        // First registration should succeed
        try webAuthnManager.verifyRegistration(username: username, credential: credential)
        
        // Second registration should fail
        XCTAssertThrowsError(try webAuthnManager.verifyRegistration(username: username, credential: credential)) { error in
            XCTAssertTrue(error is WebAuthnError)
            XCTAssertEqual(error as! WebAuthnError, WebAuthnError.duplicateUsername)
        }
    }
    
    func testRegistrationWithInvalidOrigin() throws {
        let username = "testuser"
        let (_, _, coseKey) = createMockES256PublicKey()
        
        let attestationObjectData = createMockAttestationObject(coseKey: coseKey)
        let clientDataJSON = createMockClientDataJSON(
            type: "webauthn.create",
            challenge: "test-challenge",
            origin: "https://evil.com" // Wrong origin
        )
        
        let credentialId = Data(repeating: 0x01, count: 16).base64EncodedString()
        
        let credential: [String: Any] = [
            "id": credentialId,
            "rawId": credentialId,
            "response": [
                "attestationObject": attestationObjectData.base64EncodedString(),
                "clientDataJSON": clientDataJSON.base64EncodedString()
            ],
            "type": "public-key"
        ]
        
        // Should fail due to invalid origin
        XCTAssertThrowsError(try webAuthnManager.verifyRegistration(username: username, credential: credential)) { error in
            XCTAssertTrue(error is WebAuthnError)
            XCTAssertEqual(error as! WebAuthnError, WebAuthnError.invalidCredential)
        }
    }
    
    // MARK: - Authentication Options Tests
    
    func testGenerateAuthenticationOptions() throws {
        // First register a user
        let username = "testuser"
        let (_, _, coseKey) = createMockES256PublicKey()
        
        let attestationObjectData = createMockAttestationObject(coseKey: coseKey)
        let clientDataJSON = createMockClientDataJSON(
            type: "webauthn.create",
            challenge: "test-challenge",
            origin: "https://\(testRpId)"
        )
        
        let credentialId = Data(repeating: 0x01, count: 16).base64EncodedString()
        
        let credential: [String: Any] = [
            "id": credentialId,
            "rawId": credentialId,
            "response": [
                "attestationObject": attestationObjectData.base64EncodedString(),
                "clientDataJSON": clientDataJSON.base64EncodedString()
            ],
            "type": "public-key"
        ]
        
        try webAuthnManager.verifyRegistration(username: username, credential: credential)
        
        // Now test authentication options
        let authOptions = try webAuthnManager.generateAuthenticationOptions(username: username)
        
        XCTAssertNotNil(authOptions["publicKey"])
        
        let publicKey = authOptions["publicKey"] as! [String: Any]
        XCTAssertNotNil(publicKey["challenge"])
        XCTAssertEqual(publicKey["rpId"] as! String, testRpId)
        XCTAssertNotNil(publicKey["allowCredentials"])
        
        let allowCredentials = publicKey["allowCredentials"] as! [[String: Any]]
        XCTAssertEqual(allowCredentials.count, 1)
        XCTAssertEqual(allowCredentials[0]["id"] as! String, credentialId)
    }
    
    func testGenerateAuthenticationOptionsUnregisteredUser() throws {
        XCTAssertThrowsError(try webAuthnManager.generateAuthenticationOptions(username: "nonexistent")) { error in
            XCTAssertTrue(error is WebAuthnError)
            XCTAssertEqual(error as! WebAuthnError, WebAuthnError.credentialNotFound)
        }
    }
    
    // MARK: - Authentication Tests
    
    func testValidAuthentication() throws {
        let username = "testuser"
        let (privateKey, publicKeyData, coseKey) = createMockES256PublicKey()
        
        // First register the user
        let attestationObjectData = createMockAttestationObject(coseKey: coseKey)
        let clientDataJSON = createMockClientDataJSON(
            type: "webauthn.create",
            challenge: "test-challenge",
            origin: "https://\(testRpId)"
        )
        
        let credentialId = Data(repeating: 0x01, count: 16).base64EncodedString()
        
        let registrationCredential: [String: Any] = [
            "id": credentialId,
            "rawId": credentialId,
            "response": [
                "attestationObject": attestationObjectData.base64EncodedString(),
                "clientDataJSON": clientDataJSON.base64EncodedString()
            ],
            "type": "public-key"
        ]
        
        try webAuthnManager.verifyRegistration(username: username, credential: registrationCredential)
        
        // Now test authentication
        let authClientDataJSON = createMockClientDataJSON(
            type: "webauthn.get",
            challenge: "auth-challenge",
            origin: "https://\(testRpId)"
        )
        
        // Create mock authenticator data
        let rpIdHash = Data(SHA256.hash(data: testRpId.data(using: .utf8)!))
        let flags: UInt8 = 0x05 // UP | UV flags
        let signCount = Data([0x00, 0x00, 0x00, 0x01])
        var authenticatorData = Data()
        authenticatorData.append(rpIdHash)
        authenticatorData.append(flags)
        authenticatorData.append(signCount)
        
        // Create signature
        let clientDataHash = SHA256.hash(data: authClientDataJSON)
        var signedData = authenticatorData
        signedData.append(Data(clientDataHash))
        
        let signature = try privateKey.signature(for: signedData)
        
        let authCredential: [String: Any] = [
            "id": credentialId,
            "response": [
                "clientDataJSON": authClientDataJSON.base64EncodedString(),
                "authenticatorData": authenticatorData.base64EncodedString(),
                "signature": signature.derRepresentation.base64EncodedString()
            ],
            "type": "public-key"
        ]
        
        // This should not throw and should return the username
        let result = try webAuthnManager.verifyAuthentication(username: "", credential: authCredential)
        XCTAssertEqual(result, username)
    }
    
    func testAuthenticationWithInvalidSignature() throws {
        let username = "testuser"
        let (privateKey, publicKeyData, coseKey) = createMockES256PublicKey()
        
        // First register the user
        let attestationObjectData = createMockAttestationObject(coseKey: coseKey)
        let clientDataJSON = createMockClientDataJSON(
            type: "webauthn.create",
            challenge: "test-challenge",
            origin: "https://\(testRpId)"
        )
        
        let credentialId = Data(repeating: 0x01, count: 16).base64EncodedString()
        
        let registrationCredential: [String: Any] = [
            "id": credentialId,
            "rawId": credentialId,
            "response": [
                "attestationObject": attestationObjectData.base64EncodedString(),
                "clientDataJSON": clientDataJSON.base64EncodedString()
            ],
            "type": "public-key"
        ]
        
        try webAuthnManager.verifyRegistration(username: username, credential: registrationCredential)
        
        // Now test authentication with invalid signature
        let authClientDataJSON = createMockClientDataJSON(
            type: "webauthn.get",
            challenge: "auth-challenge",
            origin: "https://\(testRpId)"
        )
        
        let rpIdHash = Data(SHA256.hash(data: testRpId.data(using: .utf8)!))
        let flags: UInt8 = 0x05
        let signCount = Data([0x00, 0x00, 0x00, 0x01])
        var authenticatorData = Data()
        authenticatorData.append(rpIdHash)
        authenticatorData.append(flags)
        authenticatorData.append(signCount)
        
        // Create invalid signature (random data)
        let invalidSignature = Data(repeating: 0xFF, count: 64)
        
        let authCredential: [String: Any] = [
            "id": credentialId,
            "response": [
                "clientDataJSON": authClientDataJSON.base64EncodedString(),
                "authenticatorData": authenticatorData.base64EncodedString(),
                "signature": invalidSignature.base64EncodedString()
            ],
            "type": "public-key"
        ]
        
        // Should fail due to invalid signature
        XCTAssertThrowsError(try webAuthnManager.verifyAuthentication(username: username, credential: authCredential)) { error in
            XCTAssertTrue(error is WebAuthnError)
            XCTAssertEqual(error as! WebAuthnError, WebAuthnError.verificationFailed)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testRegistrationMissingFields() throws {
        let username = "testuser"
        
        // Test missing id
        var credential: [String: Any] = [
            "response": [
                "attestationObject": "test",
                "clientDataJSON": "test"
            ]
        ]
        
        XCTAssertThrowsError(try webAuthnManager.verifyRegistration(username: username, credential: credential))
        
        // Test missing response
        credential = [
            "id": "test-id"
        ]
        
        XCTAssertThrowsError(try webAuthnManager.verifyRegistration(username: username, credential: credential))
        
        // Test missing attestationObject
        credential = [
            "id": "test-id",
            "response": [
                "clientDataJSON": "test"
            ]
        ]
        
        XCTAssertThrowsError(try webAuthnManager.verifyRegistration(username: username, credential: credential))
    }
    
    func testAuthenticationMissingFields() throws {
        let username = "testuser"
        
        // Test missing signature
        var credential: [String: Any] = [
            "id": "test-id",
            "response": [
                "clientDataJSON": "test",
                "authenticatorData": "test"
            ]
        ]
        
        XCTAssertThrowsError(try webAuthnManager.verifyAuthentication(username: username, credential: credential))
        
        // Test missing authenticatorData
        credential = [
            "id": "test-id",
            "response": [
                "clientDataJSON": "test",
                "signature": "test"
            ]
        ]
        
        XCTAssertThrowsError(try webAuthnManager.verifyAuthentication(username: username, credential: credential))
    }
    
    // MARK: - Persistence Tests
    
    func testCredentialPersistence() throws {
        let username = "testuser"
        let (_, _, coseKey) = createMockES256PublicKey()
        
        let attestationObjectData = createMockAttestationObject(coseKey: coseKey)
        let clientDataJSON = createMockClientDataJSON(
            type: "webauthn.create",
            challenge: "test-challenge",
            origin: "https://\(testRpId)"
        )
        
        let credentialId = Data(repeating: 0x01, count: 16).base64EncodedString()
        
        let credential: [String: Any] = [
            "id": credentialId,
            "rawId": credentialId,
            "response": [
                "attestationObject": attestationObjectData.base64EncodedString(),
                "clientDataJSON": clientDataJSON.base64EncodedString()
            ],
            "type": "public-key"
        ]
        
        // Register user
        try webAuthnManager.verifyRegistration(username: username, credential: credential)
        XCTAssertTrue(webAuthnManager.isUsernameRegistered(username))
        
        // Create new manager instance to test persistence
        let newManager = WebAuthnManager(rpId: testRpId)
        XCTAssertTrue(newManager.isUsernameRegistered(username))
    }
} 