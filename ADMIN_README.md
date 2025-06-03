# Admin Panel Documentation

## Overview

The XCF Chat admin panel provides comprehensive user management capabilities for administrators. The admin system tracks all users with passkey authentication and provides tools to monitor, enable/disable, and manage users.

## Features

### 🛡️ User Management
- **User Tracking**: Tracks passkey credentials, sign counts, public keys, user IDs, usernames, and user numbers
- **Enable/Disable Users**: Toggle user access with a simple switch
- **IP Address Tracking**: Monitor user login IPs and bulk disable users by IP
- **User Details**: View comprehensive user information including credentials and login history

### 📊 Statistics Dashboard
- Total users count
- Active (enabled) users count  
- Disabled users count
- Online users (future enhancement)

### 🔍 Advanced Controls
- **Bulk Actions**: Disable all users from a specific IP address
- **Search & Filter**: Search by username or filter by enabled/disabled status
- **User Details Modal**: View complete user information including public keys

## Access Control

### Admin Access Rules
1. **First Time Setup**: If no admin users exist, access is granted for initial setup
2. **Enabled Admins Required**: At least one enabled admin user must exist for access
3. **Authentication**: Uses the same WebAuthn passkey system as the main chat
4. **URL Access**: Admin panel is accessed via `/admin/index.html`

### Security Features
- **404 Error**: Non-admin users receive a 404 error when accessing admin routes
- **Disabled User Protection**: Disabled users cannot authenticate even with valid passkeys
- **IP Tracking**: All user logins are tracked by IP address for security monitoring
- **Real-time IP Extraction**: IP addresses are automatically captured from network connections

## IP Address Tracking

### How IP Tracking Works

The system automatically tracks IP addresses for all user activities:

1. **Registration**: When users first register with WebAuthn, their IP is captured and stored
2. **Authentication**: Every successful login updates the user's `lastLoginIP` and `lastLoginAt` fields
3. **Connection Source**: IP addresses are extracted from the network connection endpoint
4. **Proxy Support**: Falls back to `X-Forwarded-For` and `X-Real-IP` headers for proxy scenarios

### IP Extraction Process

```swift
// Primary: Extract from network connection
if let endpoint = connection.currentPath?.remoteEndpoint {
    switch endpoint {
    case .hostPort(let host, _):
        return String(describing: host)  // Real client IP
    }
}

// Fallback: Check proxy headers
// X-Forwarded-For: 203.0.113.195, 203.0.113.196
// X-Real-IP: 203.0.113.195
```

### IP Data Storage

IP addresses are stored in the `AdminUser` model:

```swift
public struct AdminUser {
    public let lastLoginIP: String?        // Most recent login IP
    public let lastLoginAt: Date?          // Timestamp of last login
    // ... other fields
}
```

### Admin Panel IP Features

- **IP Display**: Each user's last login IP is shown in the admin table
- **IP Search**: Search users by IP address in the search box
- **Bulk IP Actions**: Disable all users from a specific IP address
- **IP Monitoring**: Track patterns and identify suspicious activity

## Usage

### Accessing the Admin Panel

1. Navigate to `/admin/index.html` on your chat server
2. Authenticate using your WebAuthn passkey (same as chat login)
3. If you're the first user, you'll automatically have admin access

### Managing Users

#### View User Details
- Click the "View" button next to any user to see comprehensive details
- Details include: User ID, username, credentials, sign count, login history

#### Enable/Disable Users
- Use the toggle switch in each user row to enable/disable access
- Disabled users cannot log in even with valid passkeys

#### Delete Users
- Click the "Delete" button to permanently remove a user
- **Warning**: This action cannot be undone

#### Bulk IP Management
- Enter an IP address in the "Bulk Actions" section
- Click "Disable All Users with IP" to disable all users from that IP
- Useful for blocking compromised or malicious IP addresses

### Search and Filtering

#### Status Filter
- **All Users**: Show all users regardless of status
- **Enabled Only**: Show only enabled users
- **Disabled Only**: Show only disabled users

#### Username Search
- Type in the search box to filter users by username
- Search also works with user numbers and IP addresses

## Database Storage

### AdminUser Model
```swift
public struct AdminUser: Codable, Identifiable {
    public let id: UUID                    // Unique user identifier
    public let username: String            // Username from registration
    public let credentialId: String        // WebAuthn credential ID
    public let publicKey: String          // Base64-encoded public key
    public let signCount: UInt32          // Authentication counter
    public let createdAt: Date            // Account creation time
    public let lastLoginAt: Date?         // Last successful login
    public let lastLoginIP: String?       // Last login IP address
    public let isEnabled: Bool            // Whether user can access system
    public let userNumber: Int            // Sequential user number
}
```

### Persistence
- Stored in UserDefaults as JSON under key `"MultiPeerChat_AdminUsers"`
- Automatically saved when users are created, updated, or deleted
- Supports backup and restore through standard UserDefaults mechanisms

## API Endpoints

### GET `/admin/api/users`
Returns array of all admin users with their details.

### POST `/admin/api/users/{id}/toggle`
Body: `{"enabled": boolean}`
Toggles the enabled status of a specific user.

### DELETE `/admin/api/users/{id}`
Permanently deletes a user account.

### POST `/admin/api/users/disable-by-ip`
Body: `{"ipAddress": "string"}`
Disables all users with the specified IP address.

## Security Considerations

### Authentication Flow
1. User attempts to access admin panel
2. System checks for existing admin users
3. If none exist, grants access for setup
4. If admin users exist, validates authentication
5. Checks if authenticated user is enabled
6. Grants or denies access accordingly

### Disabled User Enforcement
- Disabled status is checked during WebAuthn authentication
- Authentication fails with `accessDenied` error for disabled users
- Admin panel access is denied for disabled users

### Production Recommendations
1. **Session Management**: Implement proper session tokens for admin access
2. **Role-Based Access**: Add role hierarchy (admin, moderator, user)
3. **Audit Logging**: Log all admin actions for security auditing
4. **Rate Limiting**: Implement rate limiting on admin endpoints
5. **HTTPS Only**: Always use HTTPS in production environments

## Testing

The admin functionality includes comprehensive test coverage:

```bash
swift test --filter AdminTests
```

Tests cover:
- Admin user creation and persistence
- Enable/disable functionality  
- Bulk IP-based disable operations
- WebAuthn integration with disabled users
- User number generation

## File Structure

```
Sources/MultiPeerChatCore/
├── Models.swift              # AdminUser model definition
├── PersistenceManager.swift  # Database operations
├── WebAdminContent.swift     # HTML/CSS/JS for admin panel
├── WebServer.swift           # Admin routes and API handlers
└── WebAuthnManager.swift     # Authentication with disabled checks

Tests/MultiPeerChatTests/
└── AdminTests.swift          # Comprehensive admin functionality tests
```

## Troubleshooting

### Common Issues

**Q: Getting 404 when accessing `/admin/index.html`**
A: Ensure you have authenticated with WebAuthn and admin users exist in the system.

**Q: Can't enable/disable users**
A: Check browser console for JavaScript errors and verify admin API endpoints are accessible.

**Q: User still can log in after being disabled**
A: Disabled status is enforced at authentication time. User may need to try logging in again.

**Q: Bulk IP disable not working**
A: Ensure the IP address exactly matches the stored `lastLoginIP` values.

### Debug Information
- Admin actions are logged to console with `[WebServer]` prefix
- WebAuthn authentication logs include disabled user checks
- All admin API calls return JSON responses with success/error status

## Future Enhancements

- Real-time user online status
- Enhanced role-based permissions
- Admin action audit logs
- User session management
- Advanced user analytics
- Export/import user data
- Email notifications for admin actions 