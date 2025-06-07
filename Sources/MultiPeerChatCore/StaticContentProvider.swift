
import Foundation

// MARK: - Static Content Provider
// Provides functions to serve web content from external files with fallbacks

public func generateIndexHTML() -> String {
    // Try to read from external file first, fallback to default if not found
    let possiblePaths = [
        "static/index.html",
        "./static/index.html",
        "../../static/index.html",
        FileManager.default.currentDirectoryPath + "/static/index.html"
    ]
    
    for staticHTMLPath in possiblePaths {
        if let htmlContent = try? String(contentsOfFile: staticHTMLPath) {
            print("📄 Loaded HTML from: \(staticHTMLPath)")
            return htmlContent
        }

    }
    
    print("⚠️ Static HTML file not found, using fallback")
    return generateFallbackHTML()
}

private func generateFallbackHTML() -> String {
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no, viewport-fit=cover">
        <title>💬 chat.xcf.ai</title>
        <meta name="title" content="XCF Chat - Secure Real-time Chat">
        <meta name="description" content="Anonymous • Passwordless • Emoji Avatars • WebAuthn FIDO2 Passkey Security">
        <meta name="keywords" content="chat, real-time, secure, WebAuthn, emoji, file sharing, instant messaging, group chat, rooms">
        <meta name="author" content="XCF Chat">
        <meta name="robots" content="index, follow">
        
        <!-- Primary Meta Tags -->
        <meta property="og:type" content="website">
        <meta property="og:url" content="https:///">
        <meta property="og:title" content="XCF Chat - Secure Real-time Chat Platform">
        <meta property="og:description" content="Anonymous • Passwordless • Emoji Avatars • WebAuthn FIDO2 Passkey Security">
        
        <!-- Apple -->
        <meta name="apple-mobile-web-app-capable" content="yes">
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
        <meta name="apple-mobile-web-app-title" content="XCF Chat">
        
        <!-- Theme colors -->
        <meta name="theme-color" content="#eceff1" media="(prefers-color-scheme: light)">
        <meta name="theme-color" content="#121212" media="(prefers-color-scheme: dark)">
        
        <!-- Manifest -->
        <link rel="manifest" href="/manifest.json">
        
        <!-- Stylesheets -->
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
        <script src="/emoji.js"></script>
        <script src="/webauthn.js"></script>
        <script src="/chat.js"></script>
    </body>
    </html>
    """
}

public func generateCSS() -> String {
    // Try to read from external file first, fallback to default if not found
    let possiblePaths = [
        "static/style.css",
        "./static/style.css",
        "../../static/style.css",
        FileManager.default.currentDirectoryPath + "/static/style.css"
    ]
    
    for staticCSSPath in possiblePaths {
        if let cssContent = try? String(contentsOfFile: staticCSSPath) {
            print("🎨 Loaded CSS from: \(staticCSSPath)")
            return cssContent
        }
    }
    
    print("⚠️ Static CSS file not found, using fallback")
    return generateFallbackCSS()
}

private func generateFallbackCSS() -> String {
    return """
    /* Basic fallback CSS */
    * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
    }
    
    body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: #333;
        line-height: 1.6;
        height: 100vh;
        overflow: hidden;
    }
    
    .container {
        height: 100vh;
        display: flex;
        flex-direction: column;
    }
    
    .header {
        background: rgba(255, 255, 255, 0.95);
        padding: 1rem 2rem;
        display: flex;
        justify-content: space-between;
        align-items: center;
        box-shadow: 0 2px 20px rgba(0, 0, 0, 0.1);
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
        display: flex;
        align-items: center;
        justify-content: center;
    }
    
    .hidden {
        display: none;
    }
    
    .login-form {
        background: rgba(255, 255, 255, 0.95);
        padding: 2rem;
        border-radius: 12px;
        box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
        text-align: center;
        max-width: 400px;
        width: 90%;
    }
    
    .login-input-container {
        display: flex;
        flex-direction: column;
        gap: 1rem;
        margin-top: 1rem;
    }
    
    input[type="text"] {
        padding: 1rem;
        border: 2px solid #e2e8f0;
        border-radius: 8px;
        font-size: 1rem;
        outline: none;
        transition: border-color 0.3s ease;
    }
    
    input[type="text"]:focus {
        border-color: #007AFF;
    }
    
    .auth-options {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }
    
    button {
        padding: 0.75rem 1.5rem;
        border: none;
        border-radius: 8px;
        color: white;
        cursor: pointer;
        font-size: 1rem;
        transition: background-color 0.3s ease;
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
    """
}

public func generateChatJS() -> String {
    // Try to read from external file first, fallback to default if not found
    let possiblePaths = [
        "static/chat.js",
        "./static/chat.js",
        "../../static/chat.js",
        FileManager.default.currentDirectoryPath + "/static/chat.js"
    ]
    
    for staticJSPath in possiblePaths {
        if let jsContent = try? String(contentsOfFile: staticJSPath) {
            print("⚡ Loaded JavaScript from: \(staticJSPath)")
            return jsContent
        }
    }
    
    print("⚠️ Static JavaScript file not found, using fallback")
    return generateFallbackJS()
}

public func generateWebAuthnJS() -> String {
    // Try to read from external file first, fallback to default if not found
    let possiblePaths = [
        "static/webauthn.js",
        "./static/webauthn.js",
        "../../static/webauthn.js",
        FileManager.default.currentDirectoryPath + "/static/webauthn.js"
    ]
    
    for staticJSPath in possiblePaths {
        if let jsContent = try? String(contentsOfFile: staticJSPath) {
            print("🔐 Loaded WebAuthn JavaScript from: \(staticJSPath)")
            return jsContent
        }
    }
    
    print("⚠️ Static WebAuthn JavaScript file not found, using fallback")
    return generateFallbackWebAuthnJS()
}

private func generateFallbackWebAuthnJS() -> String {
    return """
    // Basic fallback WebAuthn JavaScript
    console.log('XCF Chat - Loading basic fallback WebAuthn JavaScript');
    
    // Placeholder WebAuthn functions
    function registerWebAuthn() {
        alert('WebAuthn registration not available - static files missing');
    }
    
    function loginWithWebAuthn() {
        alert('WebAuthn login not available - static files missing');
    }
    
    // Placeholder utility functions
    function base64ToArrayBuffer(base64) {
        console.error('WebAuthn utilities not available');
        return new ArrayBuffer(0);
    }
    
    function arrayBufferToBase64(buffer) {
        console.error('WebAuthn utilities not available');
        return '';
    }
    
    function showLoginStatus(message, type) {
        console.log('Login status:', type, message);
    }
    
    function clearLoginStatus() {
        console.log('Clear login status');
    }
    
    function setButtonState(registerBtn, loginBtn, disabled, registerText, loginText) {
        console.log('Set button state called');
    }
    
    // Initialize fallback state
    document.addEventListener('DOMContentLoaded', function() {
        window.statusTimeout = null;
        window.statusFadeTimeout = null;
        window.webauthnInProgress = false;
        
        // Show error message to user
        const loginForm = document.querySelector('.login-form');
        if (loginForm) {
            const errorMsg = document.createElement('div');
            errorMsg.style.cssText = 'background: #fee; color: #c33; padding: 1rem; border-radius: 8px; margin-top: 1rem; font-size: 0.9rem;';
            errorMsg.innerHTML = '⚠️ WebAuthn features not available - static files missing.';
            loginForm.appendChild(errorMsg);
        }
    });
    """
}

public func generateEmojiJS() -> String {
    // Try to read from external file first, fallback to default if not found
    let possiblePaths = [
        "static/emoji.js",
        "./static/emoji.js",
        "../../static/emoji.js",
        FileManager.default.currentDirectoryPath + "/static/emoji.js"
    ]
    
    for staticJSPath in possiblePaths {
        if let jsContent = try? String(contentsOfFile: staticJSPath) {
            print("😀 Loaded Emoji JavaScript from: \\(staticJSPath)")
            return jsContent
        }
    }
    
    print("⚠️ Static Emoji JavaScript file not found, using fallback")
    return generateFallbackEmojiJS()
}

private func generateFallbackEmojiJS() -> String {
    return """
    // Basic fallback Emoji JavaScript
    console.log('XCF Chat - Loading basic fallback Emoji JavaScript');
    
    // Basic emoji data
    const EMOJI_DATA = ['👤', '🐶', '🐱', '🐭', '🐹', '🐰'];
    
    function populateEmojiGrid(containerSelector, onClickHandler) {
        console.log('Emoji grid population not available - static files missing');
    }
    
    // Basic emoji functions
    function selectEmoji(emoji) {
        console.log('Select emoji:', emoji);
    }
    
    function changeUserEmoji(emoji) {
        console.log('Change user emoji:', emoji);
    }
    
    // Export basic functionality
    if (typeof window !== 'undefined') {
        window.EMOJI_DATA = EMOJI_DATA;
        window.populateEmojiGrid = populateEmojiGrid;
    }
    """
}

private func generateFallbackJS() -> String {
    return """
    // Basic fallback JavaScript for Chat Client
    console.log('XCF Chat - Loading basic fallback JavaScript for chat client');
    
    // Set hostname
    document.addEventListener('DOMContentLoaded', function() {
        document.querySelectorAll('#rp-id').forEach(function(el) {
            el.textContent = window.location.hostname;
        });
    });
    
    // Basic chat placeholder
    class ChatClient {
        constructor() {
            console.log('Basic fallback chat client initialized');
        }
        
        connect() {
            console.log('Chat connection not available - static files missing');
        }
    }
    
    // Initialize basic chat client
    let chatClient = new ChatClient();
    
    // Show error message to user
    document.addEventListener('DOMContentLoaded', function() {
        const chatScreen = document.getElementById('chat-screen');
        if (chatScreen) {
            const errorMsg = document.createElement('div');
            errorMsg.style.cssText = 'background: #fee; color: #c33; padding: 1rem; border-radius: 8px; margin: 1rem; font-size: 0.9rem;';
            errorMsg.innerHTML = '⚠️ Chat functionality not available - static files missing.';
            chatScreen.appendChild(errorMsg);
        }
    });
    """
} 
