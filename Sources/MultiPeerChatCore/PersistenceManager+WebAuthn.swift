import Foundation
import DogTagKit

// MARK: - PersistenceManager WebAuthn Integration

extension PersistenceManager: WebAuthnUserManager {
    
    /// Check if a user is enabled and can authenticate
    public func isUserEnabled(username: String) -> Bool {
        guard let user = getAdminUser(by: username) else {
            return false // User doesn't exist
        }
        return user.isEnabled
    }
    
    /// Get user emoji for display
    public func getUserEmoji(username: String) -> String? {
        return getAdminUser(by: username)?.emoji
    }
    
    /// Update user emoji
    public func updateUserEmoji(username: String, emoji: String) -> Bool {
        guard let user = getAdminUser(by: username) else {
            return false
        }
        
        let updatedUser = user.withEmoji(emoji)
        saveAdminUser(updatedUser)
        return true
    }
    
    /// Create or update user record after registration
    public func createUser(username: String, credentialId: String, publicKey: String, clientIP: String?, emoji: String) throws {
        let userNumber = getNextUserNumber()
        
        let adminUser = AdminUser(
            username: username,
            credentialId: credentialId,
            publicKey: publicKey,
            signCount: 0,
            lastLoginIP: clientIP,
            userNumber: userNumber,
            emoji: emoji
        )
        
        saveAdminUser(adminUser)
        print("[WebAuthn] Created admin user record for \(username) (#\(userNumber)) with emoji \(emoji)")
    }
    
    /// Update user login information after authentication
    public func updateUserLogin(username: String, signCount: UInt32, clientIP: String?) throws {
        guard let user = getAdminUser(by: username) else {
            throw WebAuthnError.credentialNotFound
        }
        
        let updatedUser = user.updatedWithLogin(ip: clientIP, signCount: signCount)
        saveAdminUser(updatedUser)
        print("[WebAuthn] Updated user record for \(username) with sign count \(signCount) and IP \(clientIP ?? "unknown")")
    }
    
    /// Delete user and associated data
    public func deleteUser(username: String) throws {
        guard let user = getAdminUser(by: username) else {
            throw WebAuthnError.credentialNotFound
        }
        
        deleteAdminUser(user.id)
        print("[WebAuthn] Deleted user record for \(username)")
    }
} 