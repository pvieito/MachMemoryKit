// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "MachMemoryKit",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "MachMemoryTool",
            targets: ["MachMemoryTool"]
        ),
        .library(
            name: "MachMemoryKit",
            targets: ["MachMemoryKit"]
        )
    ],
    dependencies: [
        .package(url: "git@github.com:pvieito/LoggerKit.git", branch: "master"),
        .package(url: "git@github.com:pvieito/FoundationKit.git", branch: "master"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "MachMemoryTool",
            dependencies: [
                "FoundationKit",
                "LoggerKit",
                "MachMemoryKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "MachMemoryTool"
        ),
        .target(
            name: "MachMemoryKit",
            dependencies: [
                "MachAttach",
                "FoundationKit"
            ],
            path: "MachMemoryKit"
        ),
        .target(
            name: "MachAttach",
            path: "MachAttach"
        ),
        .testTarget(
            name: "MachMemoryKitTests",
            dependencies: ["MachMemoryKit", "FoundationKit"]
        )
    ]
)
