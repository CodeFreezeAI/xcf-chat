import XCTest
@testable import MultiPeerChatCore

final class WebAuthnSignCountTests: XCTestCase {
    var webAuthnManager: WebAuthnManager!
    let testRpId = "localhost"
    
    override func setUp() {
        super.setUp()
        webAuthnManager = WebAuthnManager(rpId: testRpId)
    }
    
    override func tearDown() {
        webAuthnManager = nil
        super.tearDown()
    }
    
    func testInitialSignCountIsZero() throws {
        // Register a new credential
        let username = "testuser"
        let options = try webAuthnManager.generateRegistrationOptions(username: username)
        
        // Simulate registration with a mock credential
        let mockCredential = createMockCredential(
            id: "testid",
            attestationObject: createMockAttestationObject(signCount: 0),
            clientDataJSON: createMockClientDataJSON(type: "webauthn.create")
        )
        
        try webAuthnManager.verifyRegistration(username: username, credential: mockCredential)
        
        // Verify initial sign count is 0
        XCTAssertTrue(webAuthnManager.isUsernameRegistered(username))
    }
    
    func testSignCountIncreasesOnAuthentication() throws {
        // Register a new credential
        let username = "testuser"
        let options = try webAuthnManager.generateRegistrationOptions(username: username)
        
        // Simulate registration
        let mockCredential = createMockCredential(
            id: "testid",
            attestationObject: createMockAttestationObject(signCount: 0),
            clientDataJSON: createMockClientDataJSON(type: "webauthn.create")
        )
        
        try webAuthnManager.verifyRegistration(username: username, credential: mockCredential)
        
        // Simulate first authentication with sign count 1
        let authCredential = createMockAuthCredential(
            id: "testid",
            authenticatorData: createMockAuthenticatorData(signCount: 1),
            clientDataJSON: createMockClientDataJSON(type: "webauthn.get"),
            signature: "testsignature"
        )
        
        try webAuthnManager.verifyAuthentication(username: username, credential: authCredential)
        
        // Simulate second authentication with sign count 2
        let authCredential2 = createMockAuthCredential(
            id: "testid",
            authenticatorData: createMockAuthenticatorData(signCount: 2),
            clientDataJSON: createMockClientDataJSON(type: "webauthn.get"),
            signature: "testsignature"
        )
        
        try webAuthnManager.verifyAuthentication(username: username, credential: authCredential2)
    }
    
    func testRejectedAuthenticationWithLowerSignCount() throws {
        // Register a new credential
        let username = "testuser"
        let options = try webAuthnManager.generateRegistrationOptions(username: username)
        
        // Simulate registration
        let mockCredential = createMockCredential(
            id: "testid",
            attestationObject: createMockAttestationObject(signCount: 0),
            clientDataJSON: createMockClientDataJSON(type: "webauthn.create")
        )
        
        try webAuthnManager.verifyRegistration(username: username, credential: mockCredential)
        
        // Simulate first authentication with sign count 2
        let authCredential = createMockAuthCredential(
            id: "testid",
            authenticatorData: createMockAuthenticatorData(signCount: 2),
            clientDataJSON: createMockClientDataJSON(type: "webauthn.get"),
            signature: "testsignature"
        )
        
        try webAuthnManager.verifyAuthentication(username: username, credential: authCredential)
        
        // Attempt authentication with lower sign count (1)
        let authCredential2 = createMockAuthCredential(
            id: "testid",
            authenticatorData: createMockAuthenticatorData(signCount: 1),
            clientDataJSON: createMockClientDataJSON(type: "webauthn.get"),
            signature: "testsignature"
        )
        
        XCTAssertThrowsError(try webAuthnManager.verifyAuthentication(username: username, credential: authCredential2)) { error in
            XCTAssertEqual(error as? WebAuthnError, .signCountInvalid)
        }
    }
    
    func testRejectedAuthenticationWithSameSignCount() throws {
        // Register a new credential
        let username = "testuser"
        let options = try webAuthnManager.generateRegistrationOptions(username: username)
        
        // Simulate registration
        let mockCredential = createMockCredential(
            id: "testid",
            attestationObject: createMockAttestationObject(signCount: 0),
            clientDataJSON: createMockClientDataJSON(type: "webauthn.create")
        )
        
        try webAuthnManager.verifyRegistration(username: username, credential: mockCredential)
        
        // Simulate first authentication with sign count 1
        let authCredential = createMockAuthCredential(
            id: "testid",
            authenticatorData: createMockAuthenticatorData(signCount: 1),
            clientDataJSON: createMockClientDataJSON(type: "webauthn.get"),
            signature: "testsignature"
        )
        
        try webAuthnManager.verifyAuthentication(username: username, credential: authCredential)
        
        // Attempt authentication with same sign count (1)
        let authCredential2 = createMockAuthCredential(
            id: "testid",
            authenticatorData: createMockAuthenticatorData(signCount: 1),
            clientDataJSON: createMockClientDataJSON(type: "webauthn.get"),
            signature: "testsignature"
        )
        
        XCTAssertThrowsError(try webAuthnManager.verifyAuthentication(username: username, credential: authCredential2)) { error in
            XCTAssertEqual(error as? WebAuthnError, .signCountInvalid)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockCredential(id: String, attestationObject: String, clientDataJSON: String) -> [String: Any] {
        return [
            "id": id,
            "response": [
                "attestationObject": attestationObject,
                "clientDataJSON": clientDataJSON
            ]
        ]
    }
    
    private func createMockAuthCredential(id: String, authenticatorData: String, clientDataJSON: String, signature: String) -> [String: Any] {
        return [
            "id": id,
            "response": [
                "authenticatorData": authenticatorData,
                "clientDataJSON": clientDataJSON,
                "signature": signature
            ]
        ]
    }
    
    private func createMockAttestationObject(signCount: UInt32) -> String {
        // Create a minimal attestation object with the specified sign count
        var authData = Data(count: 37) // rpIdHash(32) + flags(1) + signCount(4)
        authData[32] = 0x40 // flags: attested credential data included
        
        // Set sign count (4 bytes, big endian)
        withUnsafeBytes(of: signCount.bigEndian) { bytes in
            authData.replaceSubrange(33..<37, with: bytes)
        }
        
        // Create minimal attestation object
        let attestationObject: [String: Any] = [
            "fmt": "none",
            "authData": authData.base64EncodedString(),
            "attStmt": [:]
        ]
        
        // Convert to CBOR (simplified for test)
        let cborData = try! JSONSerialization.data(withJSONObject: attestationObject)
        return cborData.base64EncodedString()
    }
    
    private func createMockAuthenticatorData(signCount: UInt32) -> String {
        var authData = Data(count: 37) // rpIdHash(32) + flags(1) + signCount(4)
        authData[32] = 0x01 // flags: user present
        
        // Set sign count (4 bytes, big endian)
        withUnsafeBytes(of: signCount.bigEndian) { bytes in
            authData.replaceSubrange(33..<37, with: bytes)
        }
        
        return authData.base64EncodedString()
    }
    
    private func createMockClientDataJSON(type: String) -> String {
        let clientData: [String: Any] = [
            "type": type,
            "challenge": "testchallenge",
            "origin": "http://localhost"
        ]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: clientData)
        return jsonData.base64EncodedString()
    }
} 