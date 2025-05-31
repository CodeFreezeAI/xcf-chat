#!/bin/bash

# 💬 chat.XCF.ai Example Script
# This script demonstrates how to run multiple instances of the chat client

echo "🚀 💬 chat.XCF.ai Example"
echo "============================"
echo ""
echo "This script will help you test the chat client."
echo "You'll need to run multiple terminal windows to see the full effect."
echo ""

# Build the project first
echo "📦 Building the project..."
swift build -c release

if [ $? -ne 0 ]; then
    echo "❌ Build failed. Please check for errors."
    exit 1
fi

echo "✅ Build successful!"
echo ""

echo "🎯 Usage Examples:"
echo ""
echo "1. Start a host (run this in Terminal 1):"
echo "   swift run MultiPeerChat --username \"Alice\" --port 8080"
echo ""
echo "2. Connect a client (run this in Terminal 2):"
echo "   swift run MultiPeerChat --username \"Bob\" --host localhost --connect-port 8080"
echo ""
echo "3. Auto-discover (run this in Terminal 3):"
echo "   swift run MultiPeerChat --username \"Charlie\" --discover"
echo ""
echo "4. Quick test with random port:"
echo "   swift run MultiPeerChat --username \"TestUser\""
echo ""

echo "🔧 Interactive Commands (once running):"
echo "   /create <room_name>  - Create a new room"
echo "   /join <room_name>    - Join an existing room"
echo "   /invite              - Create invite link"
echo "   /help                - Show all commands"
echo ""

read -p "Press Enter to start a test instance with username 'TestUser'..."

echo "🏃 Starting chat client..."
swift run MultiPeerChat --username "TestUser" 