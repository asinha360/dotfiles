// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "wallsync",
    platforms: [.macOS(.v26)],
    targets: [
        .target(name: "WallsyncCore"),
        .executableTarget(
            name: "wallsync",
            dependencies: ["WallsyncCore"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(name: "WallsyncCoreTests", dependencies: ["WallsyncCore"]),
    ]
)
