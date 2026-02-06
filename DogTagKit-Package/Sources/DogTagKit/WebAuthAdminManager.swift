import Foundation

public class WebAuthAdminManager {
    private let webAuthnManager: WebAuthnManager
    private let configuredAdminUsername: String
    
    public init(webAuthnManager: WebAuthnManager, adminUsername: String) {
        self.webAuthnManager = webAuthnManager
        self.configuredAdminUsername = adminUsername
    }
    
    // MARK: - Admin Authentication
    
    public func authenticateAdmin(username: String, requestData: [String: Any], clientIP: String?) throws -> String? {
        // CRITICAL: Only allow the configured admin username
        guard username == configuredAdminUsername else {
            print("[WebAuthAdminManager] ❌ Username \(username) does not match configured admin \(configuredAdminUsername)")
            throw WebAuthnError.accessDenied
        }
        
        print("[WebAuthAdminManager] 🔑 Admin authentication attempt for username: \(username)")
        
        // Use WebAuthn manager to verify authentication
        let authenticatedUsername = try webAuthnManager.verifyAuthentication(
            username: username,
            credential: requestData,
            clientIP: clientIP
        )
        
        let finalUsername = authenticatedUsername ?? username
        
        // Double-check the authenticated username still matches the configured admin
        guard finalUsername == configuredAdminUsername else {
            print("[WebAuthAdminManager] ❌ Authenticated username \(finalUsername) does not match configured admin \(configuredAdminUsername)")
            throw WebAuthnError.verificationFailed
        }
        
        return finalUsername
    }
    
    public func verifyAdminAccess(username: String) -> Bool {
        // Verify user exists and has admin privileges
        let allUsers = webAuthnManager.getAllUsers()
        guard let userCredential = allUsers.first(where: { $0.username == username }),
              userCredential.isEnabled && userCredential.isAdmin else {
            print("[WebAuthAdminManager] ❌ User \(username) is not an admin or is disabled")
            return false
        }
        
        return true
    }
    
    public func shouldAllowAdminAccess(username: String) -> Bool {
        // Check if user is enabled using WebAuthn manager
        guard webAuthnManager.isUserEnabled(username: username) else {
            print("[WebAuthAdminManager] 🔒 User \(username) not found or disabled in WebAuthn system")
            return false
        }
        
        // Verify admin privileges
        return verifyAdminAccess(username: username)
    }
    
    // MARK: - Admin User Management
    
    public func getAllUsers() -> [[String: Any]] {
        let allChatUsers = webAuthnManager.getAllUsers()
        
        // Convert to JSON-serializable format
        let usersData = allChatUsers.map { credential in
            let formatter = ISO8601DateFormatter()
            
            return [
                "id": credential.id as Any,
                "username": credential.username as Any,
                "credentialId": credential.id as Any,
                "publicKey": credential.publicKey as Any,
                "signCount": credential.signCount as Any,
                "createdAt": formatter.string(from: credential.createdAt ?? Date()) as Any,
                "lastLoginAt": credential.lastLoginAt != nil ? formatter.string(from: credential.lastLoginAt!) : NSNull(),
                "lastLoginIP": credential.lastLoginIP ?? NSNull(),
                "isEnabled": credential.isEnabled as Any,
                "isAdmin": credential.isAdmin as Any,
                "userNumber": credential.userNumber ?? 0 as Any,
                "emoji": credential.emoji ?? "👤" as Any
            ] as [String: Any]
        }
        
        return usersData
    }
    
    public func toggleUserStatus(credentialId: String, enabled: Bool) -> Bool {
        // Find user by credential ID
        let allUsers = webAuthnManager.getAllUsers()
        guard let userCredential = allUsers.first(where: { $0.id == credentialId }) else {
            print("[WebAuthAdminManager] ❌ User with credential ID \(credentialId) not found")
            return false
        }
        
        // Update user enabled status using WebAuthn manager
        let success = webAuthnManager.updateUserEnabledStatus(username: userCredential.username, isEnabled: enabled)
        
        if success {
            print("[WebAuthAdminManager] ✅ Updated user \(userCredential.username) enabled status to \(enabled)")
        } else {
            print("[WebAuthAdminManager] ❌ Failed to update user \(userCredential.username) enabled status")
        }
        
        return success
    }
    
    public func deleteUser(credentialId: String) -> Bool {
        // Find user by credential ID
        let allUsers = webAuthnManager.getAllUsers()
        guard let userCredential = allUsers.first(where: { $0.id == credentialId }) else {
            print("[WebAuthAdminManager] ❌ User with credential ID \(credentialId) not found")
            return false
        }
        
        // Delete user credentials
        webAuthnManager.deleteUserCredentials(username: userCredential.username)
        print("[WebAuthAdminManager] ✅ Deleted user: \(userCredential.username)")
        return true
    }
    
    public func disableUsersByIP(ipAddress: String) -> Int {
        let allUsers = webAuthnManager.getAllUsers()
        var disabledCount = 0
        
        for user in allUsers {
            if user.lastLoginIP == ipAddress {
                // Update user to disabled status
                let success = webAuthnManager.updateUserEnabledStatus(username: user.username, isEnabled: false)
                if success {
                    disabledCount += 1
                    print("[WebAuthAdminManager] ✅ Disabled user '\(user.username)' with IP \(ipAddress)")
                }
            }
        }
        
        return disabledCount
    }
    
    public func updateUserEmoji(credentialId: String, emoji: String) -> Bool {
        // Find user by credential ID
        let allUsers = webAuthnManager.getAllUsers()
        guard let userCredential = allUsers.first(where: { $0.id == credentialId }) else {
            print("[WebAuthAdminManager] ❌ User with credential ID \(credentialId) not found")
            return false
        }
        
        // Update emoji using WebAuthn manager
        let success = webAuthnManager.updateUserEmoji(username: userCredential.username, emoji: emoji)
        
        if success {
            print("[WebAuthAdminManager] ✅ Updated emoji for user \(userCredential.username) to \(emoji)")
        } else {
            print("[WebAuthAdminManager] ❌ Failed to update emoji for user \(userCredential.username)")
        }
        
        return success
    }
    
    public func toggleUserAdminStatus(credentialId: String, isAdmin: Bool) -> Bool {
        // Find user by credential ID
        let allUsers = webAuthnManager.getAllUsers()
        guard let userCredential = allUsers.first(where: { $0.id == credentialId }) else {
            print("[WebAuthAdminManager] ❌ User with credential ID \(credentialId) not found")
            return false
        }
        
        // Update admin status using WebAuthn manager
        let success = webAuthnManager.updateUserAdminStatus(username: userCredential.username, isAdmin: isAdmin)
        
        if success {
            print("[WebAuthAdminManager] ✅ Updated admin status for user \(userCredential.username) to \(isAdmin)")
        } else {
            print("[WebAuthAdminManager] ❌ Failed to update admin status for user \(userCredential.username)")
        }
        
        return success
    }
    
    // MARK: - Admin Bootstrap
    
    public func bootstrapAdminUser() {
        print("[WebAuthAdminManager] 🔑 Checking admin bootstrap for username: '\(configuredAdminUsername)'")
        
        // Check if the configured admin username exists in WebAuthn credentials
        let allUsers = webAuthnManager.getAllUsers()
        
        if let adminCredential = allUsers.first(where: { $0.username == configuredAdminUsername }) {
            if adminCredential.isAdmin {
                print("[WebAuthAdminManager] ✅ Admin user '\(configuredAdminUsername)' already has admin privileges")
            } else {
                print("[WebAuthAdminManager] 🔧 Promoting '\(configuredAdminUsername)' to admin...")
                let success = webAuthnManager.updateUserAdminStatus(username: configuredAdminUsername, isAdmin: true)
                if success {
                    print("[WebAuthAdminManager] ✅ Successfully promoted '\(configuredAdminUsername)' to admin")
                } else {
                    print("[WebAuthAdminManager] ❌ Failed to promote '\(configuredAdminUsername)' to admin")
                }
            }
        } else {
            print("[WebAuthAdminManager] ⚠️ Admin user '\(configuredAdminUsername)' not found in credentials")
            print("[WebAuthAdminManager] 💡 User must register with WebAuthn first, then will be automatically promoted to admin")
        }
    }
} 