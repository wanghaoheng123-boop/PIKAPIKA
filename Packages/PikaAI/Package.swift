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
        // PikaCoreBase only: avoids pulling SwiftData `@Model` targets into `swift test` on CI.
        .package(path: "../PikaCoreBase")
    ],
    targets: [
        .target(
            name: "PikaAI",
            dependencies: [.product(name: "PikaCoreBase", package: "PikaCoreBase")]
        ),
        .testTarget(
            name: "PikaAITests",
            dependencies: ["PikaAI", .product(name: "PikaCoreBase", package: "PikaCoreBase")],
            // Keychain + MainActor router tests are for local Mac runs; XCTSkip in setUp is unreliable on GHA.
            exclude: ["AIProviderRouterTests.swift"]
        )
    ]
)
