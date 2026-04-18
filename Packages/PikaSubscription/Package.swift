// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PikaSubscription",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "PikaSubscription", targets: ["PikaSubscription"])
    ],
    dependencies: [
        .package(path: "../PikaCore")
    ],
    targets: [
        .target(
            name: "PikaSubscription",
            dependencies: ["PikaCore"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "PikaSubscriptionTests",
            dependencies: ["PikaSubscription"]
        )
    ]
)
