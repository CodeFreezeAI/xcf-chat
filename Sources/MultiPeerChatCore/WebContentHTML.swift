import Foundation

// MARK: - HTML Content
func generateIndexHTML() -> String {
    // Try to read from external file first, fallback to default if not found
    let staticHTMLPath = "static/index.html"
    
    if let htmlContent = try? String(contentsOfFile: staticHTMLPath) {
        return htmlContent
    }
    
    // Fallback: return a basic HTML structure that references external files
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no, viewport-fit=cover">
        <title>💬 chat.xcf.ai</title>
        <link rel="stylesheet" href="/stylev008.css">
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
                <div id="login-screen" class="screen">
                    <div class="login-form">
                        <h2>Join the Chat</h2>
                        <div class="login-input-container">
                            <input type="text" id="nickname-input" placeholder="Enter your username" maxlength="20">
                            <div class="auth-options">
                                <button id="webauthn-register-btn" onclick="registerWebAuthn()">Register with Passkey</button>
                                <button id="webauthn-login-btn" onclick="loginWithWebAuthn()">Login with Passkey</button>
                            </div>
                        </div>
                    </div>
                </div>
                <div id="chat-screen" class="screen hidden">
                    <p>Loading chat interface...</p>
                </div>
            </div>
        </div>
        <script src="/chatv008.js"></script>
    </body>
    </html>
    """
}
