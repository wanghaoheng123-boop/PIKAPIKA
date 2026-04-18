// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PikaAI",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "PikaAI", targets: ["PikaAI"])
    ],
    dependencies: [
        .package(path: "../PikaCore")
    ],
    targets: [
        .target(
            name: "PikaAI",
            dependencies: ["PikaCore"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "PikaAITests",
            dependencies: ["PikaAI", "PikaCore"]
        )
    ]
)
