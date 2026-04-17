// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PikaCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "PikaCore", targets: ["PikaCore"])
    ],
    dependencies: [
        .package(path: "../PikaCoreBase")
    ],
    targets: [
        .target(
            name: "PikaCorePersistence",
            dependencies: [],
            path: "Sources/PikaCorePersistence",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "PikaCore",
            dependencies: [
                .product(name: "PikaCoreBase", package: "PikaCoreBase"),
                "PikaCorePersistence"
            ],
            path: "Sources/PikaCore",
            sources: ["PikaCore.swift"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
