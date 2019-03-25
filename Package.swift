// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "MachKit",
    products: [
        .executable(
            name: "MemoryTool",
            targets: ["MemoryTool"]
        ),
        .library(
            name: "MachKit",
            targets: ["MachKit"]
        )
    ],
    dependencies: [
        .package(path: "../CommandLineKit"),
        .package(path: "../LoggerKit"),
        .package(path: "../FoundationKit")
    ],
    targets: [
        .target(
            name: "MemoryTool",
            dependencies: ["MachKit", "LoggerKit", "CommandLineKit"],
            path: "MemoryTool"
        ),
        .target(
            name: "MachKit",
            dependencies: ["MachAttach", "FoundationKit"],
            path: "MachKit"
        ),
        .target(
            name: "MachAttach",
            path: "MachAttach"
        )
    ]
)
