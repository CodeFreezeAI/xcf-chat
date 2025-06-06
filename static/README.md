# Static Web Content

This directory contains the external HTML, CSS, and JavaScript files that are served by the Swift chat server.

## Files

- **`index.html`** - Main HTML structure for the chat application
- **`stylev009.css`** - Complete CSS styling including mobile-responsive design
- **`chatv009.js`** - JavaScript functionality for chat client, WebAuthn, and UI interactions

## How It Works

The Swift files in `Sources/MultiPeerChatCore/` have been refactored to read from these external files:

1. **WebContentHTML.swift** - Attempts to read `static/index.html`, falls back to basic HTML if not found
2. **WebContentCSS.swift** - Attempts to read `static/stylev009.css`, falls back to basic CSS if not found  
3. **WebContentJS.swift** - Attempts to read `static/chatv009.js`, falls back to basic JS if not found

## Benefits

- **Easier Development**: Edit HTML/CSS/JS without recompiling Swift
- **Better Separation**: Web content is separate from Swift server logic
- **Version Control**: Easier to track changes to web content
- **Faster Iteration**: No need to rebuild the entire Swift project for web changes

## Editing

You can now directly edit these files to modify the chat interface. The Swift server will automatically serve the updated content on the next request.

**Note**: If these files are missing or unreadable, the Swift functions will fall back to basic content to ensure the application still works. 