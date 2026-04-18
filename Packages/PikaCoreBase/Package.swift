// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PikaCoreBase",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "PikaCoreBase", targets: ["PikaCoreBase"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PikaCoreBase",
            dependencies: [],
            path: "Sources/PikaCoreBase",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "PikaCoreTests",
            dependencies: ["PikaCoreBase"],
            path: "Tests/PikaCoreTests"
        )
    ]
)
