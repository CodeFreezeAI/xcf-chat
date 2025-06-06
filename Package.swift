// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MultiPeerChat",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "ChatServer",
            targets: ["ChatServer"]
        ),
        .library(
            name: "MultiPeerChatCore",
            targets: ["MultiPeerChatCore"]
        ),
        .library(
            name: "DogTagKit",
            targets: ["DogTagKit"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ChatServer",
            dependencies: [
                "MultiPeerChatCore"
            ]
        ),
        .target(
            name: "MultiPeerChatCore",
            dependencies: ["DogTagKit"]
        ),
        .target(
            name: "DogTagKit",
            dependencies: []
        ),
        .testTarget(
            name: "MultiPeerChatTests",
            dependencies: ["MultiPeerChatCore"]
        ),
        .testTarget(
            name: "DogTagKitTests",
            dependencies: ["DogTagKit"]
        )
    ]
) 