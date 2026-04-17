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
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "6.0.0")
    ],
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
            dependencies: [
                "PikaCoreBase",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Tests/PikaCoreTests"
        )
    ]
)
