// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftTerraria",
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "SwiftTerraria",
            dependencies: [
            	.product(name: "NIOCore", package: "swift-nio"),
            	.product(name: "NIOPosix", package: "swift-nio"),
            	.product(name: "NIOExtras", package: "swift-nio-extras"),
            ]
        ),
        .testTarget(
            name: "SwiftTerrariaTests",
            dependencies: ["SwiftTerraria"]
        ),
    ]
)
