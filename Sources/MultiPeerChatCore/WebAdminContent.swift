import Foundation

// MARK: - WebAdminContent namespace
public enum WebAdminContent {
    
    // MARK: - Admin HTML Content
    public static func generateAdminIndexHTML() -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Admin Panel - User Management</title>
            <link rel="stylesheet" href="/admin/admin.css">
        </head>
        <body>
            <div class="admin-container">
                <header class="admin-header">
                    <h1>🛡️ Admin Panel - User Management</h1>
                    <div class="admin-actions">
                        <button id="refresh-btn" onclick="refreshUsers()">🔄 Refresh</button>
                        <button id="back-to-chat-btn" onclick="goBackToChat()">💬 Back to Chat</button>
                    </div>
                </header>

                <div class="stats-section">
                    <div class="stat-card">
                        <h3>Total Users</h3>
                        <span id="total-users">0</span>
                    </div>
                    <div class="stat-card">
                        <h3>Active Users</h3>
                        <span id="active-users">0</span>
                    </div>
                    <div class="stat-card">
                        <h3>Disabled Users</h3>
                        <span id="disabled-users">0</span>
                    </div>
                </div>

                <div class="controls-section">
                    <div class="bulk-actions">
                        <h3>Bulk Actions</h3>
                        <div class="bulk-controls">
                            <input type="text" id="ip-address-input" placeholder="Enter IP address">
                            <button onclick="disableByIP()">Disable All Users with IP</button>
                        </div>
                    </div>

                    <div class="filters">
                        <h3>Filters</h3>
                        <select id="status-filter" onchange="filterUsers()">
                            <option value="all">All Users</option>
                            <option value="enabled">Enabled Only</option>
                            <option value="disabled">Disabled Only</option>
                        </select>
                        <input type="text" id="search-input" placeholder="Search by username..." onkeyup="filterUsers()">
                    </div>
                </div>

                <div class="users-section">
                    <div class="users-header">
                        <h3>Users (<span id="user-count">0</span>)</h3>
                    </div>

                    <div class="users-table-container">
                        <table id="users-table">
                            <thead>
                                <tr>
                                    <th>User #</th>
                                    <th>Username</th>
                                    <th>Status</th>
                                    <th>Created</th>
                                    <th>Last Login</th>
                                    <th>IP Address</th>
                                    <th>Sign Count</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody id="users-tbody">
                                <!-- Users will be populated here -->
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- User Details Modal -->
                <div id="user-details-modal" class="modal hidden">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h3>User Details</h3>
                            <button class="close-btn" onclick="closeUserDetailsModal()">&times;</button>
                        </div>
                        <div class="modal-body">
                            <div class="user-detail-grid">
                                <div class="detail-item">
                                    <label>User ID:</label>
                                    <span id="detail-id"></span>
                                </div>
                                <div class="detail-item">
                                    <label>User Number:</label>
                                    <span id="detail-user-number"></span>
                                </div>
                                <div class="detail-item">
                                    <label>Username:</label>
                                    <span id="detail-username"></span>
                                </div>
                                <div class="detail-item">
                                    <label>Status:</label>
                                    <span id="detail-status"></span>
                                </div>
                                <div class="detail-item">
                                    <label>Created:</label>
                                    <span id="detail-created"></span>
                                </div>
                                <div class="detail-item">
                                    <label>Last Login:</label>
                                    <span id="detail-last-login"></span>
                                </div>
                                <div class="detail-item">
                                    <label>IP Address:</label>
                                    <span id="detail-ip"></span>
                                </div>
                                <div class="detail-item">
                                    <label>Sign Count:</label>
                                    <span id="detail-sign-count"></span>
                                </div>
                                <div class="detail-item">
                                    <label>Credential ID:</label>
                                    <span id="detail-credential-id" class="credential-text"></span>
                                </div>
                                <div class="detail-item full-width">
                                    <label>Public Key:</label>
                                    <textarea id="detail-public-key" class="public-key-text" readonly></textarea>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <script src="/admin/admin.js"></script>
        </body>
        </html>
        """
    }

    // MARK: - Admin CSS Content
    public static func generateAdminCSS() -> String {
        return """
        /* Admin Panel CSS */
        :root {
            --admin-primary: #2563eb;
            --admin-primary-hover: #1d4ed8;
            --admin-secondary: #64748b;
            --admin-success: #059669;
            --admin-success-hover: #047857;
            --admin-danger: #dc2626;
            --admin-danger-hover: #b91c1c;
            --admin-warning: #d97706;
            --admin-warning-hover: #b45309;
            --admin-bg: #f8fafc;
            --admin-card-bg: #ffffff;
            --admin-border: #e2e8f0;
            --admin-text: #1e293b;
            --admin-text-muted: #64748b;
            --admin-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
            --admin-shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
        }

        /* Dark mode */
        @media (prefers-color-scheme: dark) {
            :root {
                --admin-bg: #0f172a;
                --admin-card-bg: #1e293b;
                --admin-border: #334155;
                --admin-text: #f1f5f9;
                --admin-text-muted: #94a3b8;
                --admin-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.3), 0 1px 2px 0 rgba(0, 0, 0, 0.2);
                --admin-shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.3), 0 4px 6px -2px rgba(0, 0, 0, 0.2);
            }
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: var(--admin-bg);
            color: var(--admin-text);
            line-height: 1.6;
            min-height: 100vh;
        }

        .admin-container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 20px;
        }

        /* Header */
        .admin-header {
            background: var(--admin-card-bg);
            border-radius: 12px;
            padding: 24px;
            margin-bottom: 24px;
            box-shadow: var(--admin-shadow);
            display: flex;
            justify-content: space-between;
            align-items: center;
            border: 1px solid var(--admin-border);
        }

        .admin-header h1 {
            font-size: 28px;
            font-weight: 700;
            color: var(--admin-primary);
        }

        .admin-actions {
            display: flex;
            gap: 12px;
        }

        .admin-actions button {
            padding: 10px 20px;
            border: none;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s ease;
        }

        #refresh-btn {
            background: var(--admin-primary);
            color: white;
        }

        #refresh-btn:hover {
            background: var(--admin-primary-hover);
        }

        #back-to-chat-btn {
            background: var(--admin-secondary);
            color: white;
        }

        #back-to-chat-btn:hover {
            background: #475569;
        }

        /* Stats Section */
        .stats-section {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 24px;
        }

        .stat-card {
            background: var(--admin-card-bg);
            border-radius: 12px;
            padding: 24px;
            text-align: center;
            box-shadow: var(--admin-shadow);
            border: 1px solid var(--admin-border);
        }

        .stat-card h3 {
            font-size: 14px;
            font-weight: 500;
            color: var(--admin-text-muted);
            margin-bottom: 8px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .stat-card span {
            font-size: 32px;
            font-weight: 700;
            color: var(--admin-primary);
        }

        /* Controls Section */
        .controls-section {
            background: var(--admin-card-bg);
            border-radius: 12px;
            padding: 24px;
            margin-bottom: 24px;
            box-shadow: var(--admin-shadow);
            border: 1px solid var(--admin-border);
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 32px;
        }

        .bulk-actions h3,
        .filters h3 {
            font-size: 16px;
            font-weight: 600;
            margin-bottom: 16px;
            color: var(--admin-text);
        }

        .bulk-controls {
            display: flex;
            gap: 12px;
            align-items: center;
        }

        .bulk-controls input {
            flex: 1;
            padding: 10px 12px;
            border: 1px solid var(--admin-border);
            border-radius: 6px;
            background: var(--admin-bg);
            color: var(--admin-text);
            font-size: 14px;
        }

        .bulk-controls button {
            padding: 10px 16px;
            background: var(--admin-danger);
            color: white;
            border: none;
            border-radius: 6px;
            font-size: 14px;
            font-weight: 500;
            cursor: pointer;
            transition: background 0.2s ease;
            white-space: nowrap;
        }

        .bulk-controls button:hover {
            background: var(--admin-danger-hover);
        }

        .filters {
            display: flex;
            flex-direction: column;
            gap: 12px;
        }

        .filters select,
        .filters input {
            padding: 10px 12px;
            border: 1px solid var(--admin-border);
            border-radius: 6px;
            background: var(--admin-bg);
            color: var(--admin-text);
            font-size: 14px;
        }

        /* Users Section */
        .users-section {
            background: var(--admin-card-bg);
            border-radius: 12px;
            padding: 24px;
            box-shadow: var(--admin-shadow);
            border: 1px solid var(--admin-border);
        }

        .users-header {
            margin-bottom: 20px;
        }

        .users-header h3 {
            font-size: 18px;
            font-weight: 600;
            color: var(--admin-text);
        }

        /* Table */
        .users-table-container {
            overflow-x: auto;
            border-radius: 8px;
            border: 1px solid var(--admin-border);
        }

        #users-table {
            width: 100%;
            border-collapse: collapse;
            background: var(--admin-card-bg);
        }

        #users-table th {
            background: var(--admin-bg);
            padding: 12px;
            text-align: left;
            font-weight: 600;
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: var(--admin-text-muted);
            border-bottom: 1px solid var(--admin-border);
        }

        #users-table td {
            padding: 12px;
            border-bottom: 1px solid var(--admin-border);
            font-size: 14px;
        }

        #users-table tr:hover {
            background: var(--admin-bg);
        }

        /* Status badges */
        .status-badge {
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .status-enabled {
            background: #dcfce7;
            color: var(--admin-success);
        }

        .status-disabled {
            background: #fef2f2;
            color: var(--admin-danger);
        }

        @media (prefers-color-scheme: dark) {
            .status-enabled {
                background: #064e3b;
                color: #34d399;
            }

            .status-disabled {
                background: #7f1d1d;
                color: #f87171;
            }
        }

        /* Action buttons */
        .action-buttons {
            display: flex;
            gap: 8px;
        }

        .action-btn {
            padding: 6px 12px;
            border: none;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s ease;
        }

        .btn-view {
            background: var(--admin-primary);
            color: white;
        }

        .btn-view:hover {
            background: var(--admin-primary-hover);
        }

        .btn-toggle {
            background: var(--admin-warning);
            color: white;
        }

        .btn-toggle:hover {
            background: var(--admin-warning-hover);
        }

        .btn-delete {
            background: var(--admin-danger);
            color: white;
        }

        .btn-delete:hover {
            background: var(--admin-danger-hover);
        }

        /* Toggle switch */
        .toggle-switch {
            position: relative;
            display: inline-block;
            width: 50px;
            height: 24px;
        }

        .toggle-switch input {
            opacity: 0;
            width: 0;
            height: 0;
        }

        .slider {
            position: absolute;
            cursor: pointer;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-color: #ccc;
            transition: 0.4s;
            border-radius: 24px;
        }

        .slider:before {
            position: absolute;
            content: "";
            height: 18px;
            width: 18px;
            left: 3px;
            bottom: 3px;
            background-color: white;
            transition: 0.4s;
            border-radius: 50%;
        }

        input:checked + .slider {
            background-color: var(--admin-success);
        }

        input:checked + .slider:before {
            transform: translateX(26px);
        }

        /* Modal */
        .modal {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.5);
            display: flex;
            justify-content: center;
            align-items: center;
            z-index: 1000;
        }

        .modal.hidden {
            display: none;
        }

        .modal-content {
            background: var(--admin-card-bg);
            border-radius: 12px;
            width: 90%;
            max-width: 600px;
            max-height: 80vh;
            overflow-y: auto;
            box-shadow: var(--admin-shadow-lg);
            border: 1px solid var(--admin-border);
        }

        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 20px 24px;
            border-bottom: 1px solid var(--admin-border);
        }

        .modal-header h3 {
            font-size: 18px;
            font-weight: 600;
            color: var(--admin-text);
        }

        .close-btn {
            background: none;
            border: none;
            font-size: 24px;
            cursor: pointer;
            color: var(--admin-text-muted);
            width: 32px;
            height: 32px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 4px;
        }

        .close-btn:hover {
            background: var(--admin-border);
        }

        .modal-body {
            padding: 24px;
        }

        .user-detail-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
        }

        .detail-item {
            display: flex;
            flex-direction: column;
            gap: 4px;
        }

        .detail-item.full-width {
            grid-column: 1 / -1;
        }

        .detail-item label {
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: var(--admin-text-muted);
        }

        .detail-item span {
            font-size: 14px;
            color: var(--admin-text);
            word-break: break-all;
        }

        .credential-text {
            font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;
            font-size: 12px;
            background: var(--admin-bg);
            padding: 8px;
            border-radius: 4px;
            border: 1px solid var(--admin-border);
        }

        .public-key-text {
            font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;
            font-size: 11px;
            background: var(--admin-bg);
            border: 1px solid var(--admin-border);
            border-radius: 4px;
            padding: 12px;
            resize: vertical;
            min-height: 100px;
            color: var(--admin-text);
            width: 100%;
        }

        /* Responsive */
        @media (max-width: 768px) {
            .admin-container {
                padding: 12px;
            }

            .admin-header {
                flex-direction: column;
                gap: 16px;
                text-align: center;
            }

            .controls-section {
                grid-template-columns: 1fr;
            }

            .users-table-container {
                font-size: 12px;
            }

            #users-table th,
            #users-table td {
                padding: 8px 4px;
            }

            .action-buttons {
                flex-direction: column;
            }

            .user-detail-grid {
                grid-template-columns: 1fr;
            }
        }

        /* Loading state */
        .loading {
            text-align: center;
            padding: 40px;
            color: var(--admin-text-muted);
        }

        .loading::after {
            content: "Loading...";
            animation: dots 1.5s steps(5, end) infinite;
        }

        @keyframes dots {
            0%, 20% {
                color: rgba(0,0,0,0);
                text-shadow:
                    .25em 0 0 rgba(0,0,0,0),
                    .5em 0 0 rgba(0,0,0,0);
            }
            40% {
                color: var(--admin-text-muted);
                text-shadow:
                    .25em 0 0 rgba(0,0,0,0),
                    .5em 0 0 rgba(0,0,0,0);
            }
            60% {
                text-shadow:
                    .25em 0 0 var(--admin-text-muted),
                    .5em 0 0 rgba(0,0,0,0);
            }
            80%, 100% {
                text-shadow:
                    .25em 0 0 var(--admin-text-muted),
                    .5em 0 0 var(--admin-text-muted);
            }
        }
        
        /* Admin Login Page Styles */
        .login-container {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: var(--admin-bg);
            padding: 20px;
        }
        
        .login-card {
            background: var(--admin-card-bg);
            border-radius: 16px;
            padding: 40px;
            width: 100%;
            max-width: 400px;
            box-shadow: var(--admin-shadow-lg);
            border: 1px solid var(--admin-border);
        }
        
        .login-header {
            text-align: center;
            margin-bottom: 32px;
        }
        
        .login-header h1 {
            font-size: 32px;
            font-weight: 700;
            color: var(--admin-primary);
            margin-bottom: 8px;
        }
        
        .login-header p {
            color: var(--admin-text-muted);
            font-size: 14px;
        }
        
        .login-form {
            margin-bottom: 32px;
        }
        
        .form-group {
            margin-bottom: 24px;
        }
        
        .form-group label {
            display: block;
            font-size: 14px;
            font-weight: 600;
            color: var(--admin-text);
            margin-bottom: 8px;
        }
        
        .form-group input {
            width: 100%;
            padding: 12px 16px;
            border: 1px solid var(--admin-border);
            border-radius: 8px;
            background: var(--admin-bg);
            color: var(--admin-text);
            font-size: 16px;
            transition: border-color 0.2s ease, box-shadow 0.2s ease;
        }
        
        .form-group input:focus {
            outline: none;
            border-color: var(--admin-primary);
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
        }
        
        .auth-button {
            width: 100%;
            padding: 16px;
            background: var(--admin-primary);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.2s ease, transform 0.1s ease;
        }
        
        .auth-button:hover {
            background: var(--admin-primary-hover);
            transform: translateY(-1px);
        }
        
        .auth-button:active {
            transform: translateY(0);
        }
        
        .auth-button:disabled {
            background: var(--admin-text-muted);
            cursor: not-allowed;
            transform: none;
        }
        
        .status-message {
            margin-top: 16px;
            padding: 12px;
            border-radius: 8px;
            font-size: 14px;
            text-align: center;
            display: none;
        }
        
        .status-message.success {
            background: rgba(5, 150, 105, 0.1);
            color: var(--admin-success);
            border: 1px solid rgba(5, 150, 105, 0.2);
            display: block;
        }
        
        .status-message.error {
            background: rgba(220, 38, 38, 0.1);
            color: var(--admin-danger);
            border: 1px solid rgba(220, 38, 38, 0.2);
            display: block;
        }
        
        .status-message.info {
            background: rgba(37, 99, 235, 0.1);
            color: var(--admin-primary);
            border: 1px solid rgba(37, 99, 235, 0.2);
            display: block;
        }
        
        .login-footer {
            text-align: center;
        }
        
        .back-link {
            color: var(--admin-text-muted);
            text-decoration: none;
            font-size: 14px;
            transition: color 0.2s ease;
        }
        
        .back-link:hover {
            color: var(--admin-primary);
        }
        """
    }

    // MARK: - Admin JavaScript Content
    public static func generateAdminJS() -> String {
        return """
        // Admin Panel JavaScript
        class AdminPanel {
            constructor() {
                this.users = [];
                this.filteredUsers = [];
                this.currentUser = null;
                this.init();
            }

            async init() {
                await this.loadUsers();
                this.updateStats();
                this.renderUsersTable();
            }

            async loadUsers() {
                try {
                    const response = await fetch('/admin/api/users');
                    if (!response.ok) {
                        if (response.status === 404 || response.status === 403) {
                            window.location.href = '/';
                            return;
                        }
                        throw new Error('Failed to load users');
                    }
                    
                    this.users = await response.json();
                    this.filteredUsers = [...this.users];
                } catch (error) {
                    console.error('Error loading users:', error);
                    this.showError('Failed to load users');
                }
            }

            updateStats() {
                const totalUsers = this.users.length;
                const activeUsers = this.users.filter(u => u.isEnabled).length;
                const disabledUsers = this.users.filter(u => !u.isEnabled).length;
                
                document.getElementById('total-users').textContent = totalUsers;
                document.getElementById('active-users').textContent = activeUsers;
                document.getElementById('disabled-users').textContent = disabledUsers;
            }

            renderUsersTable() {
                const tbody = document.getElementById('users-tbody');
                const userCount = document.getElementById('user-count');
                
                if (this.filteredUsers.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="8" class="loading">No users found</td></tr>';
                    userCount.textContent = '0';
                    return;
                }

                tbody.innerHTML = this.filteredUsers.map(user => `
                    <tr>
                        <td>#${user.userNumber}</td>
                        <td>${this.escapeHtml(user.username)}</td>
                        <td>
                            <span class="status-badge status-${user.isEnabled ? 'enabled' : 'disabled'}">
                                ${user.isEnabled ? 'Enabled' : 'Disabled'}
                            </span>
                        </td>
                        <td>${this.formatDate(user.createdAt)}</td>
                        <td>${user.lastLoginAt ? this.formatDate(user.lastLoginAt) : 'Never'}</td>
                        <td>${user.lastLoginIP || 'Unknown'}</td>
                        <td>${user.signCount}</td>
                        <td>
                            <div class="action-buttons">
                                <button class="action-btn btn-view" onclick="adminPanel.viewUser('${user.id}')">
                                    View
                                </button>
                                <label class="toggle-switch">
                                    <input type="checkbox" ${user.isEnabled ? 'checked' : ''} 
                                           onchange="adminPanel.toggleUser('${user.id}', this.checked)">
                                    <span class="slider"></span>
                                </label>
                                <button class="action-btn btn-delete" onclick="adminPanel.deleteUser('${user.id}')">
                                    Delete
                                </button>
                            </div>
                        </td>
                    </tr>
                `).join('');

                userCount.textContent = this.filteredUsers.length;
            }

            async toggleUser(userId, enabled) {
                try {
                    const response = await fetch('/admin/api/users/' + userId + '/toggle', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({ enabled })
                    });

                    if (!response.ok) {
                        throw new Error('Failed to toggle user status');
                    }

                    // Update local data
                    const user = this.users.find(u => u.id === userId);
                    if (user) {
                        user.isEnabled = enabled;
                    }

                    this.updateStats();
                    this.filterUsers(); // Re-render with current filters
                    this.showSuccess(`User ${enabled ? 'enabled' : 'disabled'} successfully`);
                } catch (error) {
                    console.error('Error toggling user:', error);
                    this.showError('Failed to toggle user status');
                    // Reload to reset the UI
                    this.loadUsers().then(() => this.renderUsersTable());
                }
            }

            async deleteUser(userId) {
                const user = this.users.find(u => u.id === userId);
                if (!user) return;

                if (!confirm(`Are you sure you want to delete user "${user.username}"? This action cannot be undone.`)) {
                    return;
                }

                try {
                    const response = await fetch('/admin/api/users/' + userId, {
                        method: 'DELETE'
                    });

                    if (!response.ok) {
                        throw new Error('Failed to delete user');
                    }

                    this.users = this.users.filter(u => u.id !== userId);
                    this.filteredUsers = this.filteredUsers.filter(u => u.id !== userId);
                    this.updateStats();
                    this.renderUsersTable();
                    this.showSuccess('User deleted successfully');
                } catch (error) {
                    console.error('Error deleting user:', error);
                    this.showError('Failed to delete user');
                }
            }

            // Helper functions
            escapeHtml(text) {
                const div = document.createElement('div');
                div.textContent = text;
                return div.innerHTML;
            }

            formatDate(dateString) {
                return new Date(dateString).toLocaleString();
            }

            showError(message) {
                console.error('Admin Error:', message);
                // You could add a toast notification here
            }

            showSuccess(message) {
                console.log('Admin Success:', message);
                // You could add a toast notification here
            }

            filterUsers() {
                const statusFilter = document.getElementById('status-filter').value;
                const searchTerm = document.getElementById('search-input').value.toLowerCase();

                this.filteredUsers = this.users.filter(user => {
                    const matchesStatus = statusFilter === 'all' || 
                                        (statusFilter === 'enabled' && user.isEnabled) ||
                                        (statusFilter === 'disabled' && !user.isEnabled);
                    
                    const matchesSearch = searchTerm === '' || 
                                        user.username.toLowerCase().includes(searchTerm);
                    
                    return matchesStatus && matchesSearch;
                });

                this.renderUsersTable();
            }

            viewUser(userId) {
                const user = this.users.find(u => u.id === userId);
                if (!user) return;
                
                // Populate modal fields
                document.getElementById('detail-id').textContent = user.id;
                document.getElementById('detail-user-number').textContent = user.userNumber;
                document.getElementById('detail-username').textContent = user.username;
                document.getElementById('detail-status').textContent = user.isEnabled ? 'Enabled' : 'Disabled';
                document.getElementById('detail-created').textContent = this.formatDate(user.createdAt);
                document.getElementById('detail-last-login').textContent = user.lastLoginAt ? this.formatDate(user.lastLoginAt) : 'Never';
                document.getElementById('detail-ip').textContent = user.lastLoginIP || 'Unknown';
                document.getElementById('detail-sign-count').textContent = user.signCount;
                document.getElementById('detail-credential-id').textContent = user.credentialId;
                document.getElementById('detail-public-key').textContent = user.publicKey;
                
                // Show modal
                document.getElementById('user-details-modal').classList.remove('hidden');
            }
        }

        // Global functions for button clicks
        function refreshUsers() {
            if (window.adminPanel) {
                window.adminPanel.loadUsers().then(() => {
                    window.adminPanel.updateStats();
                    window.adminPanel.renderUsersTable();
                });
            }
        }

        function goBackToChat() {
            window.location.href = '/';
        }

        function filterUsers() {
            if (window.adminPanel) {
                window.adminPanel.filterUsers();
            }
        }

        function closeUserDetailsModal() {
            document.getElementById('user-details-modal').classList.add('hidden');
        }

        function disableByIP() {
            const ipAddress = document.getElementById('ip-address-input').value.trim();
            if (!ipAddress) {
                alert('Please enter an IP address');
                return;
            }

            if (!confirm(`Are you sure you want to disable all users with IP address "${ipAddress}"?`)) {
                return;
            }

            fetch('/admin/api/users/disable-by-ip', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ ipAddress })
            })
            .then(response => {
                if (!response.ok) {
                    throw new Error('Failed to disable users');
                }
                return response.json();
            })
            .then(() => {
                alert('Users disabled successfully');
                refreshUsers();
                document.getElementById('ip-address-input').value = '';
            })
            .catch(error => {
                console.error('Error disabling users:', error);
                alert('Failed to disable users');
            });
        }

        // Initialize the admin panel when the page loads
        document.addEventListener('DOMContentLoaded', () => {
            console.log('Admin panel initializing...');
            window.adminPanel = new AdminPanel();
        });
        """
    }
    
    // MARK: - Admin Login JavaScript
    public static func generateAdminLoginJS() -> String {
        return """
        // Admin Login JavaScript
        
        function showStatus(message, type = 'info') {
            const statusEl = document.getElementById('status');
            statusEl.textContent = message;
            statusEl.className = `status-message ${type}`;
        }
        
        function setButtonState(disabled, text) {
            const btn = document.getElementById('authenticate-btn');
            btn.disabled = disabled;
            btn.textContent = text;
        }
        
        async function authenticateAdmin() {
            const username = document.getElementById('username').value.trim();
            
            if (!username) {
                showStatus('Please enter your username', 'error');
                return;
            }
            
            try {
                setButtonState(true, '🔄 Preparing authentication...');
                showStatus('Preparing WebAuthn authentication...', 'info');
                
                // Step 1: Get authentication options
                const optionsResponse = await fetch('/webauthn/authenticate/begin', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ username })
                });
                
                if (!optionsResponse.ok) {
                    throw new Error('Failed to get authentication options');
                }
                
                const options = await optionsResponse.json();
                
                setButtonState(true, '🔐 Authenticate with your passkey...');
                showStatus('Please use your passkey to authenticate', 'info');
                
                // Convert base64url to Uint8Array for WebAuthn
                function base64urlToUint8Array(base64url) {
                    const base64 = base64url.replace(/-/g, '+').replace(/_/g, '/');
                    const padded = base64.padEnd(base64.length + (4 - base64.length % 4) % 4, '=');
                    const binary = atob(padded);
                    return new Uint8Array(binary.split('').map(char => char.charCodeAt(0)));
                }
                
                // Prepare WebAuthn options
                const webauthnOptions = {
                    publicKey: {
                        challenge: base64urlToUint8Array(options.publicKey.challenge),
                        allowCredentials: options.publicKey.allowCredentials?.map(cred => ({
                            type: cred.type,
                            id: base64urlToUint8Array(cred.id)
                        })),
                        timeout: options.publicKey.timeout || 60000,
                        userVerification: options.publicKey.userVerification || 'preferred'
                    }
                };
                
                // Step 2: Get WebAuthn assertion
                const assertion = await navigator.credentials.get(webauthnOptions);
                
                if (!assertion) {
                    throw new Error('Authentication cancelled or failed');
                }
                
                setButtonState(true, '✅ Verifying authentication...');
                showStatus('Verifying your authentication...', 'info');
                
                // Convert Uint8Array to base64 for transmission (same as chat system)
                function arrayBufferToBase64(buffer) {
                    let binary = '';
                    const bytes = new Uint8Array(buffer);
                    for (let i = 0; i < bytes.byteLength; i++) {
                        binary += String.fromCharCode(bytes[i]);
                    }
                    return btoa(binary);
                }
                
                // Convert Uint8Array to base64url for rawId
                function uint8ArrayToBase64url(uint8Array) {
                    const base64 = btoa(String.fromCharCode(...uint8Array));
                    return base64.replace(/\\+/g, '-').replace(/\\//g, '_').replace(/=/g, '');
                }
                
                // Prepare response data (using same format as chat system)
                const authData = {
                    username: username,
                    id: assertion.id,
                    rawId: uint8ArrayToBase64url(new Uint8Array(assertion.rawId)),
                    response: {
                        clientDataJSON: arrayBufferToBase64(assertion.response.clientDataJSON),
                        authenticatorData: arrayBufferToBase64(assertion.response.authenticatorData),
                        signature: arrayBufferToBase64(assertion.response.signature)
                    },
                    type: assertion.type
                };
                
                // Step 3: Verify authentication with admin login endpoint
                const verifyResponse = await fetch('/admin/api/login', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(authData)
                });
                
                if (!verifyResponse.ok) {
                    const errorData = await verifyResponse.json().catch(() => ({}));
                    throw new Error(errorData.error || 'Authentication failed');
                }
                
                const result = await verifyResponse.json();
                
                if (result.success) {
                    showStatus('✅ Authentication successful! Redirecting...', 'success');
                    
                    // Store session info and redirect
                    if (result.sessionId) {
                        sessionStorage.setItem('adminSessionId', result.sessionId);
                    }
                    
                    setTimeout(() => {
                        window.location.href = '/admin/panel.html';
                    }, 1000);
                } else {
                    throw new Error(result.error || 'Authentication failed');
                }
                
            } catch (error) {
                console.error('Admin authentication error:', error);
                showStatus(`Authentication failed: ${error.message}`, 'error');
                setButtonState(false, '🔐 Authenticate with Passkey');
            }
        }
        
        // Allow Enter key to trigger authentication
        document.addEventListener('DOMContentLoaded', () => {
            document.getElementById('username').addEventListener('keypress', (e) => {
                if (e.key === 'Enter') {
                    authenticateAdmin();
                }
            });
        });
        """
    }

    // MARK: - Admin Login Page
    public static func generateAdminLoginHTML() -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Admin Login - XCF Chat</title>
            <link rel="stylesheet" href="/admin/admin.css">
        </head>
        <body>
            <div class="login-container">
                <div class="login-card">
                    <div class="login-header">
                        <h1>🛡️ Admin Access</h1>
                        <p>Authenticate with your passkey to access the admin panel</p>
                    </div>
                    
                    <div class="login-form">
                        <div class="form-group">
                            <label for="username">Username:</label>
                            <input type="text" id="username" placeholder="Enter your admin username" required>
                        </div>
                        
                        <button id="authenticate-btn" onclick="authenticateAdmin()" class="auth-button">
                            🔐 Authenticate with Passkey
                        </button>
                        
                        <div id="status" class="status-message"></div>
                    </div>
                    
                    <div class="login-footer">
                        <a href="/" class="back-link">← Back to Chat</a>
                    </div>
                </div>
            </div>
            
            <script src="/admin/admin-login.js"></script>
        </body>
        </html>
        """
    }
}