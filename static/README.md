# Static Web Content

This directory contains the external HTML, CSS, and JavaScript files that are served by the Swift chat server.

## Files

- **`index.html`** - Main HTML structure for the chat application
- **`style.css`** - Complete CSS styling including mobile-responsive design
- **`chat.js`** - JavaScript functionality for chat client and UI interactions
- **`webauthn.js`** - WebAuthn authentication functions (passkey registration and login) with platform-specific detection for Android, Linux, macOS, Windows
- **`hybrid-webauthn.js`** - Hybrid WebAuthn client for QR code + security key testing

## How It Works

The Swift files in `Sources/MultiPeerChatCore/` have been refactored to read from these external files:

1. **StaticContentProvider.swift** - Attempts to read `static/index.html`, falls back to basic HTML if not found
2. **StaticContentProvider.swift** - Attempts to read `static/style.css`, falls back to basic CSS if not found  
3. **StaticContentProvider.swift** - Attempts to read `static/chat.js`, falls back to basic JS if not found
4. **StaticContentProvider.swift** - Attempts to read `static/webauthn.js`, falls back to basic WebAuthn JS if not found

## Benefits

- **Easier Development**: Edit HTML/CSS/JS without recompiling Swift
- **Better Separation**: Web content is separate from Swift server logic
- **Version Control**: Easier to track changes to web content
- **Faster Iteration**: No need to rebuild the entire Swift project for web changes

## Editing

You can now directly edit these files to modify the chat interface. The Swift server will automatically serve the updated content on the next request.

**Note**: If these files are missing or unreadable, the Swift functions will fall back to basic content to ensure the application still works. 