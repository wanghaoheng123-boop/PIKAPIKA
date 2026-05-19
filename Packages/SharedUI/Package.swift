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
        .package(path: "../PikaCore"),
        .package(path: "../PikaCoreBase")
    ],
    targets: [
        .target(
            name: "SharedUI",
            dependencies: [
                "PikaCore",
                .product(name: "PikaCoreBase", package: "PikaCoreBase")
            ]
        ),
        .testTarget(
            name: "SharedUITests",
            dependencies: [
                "SharedUI",
                "PikaCore",
                .product(name: "PikaCoreBase", package: "PikaCoreBase")
            ]
        )
    ]
)
