import XCTest
@testable import MultiPeerChatCore

final class WebAuthnTests: XCTestCase {
    var webAuthnManager: WebAuthnManager!
    
    override func setUp() {
        super.setUp()
        webAuthnManager = WebAuthnManager()
    }
    
    override func tearDown() {
        webAuthnManager = nil
        super.tearDown()
    }
    
    func testGenerateRegistrationOptions() throws {
        let username = "testuser"
        let options = try webAuthnManager.generateRegistrationOptions(username: username)
        
        // Verify the structure of the options
        XCTAssertNotNil(options["publicKey"])
        let publicKey = options["publicKey"] as! [String: Any]
        
        XCTAssertNotNil(publicKey["challenge"])
        XCTAssertNotNil(publicKey["rp"])
        XCTAssertNotNil(publicKey["user"])
        XCTAssertNotNil(publicKey["pubKeyCredParams"])
        XCTAssertNotNil(publicKey["timeout"])
        XCTAssertNotNil(publicKey["attestation"])
        XCTAssertNotNil(publicKey["authenticatorSelection"])
        
        // Verify user information
        let user = publicKey["user"] as! [String: Any]
        XCTAssertEqual(user["name"] as? String, username)
        XCTAssertEqual(user["displayName"] as? String, username)
    }
    
    func testGenerateAuthenticationOptions() throws {
        // First register a user
        let username = "testuser"
        let registrationOptions = try webAuthnManager.generateRegistrationOptions(username: username)
        
        // Create a mock credential
        let mockCredential: [String: Any] = [
            "id": "test-id",
            "rawId": "test-raw-id",
            "response": [
                "attestationObject": "test-attestation",
                "clientDataJSON": "test-client-data"
            ],
            "type": "public-key",
            "username": username
        ]
        
        // Register the credential
        try webAuthnManager.verifyRegistration(username: username, credential: mockCredential)
        
        // Now test authentication options
        let authOptions = try webAuthnManager.generateAuthenticationOptions(username: username)
        
        // Verify the structure of the options
        XCTAssertNotNil(authOptions["publicKey"])
        let publicKey = authOptions["publicKey"] as! [String: Any]
        
        XCTAssertNotNil(publicKey["challenge"])
        XCTAssertNotNil(publicKey["timeout"])
        XCTAssertNotNil(publicKey["rpId"])
        XCTAssertNotNil(publicKey["allowCredentials"])
        XCTAssertNotNil(publicKey["userVerification"])
        
        // Verify allowCredentials
        let allowCredentials = publicKey["allowCredentials"] as! [[String: Any]]
        XCTAssertEqual(allowCredentials.count, 1)
        XCTAssertEqual(allowCredentials[0]["id"] as? String, "test-id")
    }
    
    func testVerifyRegistration() throws {
        let username = "testuser"
        let mockCredential: [String: Any] = [
            "id": "test-id",
            "rawId": "test-raw-id",
            "response": [
                "attestationObject": "test-attestation",
                "clientDataJSON": "test-client-data"
            ],
            "type": "public-key",
            "username": username
        ]
        
        // Should not throw
        try webAuthnManager.verifyRegistration(username: username, credential: mockCredential)
    }
    
    func testVerifyRegistrationWithInvalidCredential() {
        let username = "testuser"
        let invalidCredential: [String: Any] = [
            "id": "test-id",
            // Missing required fields
            "type": "public-key",
            "username": username
        ]
        
        XCTAssertThrowsError(try webAuthnManager.verifyRegistration(username: username, credential: invalidCredential))
    }
    
    func testVerifyAuthentication() throws {
        // First register a user
        let username = "testuser"
        let mockCredential: [String: Any] = [
            "id": "test-id",
            "rawId": "test-raw-id",
            "response": [
                "attestationObject": "test-attestation",
                "clientDataJSON": "test-client-data"
            ],
            "type": "public-key",
            "username": username
        ]
        
        try webAuthnManager.verifyRegistration(username: username, credential: mockCredential)
        
        // Now test authentication
        let authCredential: [String: Any] = [
            "id": "test-id",
            "response": [
                "clientDataJSON": "test-client-data",
                "authenticatorData": "test-auth-data",
                "signature": "test-signature"
            ],
            "type": "public-key",
            "username": username
        ]
        
        // Should not throw
        try webAuthnManager.verifyAuthentication(username: username, credential: authCredential)
    }
    
    func testVerifyAuthenticationWithInvalidCredential() {
        let username = "testuser"
        let invalidCredential: [String: Any] = [
            "id": "wrong-id",
            "response": [
                "clientDataJSON": "test-client-data",
                "authenticatorData": "test-auth-data",
                "signature": "test-signature"
            ],
            "type": "public-key",
            "username": username
        ]
        
        XCTAssertThrowsError(try webAuthnManager.verifyAuthentication(username: username, credential: invalidCredential))
    }
} 