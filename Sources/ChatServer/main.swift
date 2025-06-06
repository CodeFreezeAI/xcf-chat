import Foundation
import MultiPeerChatCore
import DogTagKit

var globalRpId = "chat.xcf.ai"
if let rpArgIndex = CommandLine.arguments.firstIndex(of: "--rp-id"), CommandLine.arguments.count > rpArgIndex + 1 {
    globalRpId = CommandLine.arguments[rpArgIndex + 1]
}

var adminUsername = "XCF Admin"
if let adminArgIndex = CommandLine.arguments.firstIndex(of: "--admin"), CommandLine.arguments.count > adminArgIndex + 1 {
    adminUsername = CommandLine.arguments[adminArgIndex + 1]
}

// Expand tilde in database path
let dbPath = "~/webauthn/credentials.sqlite"
let expandedDbPath = NSString(string: dbPath).expandingTildeInPath

// Create database directory if it doesn't exist
let dbDirectory = (expandedDbPath as NSString).deletingLastPathComponent
do {
    try FileManager.default.createDirectory(atPath: dbDirectory, withIntermediateDirectories: true, attributes: nil)
    print("📁 WebAuthn database directory: \(dbDirectory)")
    print("🗄️ WebAuthn database file: \(expandedDbPath)")
} catch {
    print("⚠️ Warning: Could not create database directory: \(error)")
    print("📁 Attempted directory: \(dbDirectory)")
}

// Pass rpId and adminUsername to WebChatServer
let server = WebChatServer(
    rpId: globalRpId,
    adminUsername: adminUsername,
    storageBackend: WebAuthnStorageBackend.swiftData(expandedDbPath))

print("🌐 💬 \(globalRpId) Web Server")
print("============================")
print("")

// Require port from command line arguments
guard CommandLine.arguments.count > 1, let port = UInt16(CommandLine.arguments[1]) else {
    print("❌ Error: Port number required")
    print("Usage: ChatServer <port> [--rp-id <domain>] [--admin <username>]")
    print("Example: ChatServer 8081")
    print("Example: ChatServer 8081 --rp-id chat.example.com --admin \"My Admin\"")
    exit(1)
}

print("🚀 Starting server on port \(port)...")
server.start(on: port)

// Wait a moment for server to start
Thread.sleep(forTimeInterval: 1.0)

print("✅ Server is running!")
print("🌍 Open your browser and go to: http://\(globalRpId):\(port)")
print("📱 Or access from other devices on your network")
print("")
print("💡 Commands:")
print("   'status' - Show server status")
print("   'quit' or 'exit' - Stop the server")
print("")

// Simple command loop
var isRunning = true
var chatServerStartTime = Date()
while isRunning {
    print("> ", terminator: "")
    
    guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
        continue
    }
    
    switch input {
    case "status", "s":
        showStatus(server)
    case "quit", "exit", "q":
        print("🛑 Stopping server...")
        server.stop()
        isRunning = false
    case "help", "h":
        showHelp()
    case "":
        continue
    default:
        print("❌ Unknown command. Type 'help' for available commands.")
    }
}

print("👋 Server stopped. Goodbye!")

func showStatus(_ server: WebChatServer) {
    print("")
    print("📊 Server Status:")
    // Placeholder: show at least 1 room (Lobby)
    let totalRooms = max(server.totalRooms, 1)
    // Show connected users (actual value)
    let connectedUsers = server.connectedUsers
    // Show running status and port
    let runningStatus = server.isRunning ? "Yes (port \(port))" : "No"
    // Chat server uptime
    let chatUptime = getChatServerUptime()
    // System uptime
    let systemUptime = getSystemUptime()
    print("   👥 Connected Users: \(connectedUsers)")
    print("   🏠 Total Rooms: \(totalRooms)")
    print("   🌐 Server Running: \(runningStatus)")
    print("   🕐 Chat Uptime: \(chatUptime)")
    print("   🖥️  System Uptime: \(systemUptime)")
    print("")
}

func showHelp() {
    print("")
    print("📋 Available Commands:")
    print("   status, s    - Show server status")
    print("   help, h      - Show this help")
    print("   quit, q      - Stop the server")
    print("   exit         - Stop the server")
    print("")
}

func getChatServerUptime() -> String {
    let interval = Date().timeIntervalSince(chatServerStartTime)
    let hours = Int(interval) / 3600
    let minutes = Int(interval) % 3600 / 60
    let seconds = Int(interval) % 60
    if hours > 0 {
        return String(format: "%dh %dm %ds", hours, minutes, seconds)
    } else if minutes > 0 {
        return String(format: "%dm %ds", minutes, seconds)
    } else {
        return String(format: "%ds", seconds)
    }
}

func getSystemUptime() -> String {
    let uptime = ProcessInfo.processInfo.systemUptime
    let hours = Int(uptime) / 3600
    let minutes = Int(uptime) % 3600 / 60
    let seconds = Int(uptime) % 60
    if hours > 0 {
        return String(format: "%dh %dm %ds", hours, minutes, seconds)
    } else if minutes > 0 {
        return String(format: "%dm %ds", minutes, seconds)
    } else {
        return String(format: "%ds", seconds)
    }
} 
