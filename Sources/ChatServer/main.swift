import Foundation
import MultiPeerChatCore

let server = WebChatServer()

print("🌐 💬 chat.XCF.ai Web Server")
print("============================")
print("")

// Require port from command line arguments
guard CommandLine.arguments.count > 1, let port = UInt16(CommandLine.arguments[1]) else {
    print("❌ Error: Port number required")
    print("Usage: ChatServer <port>")
    print("Example: ChatServer 8081")
    exit(1)
}

print("🚀 Starting server on port \(port)...")
server.start(on: port)

// Wait a moment for server to start
Thread.sleep(forTimeInterval: 1.0)

print("✅ Server is running!")
print("🌍 Open your browser and go to: http://localhost:\(port)")
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
