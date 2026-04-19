// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PikaSync",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "PikaSync", targets: ["PikaSync"])
    ],
    dependencies: [
        .package(path: "../PikaCore")
    ],
    targets: [
        .target(
            name: "PikaSync",
            dependencies: ["PikaCore"]
        ),
        .testTarget(
            name: "PikaSyncTests",
            dependencies: ["PikaSync", "PikaCore"]
        )
    ]
)
