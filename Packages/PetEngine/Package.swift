// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PetEngine",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "PetEngine", targets: ["PetEngine"])
    ],
    dependencies: [
        .package(path: "../PikaCore")
    ],
    targets: [
        .target(
            name: "PetEngine",
            dependencies: ["PikaCore"]
        ),
        .testTarget(
            name: "PetEngineTests",
            dependencies: ["PetEngine", "PikaCore"]
        )
    ]
)
