// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacMeter",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MacMeter",
            targets: ["MacMeter"]
        )
    ],
    dependencies: [
        // Add any external dependencies here
    ],
    targets: [
        .executableTarget(
            name: "MacMeter",
            dependencies: [],
            path: ".",
            sources: [
                "MacMeterApp.swift",
                "Models/",
                "Managers/",
                "Views/",
                "Extensions/",
                "Utils/"
            ],
            resources: [
                .process("Resources/"),
                .process("Views/Widgets/"),
                .process("icon.png")
            ]
        )
    ]
)



