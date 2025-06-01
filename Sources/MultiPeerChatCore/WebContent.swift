import Foundation

// MARK: - HTML Content
func generateIndexHTML() -> String {
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title><span id="rp-id"></span></title>
        <link rel="stylesheet" href="/style.css">
    </head>
    <body>
        <div class="container">
            <header class="header">
                <h1>💬 <span id="rp-id"></span></h1>
                <div class="status">
                    <span id="connection-status" class="status-disconnected">Disconnected</span>
                    <span id="user-count">0 users online</span>
                </div>
            </header>

            <div class="main-content">
                <!-- Login Screen -->
                <div id="login-screen" class="screen">
                    <div class="login-form">
                        <h2>Join the Chat</h2>
                        <div class="emoji-picker">
                            <span id="selected-emoji" class="selected-emoji">👤</span>
                            <div class="emoji-scroll-container">
                                <div class="emoji-grid">
                                    <span class="emoji-option">👤</span>
                                    <span class="emoji-option">🐶</span>
                                    <span class="emoji-option">🐱</span>
                                    <span class="emoji-option">🐭</span>
                                    <span class="emoji-option">🐹</span>
                                    <span class="emoji-option">🐰</span>
                                    <span class="emoji-option">🦊</span>
                                    <span class="emoji-option">🐻</span>
                                    <span class="emoji-option">🐼</span>
                                    <span class="emoji-option">🐨</span>
                                    <span class="emoji-option">🐯</span>
                                    <span class="emoji-option">🦁</span>
                                    <span class="emoji-option">🐸</span>
                                    <span class="emoji-option">🐵</span>
                                    <span class="emoji-option">🙈</span>
                                    <span class="emoji-option">🙉</span>
                                    <span class="emoji-option">🙊</span>
                                    <span class="emoji-option">🐒</span>
                                    <span class="emoji-option">🦍</span>
                                    <span class="emoji-option">🦧</span>
                                    <span class="emoji-option">🐕</span>
                                    <span class="emoji-option">🐩</span>
                                    <span class="emoji-option">🐺</span>
                                    <span class="emoji-option">🦝</span>
                                    <span class="emoji-option">🐈</span>
                                    <span class="emoji-option">🐅</span>
                                    <span class="emoji-option">🐆</span>
                                    <span class="emoji-option">🦓</span>
                                    <span class="emoji-option">🦄</span>
                                    <span class="emoji-option">🐴</span>
                                    <span class="emoji-option">🐎</span>
                                    <span class="emoji-option">🦌</span>
                                    <span class="emoji-option">🐮</span>
                                    <span class="emoji-option">🐂</span>
                                    <span class="emoji-option">🐃</span>
                                    <span class="emoji-option">🐄</span>
                                    <span class="emoji-option">🐷</span>
                                    <span class="emoji-option">🐖</span>
                                    <span class="emoji-option">🐗</span>
                                    <span class="emoji-option">🐽</span>
                                    <span class="emoji-option">🐏</span>
                                    <span class="emoji-option">🐑</span>
                                    <span class="emoji-option">🐐</span>
                                    <span class="emoji-option">🐪</span>
                                    <span class="emoji-option">🐫</span>
                                    <span class="emoji-option">🦒</span>
                                    <span class="emoji-option">🐘</span>
                                    <span class="emoji-option">🦏</span>
                                    <span class="emoji-option">🦛</span>
                                    <span class="emoji-option">🐊</span>
                                    <span class="emoji-option">🐢</span>
                                    <span class="emoji-option">🦎</span>
                                    <span class="emoji-option">🐍</span>
                                    <span class="emoji-option">🐲</span>
                                    <span class="emoji-option">🐉</span>
                                    <span class="emoji-option">🦕</span>
                                    <span class="emoji-option">🦖</span>
                                    <span class="emoji-option">🐳</span>
                                    <span class="emoji-option">🐋</span>
                                    <span class="emoji-option">🐬</span>
                                    <span class="emoji-option">🦈</span>
                                    <span class="emoji-option">🐟</span>
                                    <span class="emoji-option">🐠</span>
                                    <span class="emoji-option">🐡</span>
                                    <span class="emoji-option">🦀</span>
                                    <span class="emoji-option">🦞</span>
                                    <span class="emoji-option">🦐</span>
                                    <span class="emoji-option">🐙</span>
                                    <span class="emoji-option">🦑</span>
                                    <span class="emoji-option">🐚</span>
                                    <span class="emoji-option">🦆</span>
                                    <span class="emoji-option">🐓</span>
                                    <span class="emoji-option">🐔</span>
                                    <span class="emoji-option">🐣</span>
                                    <span class="emoji-option">🐤</span>
                                    <span class="emoji-option">🐥</span>
                                    <span class="emoji-option">🦅</span>
                                    <span class="emoji-option">🦉</span>
                                    <span class="emoji-option">🦜</span>
                                    <span class="emoji-option">🕊️</span>
                                    <span class="emoji-option">🦢</span>
                                    <span class="emoji-option">🦩</span>
                                    <span class="emoji-option">🐧</span>
                                    <span class="emoji-option">🦇</span>
                                    <span class="emoji-option">🐝</span>
                                    <span class="emoji-option">🐛</span>
                                    <span class="emoji-option">🦋</span>
                                    <span class="emoji-option">🐌</span>
                                    <span class="emoji-option">🐞</span>
                                    <span class="emoji-option">🐜</span>
                                    <span class="emoji-option">🦗</span>
                                    <span class="emoji-option">🕷️</span>
                                    <span class="emoji-option">🦂</span>
                                </div>
                            </div>
                        </div>
                        <input type="text" id="username-input" placeholder="Enter your username" maxlength="20">
                        <div class="auth-options">
                            <button id="webauthn-register-btn" onclick="registerWebAuthn()">Register with Passkey</button>
                            <button id="webauthn-login-btn" onclick="loginWithWebAuthn()">Login with Passkey</button>
                        </div>
                    </div>
                </div>

                <!-- Chat Screen -->
                <div id="chat-screen" class="screen hidden">
                    <div class="sidebar">
                        <div class="sidebar-top">
                            <div class="user-info">
                                <div class="user-avatar">👤</div>
                                <span id="current-username"></span>
                            </div>
                            
                            <div class="rooms-section-header" onclick="toggleRoomsList()">
                                <span class="toggle-icon">▶</span>
                                <h3>Rooms</h3>
                                <button onclick="showCreateRoom()">+</button>
                            </div>
                        </div>
                        
                        <div class="rooms-section">
                            <div id="rooms-list-container" class="rooms-list-container">
                                <div id="rooms-list" class="rooms-list"></div>
                            </div>
                        </div>

                        <div class="invite-section">
                            <button id="invite-btn" onclick="createInvite()" disabled style="display:none;">📋 Create Invite</button>
                        </div>
                    </div>

                    <div class="chat-area">
                        <div class="chat-header">
                            <h3 id="current-room-name">Select a room</h3>
                            <div class="room-actions">
                                <div class="room-info-mobile">
                                    <button id="clear-history-btn" class="clear-history-btn" onclick="clearChatHistory()" disabled>Clear</button>
                                    <button id="remove-room-btn" class="remove-room-btn" onclick="removeRoom()">Remove</button>
                                    <button id="leave-room-btn" class="leave-room-btn" onclick="leaveRoom()" disabled>Leave</button>
                                    <button id="logout-btn" onclick="logout()">Logout</button>
                                </div>
                            </div>
                        </div>
                        
                        <div id="messages-container" class="messages-container">
                            <div class="welcome-message">
                                <h3>Welcome to <span id="rp-id"></span>! 🎉</h3>
                                <p>Create a room or join an existing one to start chatting.</p>
                            </div>
                        </div>
                        
                        <div class="message-input-container">
                            <div class="file-upload-area">
                                <input type="file" id="file-input" accept="image/*,.pdf,.doc,.docx,.txt,.zip" style="display: none;" multiple>
                                <button id="file-btn" class="circle-attachment-btn" onclick="selectFiles()" title="Attach files" disabled>📎</button>
                            </div>
                            <input type="text" id="message-input" placeholder="Type a message..." disabled>
                            <button id="send-btn" onclick="sendMessage()" disabled>Send</button>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Create Room Modal -->
        <div id="create-room-modal" class="modal hidden">
            <div class="modal-content">
                <h3>Create New Room</h3>
                <input type="text" id="room-name-input" placeholder="Room name" maxlength="30">
                <div class="modal-actions">
                    <button onclick="createRoom()">Create</button>
                    <button onclick="hideCreateRoom()">Cancel</button>
                </div>
            </div>
        </div>

        <!-- Invite Modal -->
        <div id="invite-modal" class="modal hidden">
            <div class="modal-content">
                <h3>Invite Link Created! 🔗</h3>
                <p>Share this link with others:</p>
                <div class="invite-link-container">
                    <input type="text" id="invite-link" readonly>
                    <button onclick="copyInviteLink()">Copy</button>
                </div>
                <div class="modal-actions">
                    <button onclick="hideInviteModal()">Close</button>
                </div>
            </div>
        </div>

        <!-- File Upload Modal -->
        <div id="file-upload-modal" class="modal hidden">
            <div class="modal-content">
                <h3>Upload Files 📎</h3>
                <div id="file-preview-container" class="file-preview-container">
                    <!-- File previews will be added here -->
                </div>
                <div class="file-upload-controls">
                    <input type="text" id="file-caption" placeholder="Add a caption (optional)" maxlength="200">
                    <div class="modal-actions">
                        <button id="upload-files-btn" onclick="uploadFiles()" disabled>Upload</button>
                        <button onclick="hideFileUploadModal()">Cancel</button>
                    </div>
                </div>
            </div>
        </div>

        <script src="/chat.js"></script>
        <script>
        // Hide upload button and file input for now
        window.addEventListener('DOMContentLoaded', function() {
            var fileBtn = document.getElementById('file-btn');
            var fileInput = document.getElementById('file-input');
            if (fileBtn) fileBtn.style.display = 'none';
            if (fileInput) fileInput.style.display = 'none';
        });

        // WebAuthn Implementation
        async function registerWebAuthn() {
            const username = document.getElementById('username-input').value;
            if (!username) {
                alert('Please enter a username first');
                return;
            }

            // Check username availability first
            try {
                const checkResponse = await fetch('/webauthn/username/check', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ username })
                });
                const checkResult = await checkResponse.json();
                if (!checkResult.available) {
                    alert(checkResult.error || 'Username is already registered.');
                    return;
                }
            } catch (err) {
                alert('Could not check username availability.');
                return;
            }

            try {
                // Get registration options from server
                const response = await fetch('/webauthn/register/begin', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ username })
                });
                
                if (!response.ok) throw new Error('Registration failed');
                
                const options = await response.json();
                
                if (!options.publicKey || !options.publicKey.challenge) {
                    alert('WebAuthn registration error: Invalid options from server.');
                    return;
                }
                
                // Convert base64 strings to ArrayBuffer
                options.publicKey.challenge = base64ToArrayBuffer(options.publicKey.challenge);
                options.publicKey.user.id = base64ToArrayBuffer(options.publicKey.user.id);
                
                // Create credentials
                const credential = await navigator.credentials.create(options);
                
                // Convert ArrayBuffer to base64
                const attestationObject = arrayBufferToBase64(credential.response.attestationObject);
                const clientDataJSON = arrayBufferToBase64(credential.response.clientDataJSON);
                
                // Send registration data to server
                const verificationResponse = await fetch('/webauthn/register/complete', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        id: arrayBufferToBase64(credential.rawId),
                        rawId: arrayBufferToBase64(credential.rawId),
                        response: {
                            attestationObject,
                            clientDataJSON
                        },
                        type: credential.type,
                        username
                    })
                });
                
                if (!verificationResponse.ok) throw new Error('Registration verification failed');
                
                alert('Registration successful! You can now login using your Passkey.');
            } catch (error) {
                console.error('WebAuthn registration error:', error);
                alert('Registration failed: ' + error.message);
            }
        }

        async function loginWithWebAuthn() {
            const usernameInput = document.getElementById('username-input');
            let username = usernameInput.value.trim();
            if (username === '') {
                username = null;
            }
            fetch('/webauthn/authenticate/begin', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username: username })
            })
            .then(response => response.json())
            .then(options => {
                if (!options.publicKey || !options.publicKey.challenge) {
                    alert('WebAuthn authentication error: Invalid options from server.');
                    throw new Error('Invalid WebAuthn options');
                }
                // Convert challenge to ArrayBuffer
                options.publicKey.challenge = base64ToArrayBuffer(options.publicKey.challenge);
                // Convert each allowCredentials id to ArrayBuffer
                if (options.publicKey.allowCredentials) {
                    options.publicKey.allowCredentials = options.publicKey.allowCredentials.map(cred => ({
                        ...cred,
                        id: base64ToArrayBuffer(cred.id)
                    }));
                }
                return navigator.credentials.get({ publicKey: options.publicKey });
            })
            .then(assertion => {
                const credential = {
                    id: assertion.id,
                    rawId: arrayBufferToBase64(assertion.rawId),
                    type: assertion.type,
                    response: {
                        clientDataJSON: arrayBufferToBase64(assertion.response.clientDataJSON),
                        authenticatorData: arrayBufferToBase64(assertion.response.authenticatorData),
                        signature: arrayBufferToBase64(assertion.response.signature),
                        userHandle: assertion.response.userHandle ? arrayBufferToBase64(assertion.response.userHandle) : null
                    },
                    username: username || ''
                };
                return fetch('/webauthn/authenticate/complete', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(credential)
                });
            })
            .then(response => response.json())
            .then(result => {
                if (result.success) {
                    if (!usernameInput.value && result.username) {
                        usernameInput.value = result.username;
                    }
                    // FIX: Actually join the chat after successful authentication!
                    joinChat();
                } else {
                    alert('Authentication failed: ' + (result.error || 'Unknown error'));
                }
            })
            .catch(err => {
                alert('WebAuthn authentication error: ' + err);
            });
        }

        // Utility functions for ArrayBuffer conversion
        function base64ToArrayBuffer(base64) {
            const binaryString = window.atob(base64);
            const bytes = new Uint8Array(binaryString.length);
            for (let i = 0; i < binaryString.length; i++) {
                bytes[i] = binaryString.charCodeAt(i);
            }
            return bytes.buffer;
        }

        function arrayBufferToBase64(buffer) {
            const bytes = new Uint8Array(buffer);
            let binary = '';
            for (let i = 0; i < bytes.byteLength; i++) {
                binary += String.fromCharCode(bytes[i]);
            }
            return window.btoa(binary);
        }

        // Replace all ${rpId} with <span id="rp-id"></span>
        // At the top of the <script> section, add:
        document.addEventListener('DOMContentLoaded', function() {
            document.querySelectorAll('#rp-id').forEach(function(el) {
                el.textContent = window.location.hostname;
            });
        });
        </script>
    </body>
    </html>
    """
}

// MARK: - CSS Content
func generateCSS() -> String {
    return """
    /* Updated: 2024-12-19 - Mobile Layout Fixed */
    #clear-history-btn { display: none !important; }
    body.admin #clear-history-btn { display: inline-block !important; }
    :root {
        /* Light Mode Colors */
        --bg-primary: #eceff1;
        --bg-secondary: #ffffff;
        --text-primary: #2d3748;
        --text-secondary: #4a5568;
        --accent-color: #007AFF;
        --accent-color-hover: #0056CC;
        --border-color: #e2e8f0;
        --status-connected: #34C759;
        --status-disconnected: #FF3B30;
        --system-message-bg: #fed7d7;
        --system-message-text: #c53030;
        --modal-bg: rgba(255, 255, 255, 0.95);
        --gradient-start: #667eea;
        --gradient-end: #764ba2;
        --input-bg: #ffffff;
        --input-text: #2d3748;
        --disabled-bg: #8E8E93;
        --orange-color: #FF9500;
        --orange-color-hover: #E6850E;
        --red-color: #FF3B30;
        --red-color-hover: #D70015;
        --green-color: #34C759;
        --green-color-hover: #248A3D;
        --dark-green-color: #1A5F1A;
        --dark-green-color-hover: #0F3D0F;
        --dark-red-color: #8B0000;
        --dark-red-color-hover: #5C0000;
        --room-hover-bg: rgba(244, 247, 246, 0.8);
        --time-other: #b0b6be;
        --own-bg: var(--accent-color);
        --own-text: #fff;
        --other-bg: var(--bg-secondary);
        --other-text: #111;
        --other-username: #111;
        --remove-room-color: #FF5E3A; /* Between orange and red */
        --remove-room-color-hover: #E04A1F;
    }

    /* Dark Mode Colors */
    @media (prefers-color-scheme: dark) {
        :root {
            --bg-primary: #121212;
            --bg-secondary: #1e1e1e;
            --text-primary: #e2e8f0;
            --text-secondary: #cbd5e0;
            --accent-color: #007AFF;
            --accent-color-hover: #0056CC;
            --border-color: #2d3748;
            --status-connected: #30D158;
            --status-disconnected: #FF453A;
            --system-message-bg: #2c1b1b;
            --system-message-text: #feb2b2;
            --modal-bg: rgba(30, 30, 30, 0.95);
            --gradient-start: #4a5568;
            --gradient-end: #2d3748;
            --input-bg: #2d3748;
            --input-text: #e2e8f0;
            --disabled-bg: #636366;
            --orange-color: #FF9F0A;
            --orange-color-hover: #E6850E;
            --red-color: #FF453A;
            --red-color-hover: #D70015;
            --green-color: #30D158;
            --green-color-hover: #248A3D;
            --room-hover-bg: rgba(18, 18, 18, 0.8);
            --time-other: #d1d5db;
            --own-bg: #0a84ff;
            --own-text: #fff;
            --other-bg: #000;
            --other-text: #e2e8f0;
            --other-username: #e2e8f0;
        }
        .message.other {
            background: #000 !important;
            color: #e2e8f0;
        }
        .message.own {
            background: #0a84ff !important; /* macOS system blue */
            color: #fff;
        }
    }

    * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
        transition: background-color 0.3s ease, color 0.3s ease;
    }

    body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        background: linear-gradient(135deg, var(--gradient-start) 0%, var(--gradient-end) 100%), var(--bg-primary);
        min-height: 100vh;
        color: var(--text-primary);
        line-height: 1.6;
    }

    .container {
        max-width: 100%;
        margin: 0 auto;
        height: 100vh;
        display: flex;
        flex-direction: column;
    }

    .header {
        background: var(--modal-bg);
        backdrop-filter: blur(10px);
        padding: 1rem 2rem;
        display: flex;
        justify-content: space-between;
        align-items: center;
        box-shadow: 0 2px 20px rgba(0, 0, 0, 0.1);
        color: var(--text-primary);
    }

    .header h1 {
        color: var(--text-secondary);
        font-size: 1.5rem;
        font-weight: 600;
    }

    .status {
        display: flex;
        gap: 1rem;
        align-items: center;
    }

    .status-connected {
        color: var(--status-connected);
        font-weight: 500;
    }

    .status-disconnected {
        color: var(--status-disconnected);
        font-weight: 500;
    }

    .main-content {
        flex: 1;
        position: relative;
        overflow: hidden;
    }

    .screen {
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        transition: opacity 0.3s ease;
    }

    .hidden {
        opacity: 0;
        pointer-events: none;
    }

    /* Login Screen */
    .login-form {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        height: 100%;
        gap: 1.5rem;
    }

    .login-form h2 {
        color: white;
        font-size: 2rem;
        margin-bottom: 1rem;
    }

    .login-form input {
        padding: 1rem 1.5rem;
        font-size: 1.1rem;
        border: 2px solid var(--border-color);
        border-radius: 50px;
        width: 300px;
        text-align: center;
        box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
        background-color: var(--input-bg);
        color: var(--input-text);
        outline: none;
        transition: border-color 0.3s ease, box-shadow 0.3s ease;
        box-sizing: border-box;
    }

    .login-form input:focus {
        border: 2px solid var(--accent-color);
        box-shadow: 0 0 0 3px rgba(0, 122, 255, 0.1);
        outline: none;
    }

    .login-form button {
        padding: 1rem 2rem;
        font-size: 1.1rem;
        background: var(--accent-color);
        color: white;
        border: none;
        border-radius: 50px;
        cursor: pointer;
        transition: background 0.3s ease;
        box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
    }

    .login-form button:hover {
        background: var(--accent-color-hover);
    }

    /* Chat Screen */
    #chat-screen {
        display: flex;
        background: var(--modal-bg);
        backdrop-filter: blur(10px);
        margin: 0;
        border-radius: 0;
        overflow: hidden;
        box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
        color: var(--text-primary);
        flex: 1;
    }

    .sidebar {
        width: 300px;
        background: var(--bg-secondary);
        border-right: 1px solid var(--border-color);
        display: flex;
        flex-direction: column;
        padding: 1.5rem;
    }

    .user-info {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        padding: 1rem;
        background: var(--bg-primary);
        border-radius: 12px;
        margin-bottom: 1.5rem;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
        color: var(--text-primary);
        border: 1px solid var(--border-color);
        height: 60px;
        box-sizing: border-box;
    }

    .user-avatar {
        font-size: 1.5rem;
    }

    .rooms-section {
        position: relative;
    }

    .rooms-section-header {
        display: flex;
        align-items: center;
        cursor: pointer;
        padding: 1rem;
        background: var(--bg-primary) !important;
        border-radius: 12px;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
        border: 1px solid var(--border-color);
        margin-bottom: 0;
        gap: 0.75rem;
        height: 60px;
        box-sizing: border-box;
    }

    .rooms-section-header .toggle-icon {
        transition: transform 0.3s ease;
        font-size: 1rem;
        display: flex;
        align-items: center;
        justify-content: center;
        width: 20px;
        height: 20px;
    }

    .rooms-section-header .toggle-icon.rotated {
        transform: rotate(90deg);
    }

    .rooms-section-header h3 {
        margin-left: 5px;
        color: var(--text-secondary);
        font-size: 1.1rem;
    }

    .rooms-section-header button {
        width: 30px;
        height: 30px;
        border-radius: 50%;
        border: none;
        background: var(--accent-color);
        color: white;
        cursor: pointer;
        font-size: 1.2rem;
        display: flex;
        align-items: center;
        justify-content: center;
        margin-left: auto;
    }

    .rooms-section-header button:hover {
        background: var(--accent-color-hover);
    }

    /* Ensure create room button has proper styling on all screen sizes */
    button[onclick="showCreateRoom()"] {
        width: 30px;
        height: 30px;
        border-radius: 50%;
        border: none;
        background: var(--accent-color);
        color: white;
        cursor: pointer;
        font-size: 1.2rem;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    button[onclick="showCreateRoom()"]:hover {
        background: var(--accent-color-hover);
    }

    .rooms-section {
        grid-column: 1 / -1;
        margin-top: 0;
        margin-bottom: 0; /* Ensure no bottom margin */
    }

    .rooms-list-container {
        max-height: none;
        overflow: visible;
        padding-top: 0;
    }

    .rooms-list-container.collapsed {
        max-height: 0;
        overflow: hidden;
        opacity: 0;
    }

    .room-item {
        padding: 0.75rem 1rem;
        margin-bottom: 0.5rem;
        background: var(--bg-primary);
        border-radius: 8px;
        cursor: pointer;
        transition: all 0.2s ease;
        border: 1px solid transparent;
        color: var(--text-primary);
        position: relative;
        overflow: hidden;
        z-index: 1;
    }

    .room-item::before {
        content: '';
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: var(--accent-color);
        opacity: 0;
        transition: opacity 0.2s ease;
        z-index: -1;
    }

    .room-item:hover::before {
        opacity: 0.1;
    }

    .room-item:hover {
        background: var(--room-hover-bg);
        color: var(--text-primary);
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.15);
        transform: translateY(-2px);
        border-color: var(--accent-color);
    }

    .room-item.active {
        background: var(--accent-color);
        color: white;
    }

    .room-item.active:hover {
        background: var(--accent-color);
        color: white;
    }

    .chat-area {
        flex: 1;
        display: flex;
        flex-direction: column;
        overflow: hidden;
    }

    .chat-header {
        display: flex;
        flex-direction: row;
        justify-content: space-between;
        align-items: center;
        padding: 0.75rem; /* Reduced from 1rem */
    }

    .chat-header h3 {
        margin: 0;
        flex-grow: 1;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        font-size: 1rem;
    }

    .room-actions {
        display: flex;
        align-items: center;
        gap: 8px; /* Reduced from 12px */
    }

    .room-actions .room-info-mobile {
        display: flex;
        align-items: center;
        gap: 6px; /* Reduced from 10px */
    }

    .room-actions button {
        padding: 0.5rem 1rem;
        background: var(--accent-color);
        color: white;
        border: none;
        border-radius: 6px;
        cursor: pointer;
        font-size: 0.9rem;
    }

    .room-actions button:disabled {
        background: var(--disabled-bg);
        cursor: not-allowed;
    }

    .room-actions .leave-room-btn {
        background-color: var(--dark-red-color);
        color: white;
    }

    .room-actions .leave-room-btn:hover {
        background: var(--dark-red-color-hover);
    }

    .room-actions .clear-history-btn {
        background-color: var(--orange-color);
        color: white;
    }

    .room-actions .clear-history-btn:hover {
        background: var(--orange-color-hover);
    }

    .room-actions .remove-room-btn {
        background-color: var(--remove-room-color);
        color: white;
    }

    .room-actions .remove-room-btn:hover {
        background: var(--remove-room-color-hover);
    }

    #logout-btn {
        background-color: var(--accent-color);
        color: white;
        margin-left: 6px;
    }

    #logout-btn:hover {
        background-color: var(--accent-color-hover);
    }

    .invite-section {
        margin-top: 1rem;
    }

    .invite-section button {
        width: 100%;
        padding: 0.75rem;
        background: var(--dark-green-color);
        color: white;
        border: none;
        border-radius: 8px;
        cursor: pointer;
        font-size: 0.9rem;
        transition: background 0.3s ease;
    }

    .invite-section button:hover {
        background: var(--dark-green-color-hover);
    }

    .invite-section button:disabled {
        background: var(--disabled-bg);
        cursor: not-allowed;
    }

    .messages-container {
        flex: 1;
        overflow-y: auto;
        padding: 1rem 1.5rem;
        padding-bottom: 155px !important; /* Increased from 120px + 35px more space */
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
        -webkit-overflow-scrolling: touch;
        min-height: 0;
        /* Ensure messages don't get hidden behind input */
        margin-bottom: 35px !important; /* Added 35px bottom margin */
    }

    .welcome-message {
        text-align: center;
        color: var(--text-secondary);
        margin-top: 2rem;
    }

    /* Message Bubble Styles - grouped and clean */
    .message {
        max-width: 70%;
        padding: 0.75rem 1rem;
        border-radius: 12px;
        word-wrap: break-word;
        margin-bottom: 0.75rem;
    }
    .message.own {
        align-self: flex-end;
        background: var(--own-bg);
        color: var(--own-text);
    }
    .message.other {
        align-self: flex-start;
        background: var(--other-bg);
        color: var(--other-text);
    }
    .message.other .username {
        color: var(--other-username);
    }
    .message.system {
        align-self: center;
        background: var(--system-message-bg);
        color: var(--system-message-text);
        font-style: italic;
        font-size: 0.9rem;
    }
    .message-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 0.5rem;
        font-size: 1rem;
        background: none;
        box-shadow: none;
        border: none;
        padding: 0;
    }
    .user-emoji {
        font-size: 1.5rem;
        margin-right: 0.5rem;
        line-height: 1;
    }
    .username {
        font-weight: 600;
        margin-right: auto;
    }
    .time {
        color: var(--time-other);
        font-size: 0.9rem;
        margin-left: 1rem;
        white-space: nowrap;
    }
    .message-content {
        font-size: 1.2rem;
        word-break: break-word;
    }

    /* Message Input Styles */
    .message-input-container {
        padding: 1.5rem;
        border-top: 1px solid var(--border-color);
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .message-input-container input {
        flex: 1;
        padding: 0.75rem 1rem;
        border: 1px solid var(--border-color);
        border-radius: 25px;
        font-size: 1rem;
        background-color: var(--input-bg);
        color: var(--input-text);
    }

    .message-input-container input:disabled {
        background: #f7fafc;
        cursor: not-allowed;
    }

    .message-input-container button {
        padding: 0.75rem 1.5rem;
        background: var(--accent-color);
        color: white;
        border: none;
        border-radius: 25px;
        cursor: pointer;
        font-size: 1rem;
    }

    .message-input-container button:disabled {
        background: var(--disabled-bg);
        cursor: not-allowed;
    }

    /* File Upload Area */
    .file-upload-area {
        display: flex;
        align-items: center;
    }

    .circle-attachment-btn {
        width: 48px;
        height: 48px;
        aspect-ratio: 1/1;
        border-radius: 50%;
        background: var(--accent-color);
        color: white;
        border: none;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 2rem;
        font-family: "SF Pro", "SF Pro Icons", "Apple Symbols", "system-ui", sans-serif;
        cursor: pointer;
        transition: background 0.3s;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08);
    }

    .circle-attachment-btn:hover {
        background: var(--accent-color-hover);
    }

    .circle-attachment-btn:disabled {
        background: var(--disabled-bg);
        cursor: not-allowed;
    }

    /* Mobile adjustments for message input */
    @media (max-width: 768px) {
        /* Ensure body and container take full height */
        body {
            height: 100vh;
            height: -webkit-fill-available;
            overflow: hidden;
            overscroll-behavior: none;
        }

        .container {
            height: 100vh;
            height: -webkit-fill-available;
            display: flex;
            flex-direction: column;
        }

        /* Chat screen takes full height */
        #chat-screen {
            height: 100vh;
            height: -webkit-fill-available;
            display: flex;
            flex-direction: column;
        }

        /* Make chat area flex container with sticky input */
        .chat-area {
            flex: 1;
            display: flex;
            flex-direction: column;
            overflow: hidden;
            position: relative;
            min-height: 0;
        }

        .messages-container {
            flex: 1;
            overflow-y: auto;
            padding: 1rem 1.5rem;
            padding-bottom: 120px !important; /* More space for fixed input */
            display: flex;
            flex-direction: column;
            gap: 0.75rem;
            -webkit-overflow-scrolling: touch;
            min-height: 0;
            /* Ensure messages don't get hidden behind input */
            margin-bottom: 0;
        }

        .message-input-container {
            position: fixed !important;
            bottom: 0 !important;
            left: 0 !important;
            right: 0 !important;
            width: 100% !important;
            padding: 1rem !important;
            background: var(--bg-secondary) !important;
            border-top: 1px solid var(--border-color) !important;
            display: flex !important;
            flex-direction: row !important;
            gap: 10px !important;
            align-items: center !important;
            z-index: 1000 !important;
            box-sizing: border-box !important;
            transform: translateZ(0);
            -webkit-transform: translateZ(0);
            padding-bottom: calc(1rem + 50px + env(safe-area-inset-bottom)) !important;
            box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.1) !important;
            /* iPhone specific fixes */
            -webkit-backdrop-filter: blur(10px);
            backdrop-filter: blur(10px);
        }
        
        .message-input-container input {
            flex: 1 !important;
            margin: 0 !important;
            padding: 0.75rem 1rem !important;
            border: 1px solid var(--border-color) !important;
            border-radius: 25px !important;
            background-color: var(--input-bg) !important;
            color: var(--input-text) !important;
            font-size: 16px !important;
            min-height: 44px !important;
            box-sizing: border-box !important;
        }
        
        .message-input-container button {
            padding: 0.75rem 1.5rem !important;
            background: var(--accent-color) !important;
            color: white !important;
            border: none !important;
            border-radius: 25px !important;
            cursor: pointer !important;
            font-size: 1rem !important;
            margin: 0 !important;
            min-width: 60px !important;
            min-height: 44px !important;
            box-sizing: border-box !important;
        }

        /* File upload button positioning */
        .file-upload-area {
            display: flex !important;
            align-items: center !important;
        }

        .circle-attachment-btn {
            width: 44px !important;
            height: 44px !important;
            font-size: 1.5rem !important;
            margin: 0 !important;
        }

        /* Ensure proper header spacing on mobile */
        .header {
            flex-shrink: 0;
        }

        /* Ensure sidebar doesn't interfere */
        .sidebar {
            flex-shrink: 0;
        }
    }

    /* Additional fix for very small screens */
    @media (max-width: 480px) {
        .message-input-container {
            padding: 0.75rem !important;
            padding-bottom: calc(0.75rem + 60px + env(safe-area-inset-bottom)) !important;
        }

        .messages-container {
            padding-bottom: 170px !important; /* Increased even more for iPhone */
            margin-bottom: 50px !important; /* Increased margin */
        }
    }

    /* Modal */
    .modal {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 1000;
    }

    .modal-content {
        background: var(--modal-bg);
        padding: 2rem;
        border-radius: 12px;
        min-width: 400px;
        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
        color: var(--text-primary);
    }

    .modal-content h3 {
        margin-bottom: 1rem;
        color: var(--text-secondary);
    }

    .modal-content input {
        width: 100%;
        padding: 0.75rem;
        border: 1px solid var(--border-color);
        border-radius: 6px;
        margin-bottom: 1rem;
        font-size: 1rem;
    }

    .modal-actions {
        display: flex;
        gap: 1rem;
        justify-content: flex-end;
    }

    .modal-actions button {
        padding: 0.75rem 1.5rem;
        border: none;
        border-radius: 6px;
        cursor: pointer;
        font-size: 1rem;
    }

    .modal-actions button:first-child {
        background: var(--accent-color);
        color: white;
    }

    .modal-actions button:last-child {
        background: var(--border-color);
        color: var(--text-primary);
    }

    .invite-link-container {
        display: flex;
        gap: 0.5rem;
        margin-bottom: 1rem;
    }

    .invite-link-container input {
        flex: 1;
        margin-bottom: 0;
    }

    .invite-link-container button {
        padding: 0.75rem 1rem;
        background: var(--accent-color);
        color: white;
        border: none;
        border-radius: 6px;
        cursor: pointer;
    }

    /* Rooms Collapsible Section */
    .rooms-section {
        position: relative;
    }

    .rooms-section-header {
        display: flex;
        align-items: center;
        cursor: pointer;
        padding: 10px;
        background: var(--bg-secondary);
        border-bottom: 1px solid var(--border-color);
        gap: 10px;
    }

    .rooms-section-header .toggle-icon {
        transition: transform 0.3s ease;
        font-size: 1rem;
        display: flex;
        align-items: center;
        justify-content: center;
        width: 20px;
        height: 20px;
    }

    .rooms-section-header .toggle-icon.rotated {
        transform: rotate(90deg);
    }

    .rooms-section-header h3 {
        margin-left: 5px;
    }

    .rooms-list-container {
        max-height: 250px;
        overflow-y: auto;
        transition: max-height 0.3s ease, opacity 0.3s ease;
        padding-top: 0.5rem;
    }

    .rooms-list-container.collapsed {
        max-height: 0;
        overflow: hidden;
        opacity: 0;
    }

    /* Mobile Specific Adjustments */
    @media (max-width: 768px) {
        .container {
            margin: 0;
        }

        /* Reduce header height on mobile */
        .header {
            padding: 0.375rem 0.75rem; /* Reduced by 25% from 0.5rem 1rem */
        }

        .header h1 {
            font-size: 1rem; /* Reduced by 25% from 1.2rem */
        }

        .status {
            gap: 0.375rem; /* Reduced by 25% from 0.5rem */
            font-size: 0.8rem; /* Reduced from 0.9rem */
        }

        /* Login screen mobile adjustments */
        .login-form {
            gap: 1rem; /* Reduced from 1.5rem */
            padding: 1rem;
            justify-content: flex-start;
            padding-top: 2rem;
        }

        .login-form h2 {
            font-size: 1.5rem; /* Reduced from 2rem */
            margin-bottom: 0.5rem; /* Reduced from 1rem */
        }

        .selected-emoji {
            font-size: 6rem !important; /* 75% of 8rem */
            width: 96px !important; /* 75% of 128px */
            height: 96px !important; /* 75% of 128px */
            margin-bottom: 1rem !important; /* Reduced from 2rem */
            padding: 11.25px !important; /* 75% of 15px */
        }

        .emoji-scroll-container {
            height: 180px; /* Reduced from 240px */
            max-width: 320px; /* Reduced from 400px */
        }

        .emoji-picker {
            margin: 0 auto 0.5rem auto; /* Reduced bottom margin */
        }

        .login-form input {
            width: 280px; /* Reduced from 300px */
            padding: 0.875rem 1.25rem; /* Slightly reduced padding */
            font-size: 1rem; /* Reduced from 1.1rem */
        }

        .auth-options {
            gap: 12px; /* Reduced from 15px */
            margin-top: 15px; /* Reduced from 20px */
            max-width: 280px; /* Reduced from 300px */
        }

        .auth-options button {
            padding: 10px 16px; /* Reduced from 12px 20px */
            font-size: 15px; /* Reduced from 16px */
        }

        #chat-screen {
            margin: 0;
            border-radius: 0;
            flex-direction: column;
            height: 100vh;
        }

        .sidebar {
            width: 100%;
            height: auto;
            max-height: 15%; /* Reduced from 20% to eliminate more dead space */
            border-right: none;
            border-bottom: 1px solid var(--border-color);
            overflow-y: auto;
            padding: 0.25rem; /* Reduced from 0.5rem */
            display: flex;
            flex-direction: column;
            gap: 0; /* Removed gap completely */
        }

        .sidebar-top {
            display: grid;
            grid-template-columns: 1fr 1fr;
            align-items: stretch; /* Changed from center to stretch for equal heights */
            gap: 0.25rem; /* Reduced from 0.5rem */
            margin-bottom: 0; /* Ensure no bottom margin */
        }

        .user-info {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.4rem; /* Reduced from 0.5rem */
            background: var(--bg-primary);
            border-radius: 8px;
            border: 1px solid var(--border-color);
            margin-bottom: 0;
            grid-column: 1;
            height: 100%; /* Ensure full height to match rooms section */
            box-sizing: border-box;
        }

        .user-avatar {
            font-size: 1.2rem;
        }

        .rooms-section-header {
            padding: 0.4rem; /* Reduced from 0.5rem */
            justify-content: space-between;
            align-items: center;
            grid-column: 2;
            background: var(--bg-primary);
            border-radius: 8px;
            border: 1px solid var(--border-color);
            margin-bottom: 0;
            display: flex;
            cursor: pointer;
            height: 100%; /* Ensure full height to match user info */
            box-sizing: border-box;
        }

        .rooms-section-header h3 {
            margin: 0;
            font-size: 1rem;
            color: var(--text-secondary);
        }

        .rooms-section-header .toggle-icon {
            font-size: 1rem;
            margin-right: 0.5rem;
            transition: transform 0.3s ease;
        }

        .rooms-section-header button {
            width: 24px;
            height: 24px;
            font-size: 1rem;
            border-radius: 50%;
            border: none;
            background: var(--accent-color);
            color: white;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-left: 0.5rem;
        }

        .rooms-section {
            grid-column: 1 / -1;
            margin-top: 0;
            margin-bottom: 0; /* Ensure no bottom margin */
        }

        .rooms-list-container {
            max-height: 200px; /* Increased from 120px to show more rooms */
            padding-top: 0.25rem; /* Reduced from 0.5rem */
            overflow-y: auto;
            transition: max-height 0.3s ease, opacity 0.3s ease;
        }

        .rooms-list-container.collapsed {
            max-height: 0;
            overflow: hidden;
            opacity: 0;
        }

        /* Mobile: Display rooms in a horizontal row */
        .rooms-list {
            display: flex;
            flex-direction: row;
            flex-wrap: wrap;
            gap: 0.25rem;
        }

        .room-item {
            padding: 0.4rem 0.6rem; /* Reduced from 0.5rem 0.75rem */
            margin-bottom: 0; /* Remove bottom margin for horizontal layout */
            font-size: 0.9rem;
            background: var(--bg-primary);
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.2s ease;
            border: 1px solid transparent;
            color: var(--text-primary);
            width: auto; /* Auto width to fit text content */
            flex-shrink: 0; /* Don't shrink the buttons */
            white-space: nowrap; /* Keep text on one line */
        }

        .room-item:hover {
            background: var(--room-hover-bg);
            color: var(--text-primary);
            border-color: var(--accent-color);
        }

        .room-item.active {
            background: var(--accent-color);
            color: white;
        }

        .chat-area {
            flex: 1;
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }

        .chat-header {
            display: flex;
            flex-direction: row;
            justify-content: space-between;
            align-items: center;
            padding: 0.75rem;
        }

        .chat-header h3 {
            margin: 0;
            flex-grow: 1;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            font-size: 1rem;
        }

        .room-actions {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .room-actions .room-info-mobile {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .room-actions button {
            padding: 0.5rem 0.75rem;
            font-size: 0.9rem;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            color: white;
        }

        .room-actions .clear-history-btn {
            background-color: var(--orange-color);
        }

        .room-actions .clear-history-btn:hover {
            background: var(--orange-color-hover);
        }

        .room-actions .remove-room-btn {
            background-color: var(--remove-room-color);
        }

        .room-actions .remove-room-btn:hover {
            background: var(--remove-room-color-hover);
        }

        .room-actions .leave-room-btn {
            background-color: var(--dark-red-color);
        }

        .room-actions .leave-room-btn:hover {
            background: var(--dark-red-color-hover);
        }

        #logout-btn {
            background-color: var(--accent-color);
            color: white;
            margin-left: 6px;
        }

        #logout-btn:hover {
            background-color: var(--accent-color-hover);
        }

        .sidebar {
            display: flex;
            flex-direction: column;
        }

        .user-info {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 0.75rem;
        }

        .user-avatar {
            font-size: 1.2rem;
        }

        .rooms-section-header {
            padding: 0.75rem;
        }

        .room-actions button {
            padding: 0.5rem 1rem;
            font-size: 0.9rem;
        }

        .message-input-container {
            padding: 1rem;
            flex-direction: row !important;
            gap: 10px;
            align-items: center;
        }
        .message-input-container input {
            width: 100%;
            margin-bottom: 0;
        }
        .message-input-container button {
            width: auto;
            min-width: 60px;
            margin-left: 0;
        }

        .modal-content {
            min-width: 90%;
            margin: 1rem;
            width: calc(100% - 2rem);
        }

        .invite-section button {
            width: 100%;
        }

        /* Ensure text doesn't overflow */
        #current-room-name, .room-item {
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            max-width: 100%;
        }
    }

    /* Additional mobile-specific tweaks */
    @media (max-width: 375px) {
        .header {
            flex-direction: column;
            align-items: flex-start;
            gap: 10px;
            padding: 1rem;
        }

        .status {
            width: 100%;
            justify-content: space-between;
        }

        .rooms-section {
            width: 100%;
        }

        .section-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            width: 100%;
        }
    }

    .error-message {
        color: var(--system-message-text);
        background-color: var(--system-message-bg);
        padding: 12px 15px;
        border-radius: 8px;
        margin-bottom: 15px;
        text-align: center;
        font-weight: 500;
        border: 2px solid var(--system-message-text);
        animation: fadeIn 0.3s ease-out;
    }

    @keyframes fadeIn {
        from { opacity: 0; transform: translateY(-10px); }
        to { opacity: 1; transform: translateY(0); }
    }

    /* EMOJI PICKER STYLES - Updated at $(Date()) */
    .emoji-picker {
        display: flex;
        flex-direction: column;
        align-items: center;
        width: 100%;
        max-width: 400px;
        margin: 0 auto 1rem auto;
    }

    .selected-emoji {
        font-size: 8rem;
        width: 128px;
        height: 128px;
        display: flex;
        align-items: center;
        justify-content: center;
        margin-bottom: 2rem;
        cursor: pointer;
        transition: transform 0.3s ease;
        background: rgba(255, 255, 255, 0.1);
        border-radius: 20px;
        backdrop-filter: blur(10px);
        padding: 15px;
        box-sizing: content-box;
    }

    .selected-emoji:hover {
        transform: scale(1.05);
    }

    .emoji-scroll-container {
        width: 100%;
        max-width: 400px;
        height: 240px !important;
        background: #2a2a2a !important;
        border-radius: 12px;
        padding: 10px;
        overflow-y: scroll !important;
        overflow-x: hidden !important;
        scrollbar-width: thin;
        scrollbar-color: rgba(255,255,255,0.3) transparent;
        box-sizing: border-box !important;
        margin: 0 auto;
        position: relative;
    }

    .emoji-scroll-container::-webkit-scrollbar {
        width: 6px;
    }

    .emoji-scroll-container::-webkit-scrollbar-track {
        background: transparent;
    }

    .emoji-scroll-container::-webkit-scrollbar-thumb {
        background-color: rgba(255,255,255,0.3);
        border-radius: 3px;
    }

    .emoji-grid {
        display: grid !important;
        grid-template-columns: repeat(6, 1fr) !important;
        gap: 8px;
        width: 100%;
        padding: 0;
        margin: 0;
        height: auto;
    }

    .emoji-option {
        font-size: 1.8rem !important;
        width: 100% !important;
        height: 40px !important;
        display: flex !important;
        align-items: center !important;
        justify-content: center !important;
        cursor: pointer;
        border-radius: 6px;
        transition: all 0.2s ease;
        box-sizing: border-box !important;
        margin: 0 !important;
        padding: 0 !important;
        max-width: none !important;
    }

    .emoji-option:hover {
        transform: scale(1.1);
        background-color: rgba(255,255,255,0.1);
    }

    .emoji-option.selected {
        background-color: rgba(66, 153, 225, 0.8);
        transform: scale(1.05);
    }

    .room-actions .leave-room-btn {
        background-color: var(--dark-red-color);
        transition: background 0.3s ease;
    }

    .room-actions .leave-room-btn:hover {
        background: var(--dark-red-color-hover);
    }

    .room-actions .clear-history-btn {
        background-color: var(--orange-color);
        transition: background 0.3s ease;
        margin-right: 0.5rem;
    }

    .room-actions .clear-history-btn:hover {
        background: var(--orange-color-hover);
    }

    /* File Upload Styles */
    .file-preview-container {
        max-height: 300px;
        overflow-y: auto;
        margin-bottom: 1rem;
        border: 1px solid var(--border-color);
        border-radius: 8px;
        padding: 1rem;
        background: var(--bg-primary);
    }

    .file-preview-item {
        display: flex;
        align-items: center;
        gap: 1rem;
        padding: 0.75rem;
        margin-bottom: 0.5rem;
        background: var(--bg-secondary);
        border-radius: 8px;
        border: 1px solid var(--border-color);
    }

    .file-preview-item:last-child {
        margin-bottom: 0;
    }

    .file-preview-thumbnail {
        width: 60px;
        height: 60px;
        border-radius: 8px;
        object-fit: cover;
        background: var(--bg-primary);
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.5rem;
        border: 1px solid var(--border-color);
    }

    .file-preview-info {
        flex: 1;
        min-width: 0;
    }

    .file-preview-name {
        font-weight: 500;
        color: var(--text-primary);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .file-preview-size {
        font-size: 0.9rem;
        color: var(--text-secondary);
    }

    .file-preview-remove {
        background: var(--red-color);
        color: white;
        border: none;
        border-radius: 50%;
        width: 30px;
        height: 30px;
        cursor: pointer;
        font-size: 1rem;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .file-preview-remove:hover {
        background: var(--red-color-hover);
    }

    .file-upload-controls {
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }

    #file-caption {
        padding: 0.75rem;
        border: 1px solid var(--border-color);
        border-radius: 8px;
        background: var(--input-bg);
        color: var(--input-text);
        font-size: 1rem;
    }

    #file-caption:focus {
        outline: none;
        border-color: var(--accent-color);
        box-shadow: 0 0 0 2px rgba(0, 122, 255, 0.1);
    }

    /* Message attachment styles */
    .message-attachment {
        margin-top: 0.5rem;
        border-radius: 12px;
        background: var(--bg-secondary);
        padding: 0.5rem;
        display: flex;
        justify-content: center;
        align-items: center;
        border: 1px solid var(--border-color);
        box-sizing: border-box;
        max-width: 100%;
    }

    .message-attachment-image {
        display: block;
        max-width: 100%;
        max-height: 400px;
        border-radius: 8px;
        object-fit: contain;
        background: #222;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        image-rendering: auto;
    }

    .message-attachment-file {
        display: flex;
        align-items: center;
        gap: 1rem;
        padding: 1rem;
        text-decoration: none;
        color: var(--text-primary);
        transition: background 0.2s ease;
    }

    .message-attachment-file:hover {
        background: var(--bg-primary);
    }

    .message-attachment-icon {
        width: 40px;
        height: 40px;
        background: var(--accent-color);
        color: white;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.2rem;
        flex-shrink: 0;
    }

    .message-attachment-info {
        flex: 1;
        min-width: 0;
    }

    .message-attachment-name {
        font-weight: 500;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .message-attachment-size {
        font-size: 0.9rem;
        color: var(--text-secondary);
    }

    /* Mobile adjustments for file upload */
    @media (max-width: 768px) {
        .file-preview-container {
            max-height: 200px;
        }
        
        .file-preview-item {
            flex-direction: column;
            align-items: flex-start;
            gap: 0.5rem;
        }
        
        .file-preview-thumbnail {
            width: 50px;
            height: 50px;
        }
        
        .message-attachment-image {
            max-width: 250px;
            max-height: 150px;
        }
    }

    #invite-btn {
        display: none !important;
    }

    .auth-options {
        display: flex;
        flex-direction: column;
        gap: 15px;
        margin-top: 20px;
        width: 100%;
        max-width: 300px;
    }

    .auth-options button {
        padding: 12px 20px;
        border: none;
        border-radius: 8px;
        color: white;
        cursor: pointer;
        font-size: 16px;
        font-weight: 500;
        transition: all 0.3s ease;
        width: 100%;
        text-align: center;
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    }

    .auth-options button:hover {
        transform: translateY(-2px);
        box-shadow: 0 6px 8px rgba(0, 0, 0, 0.15);
    }

    #webauthn-register-btn {
        background-color: #2196F3;
    }

    #webauthn-register-btn:hover {
        background-color: #1976D2;
    }

    #webauthn-login-btn {
        background-color: #FF9800;
    }

    #webauthn-login-btn:hover {
        background-color: #F57C00;
    }

    .room-actions .remove-room-btn {
        background-color: var(--remove-room-color);
        transition: background 0.3s ease;
        margin-right: 0.5rem;
        color: white;
    }

    .room-actions .remove-room-btn:hover {
        background: var(--remove-room-color-hover);
    }

    body.user #clear-history-btn,
    body.user #remove-room-btn {
        display: none !important;
    }
    body.admin #clear-history-btn,
    body.admin #remove-room-btn {
        display: inline-block;
    }

    /* Desktop message input fixes */
    @media (min-width: 769px) {
        .chat-area {
            display: flex;
            flex-direction: column;
            overflow: hidden;
            height: 100%;
        }

        .messages-container {
            flex: 1;
            overflow-y: auto;
            padding: 1rem 1.5rem;
            padding-bottom: 80px; /* Space for message input */
            display: flex;
            flex-direction: column;
            gap: 0.75rem;
            min-height: 0;
        }

        .message-input-container {
            flex-shrink: 0;
            padding: 1.5rem;
            border-top: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            gap: 1rem;
            background: var(--bg-secondary);
            position: sticky;
            bottom: 0;
            z-index: 100;
        }

        .message-input-container input {
            flex: 1;
            padding: 0.75rem 1rem;
            border: 1px solid var(--border-color);
            border-radius: 25px;
            font-size: 1rem;
            background-color: var(--input-bg);
            color: var(--input-text);
        }

        .message-input-container button {
            padding: 0.75rem 1.5rem;
            background: var(--accent-color);
            color: white;
            border: none;
            border-radius: 25px;
            cursor: pointer;
            font-size: 1rem;
        }
    }
    """
}

// MARK: - JavaScript Content
func generateChatJS(adminName: String) -> String {
    return """
    // Updated: 2024-12-19 - Mobile Layout Fixed, Duplicate Button Removed
    // Add at the top of the JS section (before class ChatClient):
    const ADMIN_USERNAME = '\(adminName)';

    class ChatClient {
        constructor() {
            this.ws = null;
            this.username = '';
            this.userEmoji = '👤';
            this.currentRoom = null;
            this.rooms = [];
            this.messages = [];
            this.isConnected = false;
            this.selectedFiles = [];
            
            this.initializeEventListeners();
        }
        
        initializeEventListeners() {
            // Enter key handlers
            document.getElementById('message-input').addEventListener('keypress', (e) => {
                if (e.key === 'Enter') this.sendMessage();
            });
            
            document.getElementById('room-name-input').addEventListener('keypress', (e) => {
                if (e.key === 'Enter') this.createRoom();
            });
        }
        
        connect() {
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const wsUrl = `${protocol}//${window.location.host}`;
            
            this.ws = new WebSocket(wsUrl);
            
            this.ws.onopen = () => {
                console.log('Connected to server');
                this.isConnected = true;
                this.updateConnectionStatus();
                
                // Send join message
                this.sendToServer({
                    type: 'join',
                    username: this.username,
                    emoji: this.userEmoji
                });
                
                // After connecting, automatically join the Lobby room
                const lobbyRoom = this.rooms.find(r => r.name === 'Lobby');
                if (lobbyRoom) {
                    this.joinRoom(lobbyRoom.id);
                }
            };
            
            this.ws.onmessage = (event) => {
                const message = JSON.parse(event.data);
                this.handleServerMessage(message);
            };
            
            this.ws.onclose = () => {
                console.log('Disconnected from server');
                this.isConnected = false;
                this.updateConnectionStatus();
                
                // Attempt to reconnect after 3 seconds
                setTimeout(() => {
                    if (!this.isConnected) {
                        this.connect();
                    }
                }, 3000);
            };
            
            this.ws.onerror = (error) => {
                console.error('WebSocket error:', error);
            };
        }
        
        sendToServer(message) {
            if (this.ws && this.ws.readyState === WebSocket.OPEN) {
                this.ws.send(JSON.stringify(message));
            }
        }
        
        handleServerMessage(message) {
            console.log('Received server message:', message);
            
            switch (message.type) {
                case 'roomList':
                    this.rooms = message.rooms || [];
                    this.updateRoomsList();
                    break;
                    
                case 'roomCreated':
                    if (!this.rooms.find(r => r.id === message.room.id)) {
                        this.rooms.push(message.room);
                        this.updateRoomsList();
                    }
                    // Close the create room dialog
                    hideCreateRoom();
                    
                    // Automatically open rooms list
                    const roomsListContainer = document.getElementById('rooms-list-container');
                    const toggleIcon = document.querySelector('.rooms-section-header .toggle-icon');
                    roomsListContainer.classList.remove('collapsed');
                    toggleIcon.textContent = '▼';
                    
                    // Automatically select the newly created room
                    this.joinRoom(message.room.id);
                    break;
                    
                case 'roomJoined':
                    this.currentRoom = message.room;
                    this.updateRoomsList();
                    document.getElementById('current-room-name').textContent = message.room.name;
                    document.getElementById('leave-room-btn').disabled = false;
                    document.getElementById('clear-history-btn').disabled = false;
                    document.getElementById('message-input').disabled = false;
                    document.getElementById('send-btn').disabled = false;
                    document.getElementById('invite-btn').disabled = false;
                    document.getElementById('file-btn').disabled = false;

                    // Show/hide remove and clear history buttons based on admin and room type
                    const removeBtn = document.getElementById('remove-room-btn');
                    const clearBtn = document.getElementById('clear-history-btn');
                    console.log('DEBUG: Room name:', message.room.name, 'Username:', this.username, 'Admin username:', ADMIN_USERNAME);
                    console.log('DEBUG: Is admin?', this.username === ADMIN_USERNAME);
                    if (message.room.name !== 'Lobby') {
                        if (this.username === ADMIN_USERNAME) {
                            console.log('DEBUG: Showing Remove button for admin in non-Lobby room');
                            if (removeBtn) {
                                removeBtn.style.display = 'inline-block';
                                removeBtn.textContent = `Remove ${message.room.name}`;
                                console.log('DEBUG: Remove button display set to inline-block');
                            } else {
                                console.log('DEBUG: Remove button element not found!');
                            }
                        } else {
                            console.log('DEBUG: Hiding Remove button for non-admin user');
                            if (removeBtn) removeBtn.style.display = 'none';
                        }
                    } else {
                        console.log('DEBUG: Hiding Remove button for Lobby room');
                        if (removeBtn) removeBtn.style.display = 'none';
                    }
                    if (clearBtn) clearBtn.style.display = (this.username === ADMIN_USERNAME) ? 'inline-block' : 'none';

                    // Show system message if Lobby
                    if (message.room.name === 'Lobby') {
                        this.showTemporarySystemMessage('You are now in the Lobby.', 10000);
                    }
                    if (message.type === 'roomJoined' && typeof message.isAdmin !== 'undefined') {
                        document.body.classList.remove('admin', 'user');
                        if (message.isAdmin) {
                            document.body.classList.add('admin');
                        } else {
                            document.body.classList.add('user');
                        }
                    }
                    break;
                    
                case 'chatMessage':
                    this.addMessage(message.message);
                    break;
                    
                case 'userJoined':
                    this.addSystemMessage(`${message.username} joined the room`);
                    break;
                    
                case 'userLeft':
                    this.addSystemMessage(`${message.username} left the room`);
                    break;
                    
                case 'inviteCreated':
                    this.showInviteLink(message.link);
                    break;
                    
                case 'chatHistoryCleared':
                    if (this.currentRoom && this.currentRoom.id === message.roomId) {
                        this.messages = [];
                        this.updateMessagesDisplay();
                        this.addSystemMessage('Chat history has been cleared');
                    }
                    break;
                    
                case 'error':
                    if (message.message.includes('room with this name already exists')) {
                        this.showRoomCreationError(message.message);
                    } else {
                        alert('Error: ' + message.message);
                    }
                    break;
                    
                case 'userCount':
                    this.updateUserCount(message.count);
                    break;
                    
                case 'roomRemoved':
                    console.log('[roomRemoved] Received for roomId:', message.roomId);
                    this.rooms = this.rooms.filter(r => r.id !== message.roomId);
                    if (this.currentRoom && this.currentRoom.id === message.roomId) {
                        this.currentRoom = null;
                        document.getElementById('current-room-name').textContent = 'Select a room';
                        document.getElementById('leave-room-btn').disabled = true;
                        document.getElementById('clear-history-btn').disabled = true;
                        document.getElementById('message-input').disabled = true;
                        document.getElementById('send-btn').disabled = true;
                        document.getElementById('invite-btn').disabled = true;
                        document.getElementById('file-btn').disabled = true;
                        document.getElementById('remove-room-btn').style.display = 'none';
                        this.messages = [];
                        this.updateMessagesDisplay();
                    }
                    this.updateRoomsList();
                    break;
            }
        }
        
        joinChat() {
            const usernameInput = document.getElementById('username-input');
            const username = usernameInput.value.trim();
            
            if (!username) {
                alert('Please enter a username');
                return;
            }
            
            this.username = username;
            document.getElementById('current-username').textContent = username;
            
            // Switch to chat screen
            document.getElementById('login-screen').classList.add('hidden');
            document.getElementById('chat-screen').classList.remove('hidden');
            
            // Connect to server
            this.connect();
        }
        
        createRoom() {
            const roomNameInput = document.getElementById('room-name-input');
            const roomName = roomNameInput.value.trim();
            
            if (!roomName) {
                alert('Please enter a room name');
                return;
            }
            
            try {
                this.sendToServer({
                    type: 'createRoom',
                    name: roomName
                });
                
                roomNameInput.value = '';
            } catch (error) {
                console.error('Failed to create room:', error);
                this.showRoomCreationError('Failed to create room. Please try again.');
            }
        }
        
        showRoomCreationError(message) {
            const createRoomModal = document.getElementById('create-room-modal');
            
            // Show error message
            const errorContainer = document.createElement('div');
            errorContainer.className = 'error-message';
            errorContainer.textContent = message;
            createRoomModal.querySelector('.modal-content').insertBefore(
                errorContainer, 
                createRoomModal.querySelector('.modal-actions')
            );
            
            // Remove error message after longer duration
            setTimeout(() => {
                if (errorContainer) {
                    errorContainer.remove();
                }
            }, 3000);
        }
        
        joinRoom(roomId) {
            const room = this.rooms.find(r => r.id === roomId);
            if (!room) return;
            this.currentRoom = room;
            document.getElementById('current-room-name').textContent = room.name;
            document.getElementById('leave-room-btn').disabled = false;
            document.getElementById('clear-history-btn').disabled = false;
            document.getElementById('message-input').disabled = false;
            document.getElementById('send-btn').disabled = false;
            document.getElementById('invite-btn').disabled = false;
            document.getElementById('file-btn').disabled = false;
            // Show/hide remove and clear history buttons based on admin
            const removeBtn = document.getElementById('remove-room-btn');
            const clearBtn = document.getElementById('clear-history-btn');
            console.log('DEBUG: Room name:', room.name, 'Username:', this.username, 'Admin username:', ADMIN_USERNAME);
            console.log('DEBUG: Is admin?', this.username === ADMIN_USERNAME);
            if (room.name !== 'Lobby') {
                if (this.username === ADMIN_USERNAME) {
                    console.log('DEBUG: Showing Remove button for admin in non-Lobby room');
                    if (removeBtn) {
                        removeBtn.style.display = 'inline-block';
                        removeBtn.textContent = `Remove ${room.name}`;
                        console.log('DEBUG: Remove button display set to inline-block');
                    } else {
                        console.log('DEBUG: Remove button element not found!');
                    }
                } else {
                    console.log('DEBUG: Hiding Remove button for non-admin user');
                    if (removeBtn) removeBtn.style.display = 'none';
                }
            } else {
                console.log('DEBUG: Hiding Remove button for Lobby room');
                if (removeBtn) removeBtn.style.display = 'none';
            }
            if (clearBtn) clearBtn.style.display = (this.username === ADMIN_USERNAME) ? 'inline-block' : 'none';
            
            // Clear messages
            this.messages = [];
            this.updateMessagesDisplay();
            
            // Update room selection
            document.querySelectorAll('.room-item').forEach(item => {
                item.classList.remove('active');
            });
            document.querySelector(`[data-room-id="${roomId}"]`).classList.add('active');
            
            // Send join room message
            this.sendToServer({
                type: 'joinRoom',
                roomId: roomId
            });
        }
        
        leaveRoom() {
            if (!this.currentRoom) return;
            
            this.sendToServer({
                type: 'leaveRoom',
                roomId: this.currentRoom.id
            });
            
            this.currentRoom = null;
            
            // Update UI
            document.getElementById('current-room-name').textContent = 'Select a room';
            document.getElementById('leave-room-btn').disabled = true;
            document.getElementById('clear-history-btn').disabled = true;
            document.getElementById('message-input').disabled = true;
            document.getElementById('send-btn').disabled = true;
            document.getElementById('invite-btn').disabled = true;
            document.getElementById('file-btn').disabled = true;
            
            // Clear room selection
            document.querySelectorAll('.room-item').forEach(item => {
                item.classList.remove('active');
            });
            
            // Clear messages
            this.messages = [];
            this.updateMessagesDisplay();
        }
        
        clearChatHistory() {
            if (this.username !== ADMIN_USERNAME) {
                alert('Only ' + ADMIN_USERNAME + ' can clear history.');
                return;
            }
            if (!this.currentRoom) return;
            
            if (confirm('Are you sure you want to clear the chat history for this room? This action cannot be undone.')) {
                this.sendToServer({
                    type: 'clearChatHistory',
                    roomId: this.currentRoom.id
                });
            }
        }
        
        sendMessage() {
            const messageInput = document.getElementById('message-input');
            const content = messageInput.value.trim();
            
            if (!content || !this.currentRoom) return;
            
            this.sendToServer({
                type: 'sendMessage',
                roomId: this.currentRoom.id,
                content: content,
                emoji: this.userEmoji
            });
            
            messageInput.value = '';
        }
        
        createInvite() {
            if (!this.currentRoom) return;
            
            this.sendToServer({
                type: 'createInvite',
                roomId: this.currentRoom.id
            });
        }
        
        async uploadFile(file) {
            const formData = new FormData();
            formData.append('file', file);
            try {
                console.log('📤 Uploading file:', file.name, 'Size:', file.size, 'Type:', file.type);
                const response = await fetch('http://upload.xcf.ai/upload', {
                    method: 'POST',
                    body: formData
                });
                if (!response.ok) {
                    const errorText = await response.text();
                    console.error('❌ Upload failed:', response.status, errorText);
                    throw new Error(`Upload failed: ${response.status} ${errorText}`);
                }
                const result = await response.json();
                if (result.success) {
                    console.log('✅ Upload successful:', result.attachment);
                    return result.attachment;
                } else {
                    console.error('❌ Upload failed:', result.error);
                    throw new Error(result.error || 'Upload failed');
                }
            } catch (error) {
                console.error('❌ File upload error:', error);
                throw error;
            }
        }
        
        async sendFileMessage(attachment, caption = '') {
            if (!this.currentRoom) return;
            
            console.log('Sending file message:', {
                roomId: this.currentRoom.id,
                attachment: attachment,
                caption: caption
            });
            
            this.sendToServer({
                type: 'sendFileMessage',
                roomId: this.currentRoom.id,
                attachment: attachment,
                caption: caption
            });
        }
        
        selectFiles() {
            if (!this.currentRoom) {
                alert('Please join a room before uploading files.');
                return;
            }
            document.getElementById('file-input').click();
        }
        
        handleFileSelection(files) {
            if (!this.currentRoom) {
                alert('Please join a room before uploading files.');
                return;
            }
            this.selectedFiles = Array.from(files);
            this.showFileUploadModal();
        }
        
        showFileUploadModal() {
            const modal = document.getElementById('file-upload-modal');
            const container = document.getElementById('file-preview-container');
            const uploadBtn = document.getElementById('upload-files-btn');
            
            container.innerHTML = '';
            
            if (this.selectedFiles.length === 0) {
                container.innerHTML = '<p>No files selected</p>';
                uploadBtn.disabled = true;
                return;
            }
            
            uploadBtn.disabled = false;
            
            this.selectedFiles.forEach((file, index) => {
                const item = document.createElement('div');
                item.className = 'file-preview-item';
                
                const thumbnail = document.createElement('div');
                thumbnail.className = 'file-preview-thumbnail';
                
                if (file.type.startsWith('image/')) {
                    const img = document.createElement('img');
                    img.src = URL.createObjectURL(file);
                    img.onload = () => URL.revokeObjectURL(img.src);
                    img.style.width = '100%';
                    img.style.height = '100%';
                    img.style.objectFit = 'cover';
                    img.style.borderRadius = '8px';
                    thumbnail.appendChild(img);
                } else {
                    thumbnail.textContent = this.getFileIcon(file.type);
                }
                
                const info = document.createElement('div');
                info.className = 'file-preview-info';
                
                const name = document.createElement('div');
                name.className = 'file-preview-name';
                name.textContent = file.name;
                
                const size = document.createElement('div');
                size.className = 'file-preview-size';
                size.textContent = this.formatFileSize(file.size);
                
                info.appendChild(name);
                info.appendChild(size);
                
                const removeBtn = document.createElement('button');
                removeBtn.className = 'file-preview-remove';
                removeBtn.textContent = '×';
                removeBtn.onclick = () => this.removeFile(index);
                
                item.appendChild(thumbnail);
                item.appendChild(info);
                item.appendChild(removeBtn);
                
                container.appendChild(item);
            });
            
            modal.classList.remove('hidden');
        }
        
        removeFile(index) {
            this.selectedFiles.splice(index, 1);
            this.showFileUploadModal();
        }
        
        async uploadFiles() {
            if (this.selectedFiles.length === 0) return;
            
            const caption = document.getElementById('file-caption').value.trim();
            const uploadBtn = document.getElementById('upload-files-btn');
            const errorDiv = document.getElementById('upload-error');
            
            uploadBtn.disabled = true;
            uploadBtn.textContent = 'Uploading...';
            if (errorDiv) errorDiv.textContent = '';
            
            try {
                for (const file of this.selectedFiles) {
                    console.log('📤 Processing file:', file.name);
                    const attachment = await this.uploadFile(file);
                    await this.sendFileMessage(attachment, caption);
                }
                
                this.hideFileUploadModal();
                this.selectedFiles = [];
                document.getElementById('file-caption').value = '';
                
            } catch (error) {
                console.error('❌ Upload failed:', error);
                if (errorDiv) {
                    errorDiv.textContent = error.message || 'Upload failed';
                    errorDiv.style.display = 'block';
                } else {
                    alert('Upload failed: ' + error.message);
                }
            } finally {
                uploadBtn.disabled = false;
                uploadBtn.textContent = 'Upload';
            }
        }
        
        hideFileUploadModal() {
            document.getElementById('file-upload-modal').classList.add('hidden');
        }
        
        getFileIcon(mimeType) {
            if (mimeType.startsWith('image/')) return '🖼️';
            if (mimeType.includes('pdf')) return '📄';
            if (mimeType.includes('word') || mimeType.includes('document')) return '📝';
            if (mimeType.includes('excel') || mimeType.includes('spreadsheet')) return '📊';
            if (mimeType.includes('powerpoint') || mimeType.includes('presentation')) return '📈';
            if (mimeType.includes('zip') || mimeType.includes('archive')) return '🗜️';
            if (mimeType.includes('text')) return '📄';
            return '📎';
        }
        
        formatFileSize(bytes) {
            if (bytes === 0) return '0 Bytes';
            const k = 1024;
            const sizes = ['Bytes', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
        }
        
        addMessage(message) {
            this.messages.push(message);
            this.updateMessagesDisplay();
        }
        
        addSystemMessage(content) {
            const message = {
                type: 'system',
                content: content,
                timestamp: new Date().toISOString()
            };
            this.addMessage(message);
        }
        
        updateMessagesDisplay() {
            const container = document.getElementById('messages-container');
            
            if (this.messages.length === 0) {
                const welcomeText = this.currentRoom ? 
                    `Welcome to ${this.currentRoom.name}!` : 
                    `Welcome to ${window.location.hostname}!`;
                    
                container.innerHTML = `
                    <div class="welcome-message">
                        <h3>${welcomeText} 🎉</h3>
                        <p>${this.currentRoom ? 'Start chatting with others in this room.' : 'Create a room or join an existing one to start chatting.'}</p>
                    </div>
                `;
                return;
            }
            
            container.innerHTML = '';
            
            this.messages.forEach(message => {
                const messageEl = document.createElement('div');
                
                if (message.type === 'system') {
                    messageEl.className = 'message system lobby-welcome';
                    messageEl.textContent = message.content;
                } else {
                    const isOwn = message.sender === this.username;
                    messageEl.className = `message ${isOwn ? 'own' : 'other'}`;
                    
                    const time = new Date(message.timestamp).toLocaleTimeString([], {
                        hour: '2-digit',
                        minute: '2-digit'
                    });
                    
                    let attachmentHTML = '';
                    if (message.attachment) {
                        const attachment = message.attachment;
                        if (attachment.isImage) {
                            const imageUrl = `/files/${attachment.fileName}`;
                            attachmentHTML = `
                                <div class="message-attachment">
                                    <img src="${imageUrl}" 
                                         alt="${attachment.originalFileName}"
                                         class="message-attachment-image"
                                         onclick="window.open('${imageUrl}', '_blank')">
                                </div>
                            `;
                        } else {
                            attachmentHTML = `
                                <div class="message-attachment">
                                    <a href="/files/${attachment.fileName}" 
                                       class="message-attachment-file" 
                                       target="_blank" 
                                       download="${attachment.originalFileName}">
                                        <div class="message-attachment-icon">${this.getFileIcon(attachment.mimeType)}</div>
                                        <div class="message-attachment-info">
                                            <div class="message-attachment-name">${attachment.originalFileName}</div>
                                            <div class="message-attachment-size">${this.formatFileSize(attachment.fileSize)}</div>
                                        </div>
                                    </a>
                                </div>
                            `;
                        }
                    }
                    
                    messageEl.innerHTML = `
                        <div class="message-header">
                            <span class="user-emoji">${message.emoji || '👤'}</span>
                            <span class="username">${isOwn ? 'You' : message.sender}</span>
                            <span class="time">${time}</span>
                        </div>
                        <div class="message-content">${this.escapeHtml(message.content)}</div>
                        ${attachmentHTML}
                    `;
                }
                
                container.appendChild(messageEl);
            });
            
            // Scroll to bottom
            container.scrollTop = container.scrollHeight;
        }
        
        updateRoomsList() {
            const container = document.getElementById('rooms-list');
            container.innerHTML = '';
            
            this.rooms.forEach(room => {
                const roomEl = document.createElement('div');
                roomEl.className = 'room-item';
                roomEl.setAttribute('data-room-id', room.id);
                roomEl.textContent = room.name;
                roomEl.onclick = () => this.joinRoom(room.id);
                container.appendChild(roomEl);
            });
            // Highlight the selected room
            if (this.currentRoom) {
                const activeRoom = container.querySelector(`[data-room-id="${this.currentRoom.id}"]`);
                if (activeRoom) activeRoom.classList.add('active');
            }
        }
        
        updateConnectionStatus() {
            const statusEl = document.getElementById('connection-status');
            if (this.isConnected) {
                statusEl.textContent = 'Connected';
                statusEl.className = 'status-connected';
            } else {
                statusEl.textContent = 'Disconnected';
                statusEl.className = 'status-disconnected';
            }
        }
        
        updateUserCount(count) {
            document.getElementById('user-count').textContent = `${count} user${count !== 1 ? 's' : ''} online`;
        }
        
        showInviteLink(link) {
            document.getElementById('invite-link').value = link;
            document.getElementById('invite-modal').classList.remove('hidden');
        }
        
        escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        showTemporarySystemMessage(content, durationMs) {
            const container = document.getElementById('messages-container');
            const msg = document.createElement('div');
            msg.className = 'message system lobby-welcome';
            msg.textContent = content;
            container.appendChild(msg);
            container.scrollTop = container.scrollHeight;

            setTimeout(() => {
                msg.style.transition = 'opacity 1s';
                msg.style.opacity = 0;
                setTimeout(() => msg.remove(), 1000);
            }, durationMs);
        }

        removeRoom() {
            if (this.username !== ADMIN_USERNAME) {
                alert('Only ' + ADMIN_USERNAME + ' can remove rooms.');
                return;
            }
            if (!this.currentRoom || this.currentRoom.name === 'Lobby') return;
            if (confirm(`Are you sure you want to remove the room '${this.currentRoom.name}'? This cannot be undone.`)) {
                this.sendToServer({ type: 'removeRoom', roomId: this.currentRoom.id });
            }
        }
    }
    
    // Global functions for HTML onclick handlers
    let chatClient;
    
    function joinChat() {
        chatClient.joinChat();
    }
    
    function createRoom() {
        chatClient.createRoom();
    }
    
    function leaveRoom() {
        chatClient.leaveRoom();
    }
    
    function sendMessage() {
        chatClient.sendMessage();
    }
    
    function createInvite() {
        chatClient.createInvite();
    }
    
    function clearChatHistory() {
        chatClient.clearChatHistory();
    }
    
    function selectFiles() {
        chatClient.selectFiles();
    }
    
    function uploadFiles() {
        chatClient.uploadFiles();
    }
    
    function hideFileUploadModal() {
        chatClient.hideFileUploadModal();
    }
    
    function showCreateRoom() {
        document.getElementById('create-room-modal').classList.remove('hidden');
        document.getElementById('room-name-input').focus();
    }
    
    function hideCreateRoom() {
        document.getElementById('create-room-modal').classList.add('hidden');
    }
    
    function hideInviteModal() {
        document.getElementById('invite-modal').classList.add('hidden');
    }
    
    function copyInviteLink() {
        const linkInput = document.getElementById('invite-link');
        linkInput.select();
        document.execCommand('copy');
        
        // Show feedback
        const button = event.target;
        const originalText = button.textContent;
        button.textContent = 'Copied!';
        setTimeout(() => {
            button.textContent = originalText;
        }, 2000);
    }
    
    function toggleRoomsList() {
        const roomsListContainer = document.getElementById('rooms-list-container');
        const toggleIcon = document.querySelector('.rooms-section-header .toggle-icon');
        
        roomsListContainer.classList.toggle('collapsed');
        
        // Change arrow based on state
        if (roomsListContainer.classList.contains('collapsed')) {
            toggleIcon.textContent = '▶'; // Right arrow when collapsed
        } else {
            toggleIcon.textContent = '▼'; // Down arrow when expanded
        }
    }
    
    // Ensure initial state is correct on page load
    document.addEventListener('DOMContentLoaded', () => {
        const roomsListContainer = document.getElementById('rooms-list-container');
        const toggleIcon = document.querySelector('.rooms-section-header .toggle-icon');
        
        // Initially collapsed
        roomsListContainer.classList.add('collapsed');
        toggleIcon.textContent = '▶';

        chatClient = new ChatClient();
        
        // Emoji picker setup
        const selectedEmoji = document.getElementById('selected-emoji');
        const emojiOptions = document.querySelectorAll('.emoji-option');
        let currentEmoji = '👤';

        // Set initial selected emoji
        selectedEmoji.textContent = currentEmoji;
        emojiOptions[0].classList.add('selected');

        emojiOptions.forEach(option => {
            option.addEventListener('click', () => {
                // Remove selected class from all options
                emojiOptions.forEach(opt => opt.classList.remove('selected'));
                
                // Add selected class to clicked option
                option.classList.add('selected');
                
                // Update selected emoji
                currentEmoji = option.textContent;
                selectedEmoji.textContent = currentEmoji;
            });
        });
        
        // Modify joinChat to include emoji
        window.joinChat = function() {
            const usernameInput = document.getElementById('username-input');
            const username = usernameInput.value.trim();
            
            if (!username) {
                alert('Please enter a username');
                return;
            }
            
            chatClient.username = username;
            chatClient.userEmoji = currentEmoji;
            document.getElementById('current-username').textContent = username;
            document.querySelector('.user-avatar').textContent = currentEmoji;
            
            // Switch to chat screen
            document.getElementById('login-screen').classList.add('hidden');
            document.getElementById('chat-screen').classList.remove('hidden');
            
            // Connect to server
            chatClient.connect();
        }
        
        // Focus username input
        document.getElementById('username-input').focus();
        
        // Close modals when clicking outside
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('modal')) {
                e.target.classList.add('hidden');
            }
        });
        
        // File input event listener
        document.getElementById('file-input').addEventListener('change', (e) => {
            if (e.target.files.length > 0) {
                chatClient.handleFileSelection(e.target.files);
            }
        });

        // Note: Create room button already exists in HTML - no need to create duplicate
    });

    // After the ChatClient class definition, add:
    window.removeRoom = function() { chatClient.removeRoom(); };

    function logout() {
        // Return to login screen, clear session
        document.getElementById('chat-screen').classList.add('hidden');
        document.getElementById('login-screen').classList.remove('hidden');
        // Optionally clear username, emoji, etc.
        document.getElementById('username-input').value = '';
        document.getElementById('selected-emoji').textContent = '👤';
        // Disconnect WebSocket if needed
        if (window.chatClient && window.chatClient.ws) {
            window.chatClient.ws.close();
        }
    }
    """
}
