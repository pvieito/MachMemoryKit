// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "MachKit",
    products: [
        .executable(
            name: "MachMemoryTool",
            targets: ["MachMemoryTool"]
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
            name: "MachMemoryTool",
            dependencies: ["MachKit", "LoggerKit", "CommandLineKit"],
            path: "MachMemoryTool"
        ),
        .target(
            name: "MachKit",
            dependencies: ["MachAttach", "FoundationKit"],
            path: "MachKit"
        ),
        .target(
            name: "MachAttach",
            path: "MachAttach"
        ),
        .testTarget(
            name: "MachKitTests",
            dependencies: ["MachKit"]
        )
    ]
)
