// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ChatServer",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "ChatServer",
            targets: ["ChatServer"]
        )
    ],
    dependencies: [
        .package(name: "MultiPeerChatCore", path: "../MultiPeerChatCore-Package")
    ],
    targets: [
        .executableTarget(
            name: "ChatServer",
            dependencies: [.product(name: "MultiPeerChatCore", package: "MultiPeerChatCore")]
        )
    ]
) 