// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SharedUI",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "SharedUI", targets: ["SharedUI"])
    ],
    dependencies: [
        .package(path: "../PikaCore")
    ],
    targets: [
        .target(
            name: "SharedUI",
            dependencies: ["PikaCore"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
