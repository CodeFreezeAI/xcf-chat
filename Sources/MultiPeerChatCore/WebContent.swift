import Foundation

// MARK: - HTML Content
func generateIndexHTML() -> String {
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no, viewport-fit=cover">
        
        <!-- Primary Meta Tags -->
        <title>💬 chat.xcf.ai</title>
        <meta name="title" content="XCF Chat - Secure Real-time Chat">
        <meta name="description" content="Anonymous • Passwordless • Emoji Avatars • WebAuthn FIDO2 Passkey Security">
        <meta name="keywords" content="chat, real-time, secure, WebAuthn, emoji, file sharing, instant messaging, group chat, rooms">
        <meta name="author" content="XCF Chat">
        <meta name="robots" content="index, follow">
        
        <!-- Open Graph / Facebook -->
        <meta property="og:type" content="website">
        <meta property="og:url" content="https://chat.xcf.ai/">
        <meta property="og:title" content="XCF Chat - Secure Real-time Chat Platform">
        <meta property="og:description" content="Anonymous • Passwordless • Emoji Avatars • WebAuthn FIDO2 Passkey Security">
        <meta property="og:image" content="https://chat.xcf.ai/chat-preview.png">
        <meta property="og:image:width" content="1200">
        <meta property="og:image:height" content="630">
        <meta property="og:image:alt" content="XCF Chat - Modern chat interface with emoji avatars">
        <meta property="og:site_name" content="XCF Chat">
        <meta property="og:locale" content="en_US">
        
        <!-- Twitter -->
        <meta property="twitter:card" content="summary_large_image">
        <meta property="twitter:url" content="https://chat.xcf.ai/">
        <meta property="twitter:title" content="XCF Chat - Secure Real-time Chat Platform">
        <meta property="twitter:description" content="Anonymous • Passwordless • Emoji Avatars • WebAuthn FIDO2 Passkey Security">
        <meta property="twitter:image" content="https://chat.xcf.ai/chat-preview.png">
        <meta property="twitter:image:alt" content="XCF Chat - Modern chat interface with emoji avatars">
        
        <!-- LinkedIn -->
        <meta property="linkedin:owner" content="">
        
        <!-- Apple / iMessage -->
        <meta name="apple-mobile-web-app-capable" content="yes">
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
        <meta name="apple-mobile-web-app-title" content="XCF Chat">
        <meta name="apple-touch-fullscreen" content="yes">
        <link rel="apple-touch-icon" sizes="57x57" href="/icons/apple-icon-57x57.png">
        <link rel="apple-touch-icon" sizes="60x60" href="/icons/apple-icon-60x60.png">
        <link rel="apple-touch-icon" sizes="72x72" href="/icons/apple-icon-72x72.png">
        <link rel="apple-touch-icon" sizes="76x76" href="/icons/apple-icon-76x76.png">
        <link rel="apple-touch-icon" sizes="114x114" href="/icons/apple-icon-114x114.png">
        <link rel="apple-touch-icon" sizes="120x120" href="/icons/apple-icon-120x120.png">
        <link rel="apple-touch-icon" sizes="144x144" href="/icons/apple-icon-144x144.png">
        <link rel="apple-touch-icon" sizes="152x152" href="/icons/apple-icon-152x152.png">
        <link rel="apple-touch-icon" sizes="180x180" href="/icons/apple-icon-180x180.png">
        
        <!-- Favicons -->
        <link rel="icon" type="image/png" href="/favicon.png">
        <link rel="icon" type="image/svg+xml" href="/favicon.ico">
        <link rel="icon" type="image/png" sizes="32x32" href="/icons/favicon-32x32.png">
        <link rel="icon" type="image/png" sizes="96x96" href="/icons/favicon-96x96.png">
        <link rel="icon" type="image/png" sizes="16x16" href="/icons/favicon-16x16.png">
        <link rel="shortcut icon" href="/favicon.ico">
        
        <!-- Microsoft -->
        <meta name="msapplication-TileColor" content="#007AFF">
        <meta name="msapplication-TileImage" content="/icons/ms-icon-144x144.png">
        <meta name="msapplication-config" content="/browserconfig.xml">
        
        <!-- Android -->
        <!-- Light mode theme color -->
        <meta name="theme-color" content="#eceff1" media="(prefers-color-scheme: light)">
        
        <!-- Dark mode theme color -->
        <meta name="theme-color" content="#121212" media="(prefers-color-scheme: dark)">
        <meta name="mobile-web-app-capable" content="yes">
        
        <!-- Web App Manifest -->
        <link rel="manifest" href="/manifest.json">
        
        <!-- Additional Meta Tags -->
        <meta name="format-detection" content="telephone=no">
        <meta name="format-detection" content="date=no">
        <meta name="format-detection" content="address=no">
        <meta name="format-detection" content="email=no">
        
        <!-- Security -->
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta http-equiv="Content-Security-Policy" content="default-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob: https:; img-src 'self' data: blob: https:; media-src 'self' blob: https:;">
        
        <!-- Preconnect for performance -->
        <link rel="preconnect" href="https://chat.xcf.ai">
        
        <link rel="stylesheet" href="/stylev1d.css">
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
                                <input type="file" id="file-input" style="display:none;" accept="image/*,.pdf,.doc,.docx,.txt,.zip" multiple>
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

        <script src="/chatv1d.js"></script>
        <script>
        // Hide upload button and file input for now
        /*
        window.addEventListener('DOMContentLoaded', function() {
            var fileBtn = document.getElementById('file-btn');
            var fileInput = document.getElementById('file-input');
            if (fileBtn) fileBtn.style.display = 'none';
            if (fileInput) fileInput.style.display = 'none';
        });
        */

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
    /* COMPLETELY REVAMPED MOBILE-FIRST CSS - 2024-12-19 */
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
        --remove-room-color: #FF5E3A;
        --remove-room-color-hover: #E04A1F;
        
        /* Safari scrollbar appearance - light mode */
        color-scheme: light;
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
            
            /* Safari scrollbar appearance - dark mode */
            color-scheme: dark;
        }
        .message.other {
            background: #000 !important;
            color: #e2e8f0;
        }
        .message.own {
            background: #0a84ff !important;
            color: #fff;
        }
    }

    * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
        transition: background-color 0.3s ease, color 0.3s ease;
    }

    /* PROPER MOBILE VIEWPORT HANDLING */
    html {
        height: 100%;
        /* Modern viewport units for mobile */
        height: 100dvh;
        height: -webkit-fill-available;
        overflow: hidden;
    }

    body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        background: linear-gradient(135deg, var(--gradient-start) 0%, var(--gradient-end) 100%), var(--bg-primary);
        height: 100%;
        height: 100dvh;
        height: -webkit-fill-available;
        color: var(--text-primary);
        line-height: 1.6;
        overflow: hidden;
        position: fixed;
        width: 100%;
        overscroll-behavior: none;
        -webkit-overflow-scrolling: touch;
    }

    .container {
        width: 100%;
        height: 100%;
        height: 100dvh;
        height: -webkit-fill-available;
        display: flex;
        flex-direction: column;
        overflow: hidden;
    }

    /* DESKTOP-FIRST HEADER */
    .header {
        background: var(--modal-bg);
        backdrop-filter: blur(10px);
        padding: 1rem 2rem;
        display: flex;
        justify-content: space-between;
        align-items: center;
        box-shadow: 0 2px 20px rgba(0, 0, 0, 0.1);
        color: var(--text-primary);
        flex-shrink: 0;
        z-index: 100;
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
        min-height: 0;
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
        gap: 0.75rem;
        padding: 2rem;
    }

    .login-form h2 {
        color: white;
        font-size: 2rem;
        margin-bottom: 0.5rem;
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

    .selected-emoji {
        font-size: 4rem !important;
        width: 80px !important;
        height: 80px !important;
        margin-bottom: 1rem !important;
        flex-shrink: 0;
    }

    .emoji-scroll-container {
        height: 150px;
        width: 100%;
        max-width: 300px;
        flex-shrink: 0;
    }

    .emoji-picker {
        flex-shrink: 0;
        width: 90%;
        max-width: 300px;
        display: flex;
        flex-direction: column;
        align-items: center;
    }

    .auth-options {
        gap: 12px;
        margin-top: 15px;
        margin-bottom: 2rem;
        width: 90%;
        max-width: 300px;
        flex-shrink: 0;
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

    /* DESKTOP CHAT SCREEN */
    #chat-screen {
        display: flex;
        background: var(--modal-bg);
        backdrop-filter: blur(10px);
        margin: 0;
        border-radius: 0;
        overflow: hidden;
        box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
        color: var(--text-primary);
        height: 100%;
    }

    .sidebar {
        width: 300px;
        background: var(--bg-secondary);
        border-right: 1px solid var(--border-color);
        display: flex;
        flex-direction: column;
        padding: 1.5rem;
        overflow-y: auto;
        flex-shrink: 0;
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
        flex: 1;
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
        margin-bottom: 0.5rem;
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

    .rooms-list-container {
        max-height: 100%;
        overflow-y: auto;
        padding-top: 2px;
        transition: max-height 0.3s ease, opacity 0.3s ease;
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

    /* DESKTOP CHAT AREA */
    .chat-area {
        flex: 1;
        display: flex;
        flex-direction: column;
        overflow: hidden;
        min-height: 0;
    }

    .chat-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 1rem 1.5rem;
        background: var(--bg-secondary);
        border-bottom: 1px solid var(--border-color);
        flex-shrink: 0;
        z-index: 10;
    }

    .chat-header h3 {
        margin: 0;
        flex-grow: 1;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        font-size: 1.1rem;
    }

    .room-actions {
        display: flex;
        align-items: center;
        gap: 12px;
    }

    .room-actions .room-info-mobile {
        display: flex;
        align-items: center;
        gap: 10px;
    }

    .room-actions button {
        padding: 0.6rem 1.2rem;
        background: var(--accent-color);
        color: white;
        border: none;
        border-radius: 6px;
        cursor: pointer;
        font-size: 0.9rem;
        transition: background 0.3s ease;
    }

    .room-actions button:disabled {
        background: var(--disabled-bg);
        cursor: not-allowed;
    }

    .room-actions .leave-room-btn {
        background-color: var(--dark-red-color);
    }

    .room-actions .leave-room-btn:hover {
        background: var(--dark-red-color-hover);
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

    #logout-btn {
        background-color: var(--accent-color);
    }

    #logout-btn:hover {
        background-color: var(--accent-color-hover);
    }

    /* DESKTOP MESSAGES CONTAINER */
    .messages-container {
        flex: 1;
        overflow-y: auto;
        padding: 1rem 1.5rem;
        padding-bottom: 1rem;
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
        -webkit-overflow-scrolling: touch;
        min-height: 0;
    }

    .welcome-message {
        text-align: center;
        color: var(--text-secondary);
        margin-top: 2rem;
    }

    /* DESKTOP MESSAGE INPUT */
    .message-input-container {
        padding: 1.5rem;
        border-top: 1px solid var(--border-color);
        display: flex;
        align-items: center;
        gap: 1rem;
        background: var(--bg-secondary);
        flex-shrink: 0;
        z-index: 10;
    }

    .message-input-container input {
        flex: 1;
        padding: 0.75rem 1rem;
        border: 1px solid var(--border-color);
        border-radius: 25px;
        font-size: 1rem;
        background-color: var(--input-bg);
        color: var(--input-text);
        outline: none;
    }

    .message-input-container input:focus {
        border: 2px solid var(--accent-color);
        box-shadow: 0 0 0 3px rgba(0, 122, 255, 0.1);
    }

    .message-input-container button {
        padding: 0.75rem 1.5rem;
        background: var(--accent-color);
        color: white;
        border: none;
        border-radius: 25px;
        cursor: pointer;
        font-size: 1rem;
        transition: background 0.3s ease;
    }

    .message-input-container button:hover {
        background: var(--accent-color-hover);
    }

    .file-upload-area {
        display: flex;
        align-items: center;
    }

    .circle-attachment-btn {
        width: 44px;
        height: 44px;
        border-radius: 50%;
        border: none;
        background: var(--accent-color);
        color: white;
        cursor: pointer;
        font-size: 1.2rem;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: background 0.3s ease;
    }

    .circle-attachment-btn:hover {
        background: var(--accent-color-hover);
    }

    .circle-attachment-btn:disabled {
        background: var(--disabled-bg);
        cursor: not-allowed;
    }

    /* MOBILE COMPLETE OVERHAUL */
    @media (max-width: 768px) {
        /* ENSURE PROPER MOBILE VIEWPORT */
        html {
            height: 100%;
            height: 100dvh;
            height: -webkit-fill-available;
        }

        body {
            height: 100%;
            height: 100dvh;
            height: -webkit-fill-available;
            overflow: hidden;
            position: fixed;
            width: 100%;
        }

        .container {
            height: 100%;
            height: 100dvh;
            height: -webkit-fill-available;
        }

        /* MOBILE HEADER - COMPACT */
        .header {
            padding: 0.5rem 1rem;
            min-height: 60px;
            flex-shrink: 0;
        }

        .header h1 {
            font-size: 1.2rem;
        }

        .status {
            gap: 0.5rem;
            font-size: 0.85rem;
        }

        /* MOBILE LOGIN FORM */
        .login-form {
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 1rem;
            gap: 1rem;
            justify-content: flex-start;
            padding-top: 2rem;
            overflow-y: auto;
            -webkit-overflow-scrolling: touch;
            height: 100%;
            box-sizing: border-box;
            /* Ensure content is accessible when keyboard appears */
            padding-bottom: calc(2rem + env(keyboard-inset-height, 0px));
        }

        /* Create a form content container to constrain all elements to same width */
        .login-form > * {
            width: 90% !important;
            max-width: 300px !important;
        }

        .login-form h2 {
            font-size: 1.5rem;
            margin-bottom: 0.5rem;
            flex-shrink: 0;
            color: white;
            text-align: center;
        }

        .login-form input {
            font-size: 16px; /* Prevent zoom on iOS */
            flex-shrink: 0;
            padding: 1rem 1.5rem;
            border: 2px solid var(--border-color);
            border-radius: 50px;
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

        .selected-emoji {
            font-size: 4rem !important;
            width: 80px !important;
            height: 80px !important;
            margin-bottom: 1rem !important;
            flex-shrink: 0;
            align-self: center;
        }

        .emoji-scroll-container {
            height: 150px;
            width: 100%;
            flex-shrink: 0;
        }

        .emoji-picker {
            flex-shrink: 0;
            display: flex;
            flex-direction: column;
            align-items: center;
        }

        .auth-options {
            gap: 12px;
            margin-top: 15px;
            margin-bottom: 2rem;
            flex-shrink: 0;
            display: flex;
            flex-direction: column;
        }

        /* MOBILE CHAT SCREEN - COMPLETE REDESIGN */
        #chat-screen {
            flex-direction: column;
            height: 100%;
        }

        /* MOBILE SIDEBAR - COMPACT TOP SECTION */
        .sidebar {
            width: 100%;
            height: auto;
            max-height: 150px;
            padding: 0.75rem;
            border-right: none;
            border-bottom: 1px solid var(--border-color);
            overflow: visible;
            flex-shrink: 0;
        }

        .sidebar-top {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 0.5rem;
            margin-bottom: 0.5rem;
        }

        .user-info {
            padding: 0.75rem;
            margin-bottom: 0;
            height: auto;
            min-height: 50px;
        }

        .user-avatar {
            font-size: 1.2rem;
        }

        .rooms-section-header {
            padding: 0.75rem;
            margin-bottom: 0;
            height: auto;
            min-height: 50px;
            grid-column: 2;
        }

        .rooms-section-header h3 {
            font-size: 0.9rem;
            margin: 0;
        }

        .rooms-section-header button {
            width: 24px;
            height: 24px;
            font-size: 1rem;
        }

        .rooms-section {
            grid-column: 1 / -1;
        }

        .rooms-list-container {
            max-height: 80px;
            overflow-y: auto;
        }

        .rooms-list {
            display: flex;
            flex-wrap: wrap;
            gap: 0.25rem;
        }

        .room-item {
            padding: 0.4rem 0.8rem;
            margin-bottom: 0;
            font-size: 0.85rem;
            white-space: nowrap;
            flex-shrink: 0;
        }

        /* MOBILE CHAT AREA - FILLS REMAINING SPACE */
        .chat-area {
            flex: 1;
            display: flex;
            flex-direction: column;
            min-height: 0;
            overflow: hidden;
        }

        /* MOBILE CHAT HEADER - STATIC */
        .chat-header {
            padding: 0.75rem;
            flex-shrink: 0;
            background: var(--bg-secondary);
            border-bottom: 1px solid var(--border-color);
            position: relative;
            z-index: 10;
        }

        .chat-header h3 {
            font-size: 1rem;
            margin: 0;
        }

        .room-actions {
            gap: 6px;
        }

        .room-actions .room-info-mobile {
            gap: 6px;
        }

        .room-actions button {
            padding: 0.4rem 0.8rem;
            font-size: 0.8rem;
            border-radius: 4px;
        }

        /* MOBILE MESSAGES - SCROLLABLE MIDDLE SECTION */
        .messages-container {
            flex: 1;
            overflow-y: auto;
            padding: 1rem;
            padding-bottom: calc(90px + env(safe-area-inset-bottom, 0px));
            display: flex;
            flex-direction: column;
            gap: 0.75rem;
            -webkit-overflow-scrolling: touch;
            min-height: 0;
        }

        /* MOBILE MESSAGE INPUT - FIXED TO BOTTOM */
        .message-input-container {
            position: fixed;
            bottom: 0;
            left: 0;
            right: 0;
            padding: 1rem;
            padding-bottom: calc(1rem + env(safe-area-inset-bottom, 0px));
            background: var(--bg-secondary);
            border-top: 1px solid var(--border-color);
            display: flex;
            gap: 0.75rem;
            align-items: center;
            z-index: 1000;
            box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.1);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
        }

        .message-input-container input {
            flex: 1;
            padding: 0.75rem 1rem;
            border: 1px solid var(--border-color);
            border-radius: 25px;
            font-size: 16px; /* Prevent zoom on iOS */
            background-color: var(--input-bg);
            color: var(--input-text);
            min-height: 44px;
        }

        .message-input-container button {
            padding: 0.75rem 1.2rem;
            background: var(--accent-color);
            color: white;
            border: none;
            border-radius: 25px;
            font-size: 0.9rem;
            min-height: 44px;
            min-width: 60px;
        }

        .circle-attachment-btn {
            width: 44px;
            height: 44px;
            font-size: 1.2rem;
        }

        /* HIDE INVITE BUTTON ON MOBILE */
        .invite-section {
            display: none;
        }

        /* MODAL ADJUSTMENTS FOR MOBILE */
        .modal-content {
            width: 90%;
            max-width: none;
            margin: 1rem;
        }
    }

    /* TINY MOBILE SCREENS */
    @media (max-width: 375px) {
        .header {
            flex-direction: column;
            align-items: flex-start;
            gap: 0.5rem;
            padding: 0.75rem;
        }

        .status {
            width: 100%;
            justify-content: space-between;
        }

        .sidebar {
            max-height: 120px;
            padding: 0.5rem;
        }

        .messages-container {
            padding-bottom: calc(100px + env(safe-area-inset-bottom, 0px));
        }

        .room-actions button {
            padding: 0.3rem 0.6rem;
            font-size: 0.75rem;
        }
    }

    /* MESSAGE BUBBLE STYLES */
    .message {
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
        transition: opacity 1s ease-out, transform 0.5s ease-out;
    }

    .message.system.expiring {
        opacity: 0;
        transform: translateY(-10px);
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

    /* MODAL STYLES */
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
        backdrop-filter: blur(10px);
        -webkit-backdrop-filter: blur(10px);
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
        background-color: var(--input-bg);
        color: var(--input-text);
    }

    .modal-content input:focus {
        outline: none;
        border-color: var(--accent-color);
        box-shadow: 0 0 0 2px rgba(0, 122, 255, 0.1);
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
        transition: background 0.3s ease;
    }

    .modal-actions button:first-child {
        background: var(--accent-color);
        color: white;
    }

    .modal-actions button:first-child:hover {
        background: var(--accent-color-hover);
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
        transition: background 0.3s ease;
    }

    .invite-link-container button:hover {
        background: var(--accent-color-hover);
    }

    /* EMOJI PICKER STYLES */
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
        -webkit-backdrop-filter: blur(10px);
        padding: 15px;
        box-sizing: content-box;
    }

    .selected-emoji:hover {
        transform: scale(1.05);
    }

    .emoji-scroll-container {
        width: 100%;
        max-width: 400px;
        height: 240px;
        background: rgba(42, 42, 42, 0.8);
        border-radius: 12px;
        padding: 10px;
        overflow-y: auto;
        overflow-x: hidden;
        scrollbar-width: thin;
        scrollbar-color: rgba(255,255,255,0.3) transparent;
        box-sizing: border-box;
        margin: 0 auto;
        backdrop-filter: blur(10px);
        -webkit-backdrop-filter: blur(10px);
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
        display: grid;
        grid-template-columns: repeat(6, 1fr);
        gap: 8px;
        width: 100%;
        padding: 0;
        margin: 0;
        height: auto;
    }

    .emoji-option {
        font-size: 1.8rem;
        width: 100%;
        height: 40px;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        border-radius: 6px;
        transition: all 0.2s ease;
        box-sizing: border-box;
        margin: 0;
        padding: 0;
    }

    .emoji-option:hover {
        transform: scale(1.1);
        background-color: rgba(255,255,255,0.1);
    }

    .emoji-option.selected {
        background-color: rgba(66, 153, 225, 0.8);
        transform: scale(1.05);
    }

    /* AUTH OPTIONS */
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

    /* FILE UPLOAD STYLES */
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
        flex-shrink: 0;
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
        transition: background 0.3s ease;
        flex-shrink: 0;
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

    /* MESSAGE ATTACHMENT STYLES */
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
    }

    .message-attachment-file {
        display: flex;
        align-items: center;
        gap: 1rem;
        padding: 1rem;
        text-decoration: none;
        color: var(--text-primary);
        transition: background 0.2s ease;
        width: 100%;
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

    /* ERROR MESSAGE STYLES */
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

    /* INVITE SECTION */
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

    #invite-btn {
        display: none !important;
    }

    /* ADMIN/USER PERMISSIONS */
    body.user #clear-history-btn,
    body.user #remove-room-btn {
        display: none !important;
    }

    body.admin #clear-history-btn,
    body.admin #remove-room-btn {
        display: inline-block;
    }

    /* MOBILE FILE UPLOAD ADJUSTMENTS */
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

        .modal-content {
            width: 90%;
            max-width: none;
            margin: 1rem;
            padding: 1.5rem;
        }

        .auth-options {
            max-width: 90%;
        }

        .selected-emoji {
            font-size: 4rem !important;
            width: 80px !important;
            height: 80px !important;
            margin-bottom: 1rem !important;
        }

        .emoji-scroll-container {
            height: 150px;
            width: 100%;
            max-width: 300px;
            flex-shrink: 0;
        }

        .emoji-picker {
            flex-shrink: 0;
            width: 90%;
            max-width: 300px;
            display: flex;
            flex-direction: column;
            align-items: center;
        }
    }

    /* FORCE CONSISTENT WIDTHS ON MOBILE - OVERRIDE ALL DESKTOP STYLES */
    @media (max-width: 768px) {
        .login-form > *,
        .login-form .emoji-picker,
        .login-form .auth-options,
        .login-form input {
            width: 90% !important;
            max-width: 300px !important;
        }
        
        .login-form .emoji-scroll-container {
            width: 100% !important;
            max-width: 100% !important;
        }
        
        .login-form .auth-options button {
            width: 100% !important;
            max-width: 100% !important;
        }
    }

    /* GLOBAL SCROLLBAR STYLING */
    /* Light mode scrollbars */
    ::-webkit-scrollbar {
        width: 8px;
        height: 8px;
        -webkit-appearance: none;
        appearance: none;
    }

    ::-webkit-scrollbar-track {
        background: rgba(0, 0, 0, 0.05);
        border-radius: 4px;
        -webkit-appearance: none;
        appearance: none;
    }

    ::-webkit-scrollbar-thumb {
        background: rgba(0, 0, 0, 0.2);
        border-radius: 4px;
        transition: background 0.3s ease;
        -webkit-appearance: none;
        appearance: none;
        border: none;
    }

    ::-webkit-scrollbar-thumb:hover {
        background: rgba(0, 0, 0, 0.4);
    }

    ::-webkit-scrollbar-corner {
        background: transparent;
        -webkit-appearance: none;
        appearance: none;
    }

    /* Dark mode scrollbars */
    @media (prefers-color-scheme: dark) {
        ::-webkit-scrollbar-track {
            background: rgba(255, 255, 255, 0.05);
        }

        ::-webkit-scrollbar-thumb {
            background: rgba(255, 255, 255, 0.2);
        }

        ::-webkit-scrollbar-thumb:hover {
            background: rgba(255, 255, 255, 0.4);
        }
    }

    /* Safari-specific scrollbar force styling */
    html {
        overflow-x: hidden;
    }

    /* Force scrollbar styling on all scrollable containers */
    .messages-container,
    .sidebar,
    .rooms-list-container,
    .emoji-scroll-container,
    .file-preview-container,
    .modal-content {
        scrollbar-width: thin;
        -webkit-overflow-scrolling: touch;
    }

    .messages-container::-webkit-scrollbar,
    .sidebar::-webkit-scrollbar,
    .rooms-list-container::-webkit-scrollbar,
    .file-preview-container::-webkit-scrollbar {
        width: 8px;
        -webkit-appearance: none !important;
        appearance: none !important;
    }

    .messages-container::-webkit-scrollbar-track,
    .sidebar::-webkit-scrollbar-track,
    .rooms-list-container::-webkit-scrollbar-track,
    .file-preview-container::-webkit-scrollbar-track {
        background: var(--bg-primary);
        border-radius: 4px;
        -webkit-appearance: none !important;
        appearance: none !important;
    }

    .messages-container::-webkit-scrollbar-thumb,
    .sidebar::-webkit-scrollbar-thumb,
    .rooms-list-container::-webkit-scrollbar-thumb,
    .file-preview-container::-webkit-scrollbar-thumb {
        background: var(--border-color);
        border-radius: 4px;
        -webkit-appearance: none !important;
        appearance: none !important;
        border: none;
    }

    .messages-container::-webkit-scrollbar-thumb:hover,
    .sidebar::-webkit-scrollbar-thumb:hover,
    .rooms-list-container::-webkit-scrollbar-thumb:hover,
    .file-preview-container::-webkit-scrollbar-thumb:hover {
        background: var(--text-secondary);
    }

    /* Firefox scrollbar styling */
    * {
        scrollbar-width: thin;
        scrollbar-color: var(--border-color) var(--bg-primary);
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
            this.previousRoomId = null; // Track previous room for reconnection
            this.rooms = [];
            this.messages = [];
            this.messagesByRoom = {}; // Store messages by room ID to prevent loss
            this.isConnected = false;
            this.isReconnecting = false; // Flag to distinguish reconnection from initial connection
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
                
                // Send join message with reconnection flag
                this.sendToServer({
                    type: 'join',
                    username: this.username,
                    emoji: this.userEmoji,
                    isReconnecting: this.isReconnecting
                });
                
                // DON'T auto-join Lobby on reconnection if user was in a different room
                // Only auto-join Lobby for initial connection without a previous room
                if (!this.isReconnecting || !this.previousRoomId) {
                    // This will be handled when we receive the roomList from server
                    // We'll join the appropriate room after getting the room list
                }
            };
            
            this.ws.onmessage = (event) => {
                const message = JSON.parse(event.data);
                this.handleServerMessage(message);
            };
            
            this.ws.onclose = () => {
                console.log('Disconnected from server');
                this.isConnected = false;
                this.isReconnecting = true; // Set flag for reconnection
                this.updateConnectionStatus();
                
                // Save current room and messages before disconnection
                if (this.currentRoom) {
                    this.previousRoomId = this.currentRoom.id;
                    this.messagesByRoom[this.currentRoom.id] = [...this.messages]; // Save current messages
                    
                    // Disable UI but DON'T clear room state or messages
                    document.getElementById('leave-room-btn').disabled = true;
                    document.getElementById('clear-history-btn').disabled = true;
                    document.getElementById('message-input').disabled = true;
                    document.getElementById('send-btn').disabled = true;
                    document.getElementById('invite-btn').disabled = true;
                    document.getElementById('file-btn').disabled = true;
                }
                
                // Attempt to reconnect after 3 seconds
                setTimeout(() => {
                    if (!this.isConnected) {
                        console.log('Attempting to reconnect...');
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
                    
                    // Handle room joining after receiving room list
                    if (this.isReconnecting && this.previousRoomId) {
                        // Try to rejoin the previous room
                        const previousRoom = this.rooms.find(r => r.id === this.previousRoomId);
                        if (previousRoom) {
                            console.log('Rejoining previous room:', previousRoom.name);
                            this.joinRoom(previousRoom.id);
                        } else {
                            // Previous room no longer exists, join Lobby
                            console.log('Previous room no longer exists, joining Lobby');
                            const lobbyRoom = this.rooms.find(r => r.name === 'Lobby');
                            if (lobbyRoom) {
                                this.joinRoom(lobbyRoom.id);
                            }
                        }
                        this.isReconnecting = false; // Reset reconnection flag
                    } else if (!this.currentRoom) {
                        // Initial connection without previous room, join Lobby
                        const lobbyRoom = this.rooms.find(r => r.name === 'Lobby');
                        if (lobbyRoom) {
                            this.joinRoom(lobbyRoom.id);
                        }
                    }
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
                    const wasReconnectingToSameRoom = this.isReconnecting && 
                                                      this.currentRoom && 
                                                      this.currentRoom.id === message.room.id;
                    
                    this.currentRoom = message.room;
                    this.updateRoomsList();
                    document.getElementById('current-room-name').textContent = message.room.name;
                    document.getElementById('leave-room-btn').disabled = false;
                    document.getElementById('clear-history-btn').disabled = false;
                    document.getElementById('message-input').disabled = false;
                    document.getElementById('send-btn').disabled = false;
                    document.getElementById('invite-btn').disabled = false;
                    document.getElementById('file-btn').disabled = false;

                    // Handle message history properly
                    if (wasReconnectingToSameRoom) {
                        console.log('Reconnecting to same room, preserving existing messages');
                        // Keep existing messages, server will send any new ones we missed
                    } else {
                        // Save current messages before switching rooms
                        if (this.currentRoom && this.messages.length > 0) {
                            const previousRoomId = this.currentRoom.id;
                            this.messagesByRoom[previousRoomId] = [...this.messages];
                        }
                        
                        // For new room or initial join, clear messages and wait for server history
                        this.messages = [];
                        
                        // If we have cached messages for this room, restore them
                        // Server will send fresh history which will be merged with these
                        if (this.messagesByRoom[message.room.id]) {
                            console.log('Restoring cached messages for room:', message.room.name);
                            this.messages = [...this.messagesByRoom[message.room.id]];
                        }
                    }
                    
                    this.updateMessagesDisplay();

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
                                removeBtn.textContent = 'Remove';
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
                    if (message.room.name === 'Lobby' && !wasReconnectingToSameRoom) {
                        this.showTemporarySystemMessage('You are now in the Lobby.', 10000);
                    }
                    
                    // Handle admin status
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
            
            // Connect to server (this will NOT be a reconnection for initial login)
            this.isReconnecting = false;
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
            
            // Save current room messages before switching
            if (this.currentRoom && this.currentRoom.id !== roomId) {
                this.messagesByRoom[this.currentRoom.id] = [...this.messages];
            }
            
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
                        removeBtn.textContent = 'Remove';
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
            
            // Load saved messages for this room or clear if none exist
            if (this.messagesByRoom[roomId]) {
                this.messages = [...this.messagesByRoom[roomId]];
            } else {
                this.messages = [];
            }
            this.updateMessagesDisplay();
            
            // Update room selection
            document.querySelectorAll('.room-item').forEach(item => {
                item.classList.remove('active');
            });
            document.querySelector(`[data-room-id="${roomId}"]`).classList.add('active');
            
            // Send join room message to server
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
            
            console.log('📤 Uploading file:', file.name, 'Size:', file.size, 'Type:', file.type);
            console.log('📤 FormData entries:');
            for (let [key, value] of formData.entries()) {
                console.log(`  ${key}:`, value);
            }
            
            try {
                const response = await fetch('/upload', {
                    method: 'POST',
                    body: formData
                    // Note: Don't set Content-Type header manually - let browser set it with boundary
                });
                
                console.log('📤 Response status:', response.status);
                console.log('📤 Response headers:', response.headers);
                
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
            // Check for duplicate messages to prevent repeats on reconnection
            const isDuplicate = this.messages.some(existingMessage => {
                return existingMessage.content === message.content &&
                       existingMessage.sender === message.sender &&
                       existingMessage.timestamp === message.timestamp &&
                       existingMessage.type === message.type;
            });
            
            if (!isDuplicate) {
                this.messages.push(message);
                
                // Save to room-specific storage immediately
                if (this.currentRoom) {
                    this.messagesByRoom[this.currentRoom.id] = [...this.messages];
                }
                
                this.updateMessagesDisplay();
            }
        }
        
        addSystemMessage(content) {
            // Check for duplicate system messages
            const isDuplicate = this.messages.some(existingMessage => {
                return existingMessage.content === content &&
                       existingMessage.type === 'system';
            });
            
            if (!isDuplicate) {
                const message = {
                    type: 'system',
                    content: content,
                    timestamp: new Date().toISOString(),
                    isExpiring: this.username !== ADMIN_USERNAME // Only expire for non-admin users
                };
                this.addMessage(message);
                
                // Auto-remove system messages after 10 seconds for non-admin users
                if (this.username !== ADMIN_USERNAME) {
                    setTimeout(() => {
                        this.removeSystemMessage(message);
                    }, 10000);
                }
            }
        }
        
        removeSystemMessage(messageToRemove) {
            // Find the DOM element for this system message
            const messageElements = document.querySelectorAll('.message.system');
            let targetElement = null;
            
            for (let element of messageElements) {
                if (element.textContent === messageToRemove.content) {
                    targetElement = element;
                    break;
                }
            }
            
            // Animate out the DOM element first
            if (targetElement) {
                targetElement.classList.add('expiring');
                setTimeout(() => {
                    if (targetElement.parentNode) {
                        targetElement.remove();
                    }
                }, 1000); // Match CSS transition duration
            }
            
            // Remove from messages array
            const index = this.messages.findIndex(msg => 
                msg.type === 'system' && 
                msg.content === messageToRemove.content && 
                msg.timestamp === messageToRemove.timestamp
            );
            
            if (index !== -1) {
                this.messages.splice(index, 1);
                
                // Update room-specific storage
                if (this.currentRoom) {
                    this.messagesByRoom[this.currentRoom.id] = [...this.messages];
                }
                
                // Update display after a short delay to allow animation
                setTimeout(() => {
                    this.updateMessagesDisplay();
                }, 1100);
            }
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
                            <span class="username">${message.sender}</span>
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

            // Only auto-remove for non-admin users
            if (this.username !== ADMIN_USERNAME) {
                setTimeout(() => {
                    msg.style.transition = 'opacity 1s';
                    msg.style.opacity = 0;
                    setTimeout(() => {
                        if (msg.parentNode) {
                            msg.remove();
                        }
                    }, 1000);
                }, durationMs);
            }
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
        
        // Mobile keyboard handling for login form
        const usernameInput = document.getElementById('username-input');
        if (usernameInput) {
            usernameInput.addEventListener('focus', () => {
                // On mobile, scroll to ensure auth buttons are visible when keyboard appears
                if (window.innerWidth <= 768) {
                    setTimeout(() => {
                        const authOptions = document.querySelector('.auth-options');
                        if (authOptions) {
                            authOptions.scrollIntoView({ 
                                behavior: 'smooth', 
                                block: 'end',
                                inline: 'nearest'
                            });
                        }
                    }, 300); // Delay to allow keyboard to appear
                }
            });
        }
        
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
