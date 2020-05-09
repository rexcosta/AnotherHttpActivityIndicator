// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AnotherHttpActivityIndicator",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "AnotherHttpActivityIndicator",
            targets: ["AnotherHttpActivityIndicator"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/rexcosta/AnotherSwiftCommonLib.git",
            .branch("master")
        )
    ],
    targets: [
        .target(
            name: "AnotherHttpActivityIndicator",
            dependencies: ["AnotherSwiftCommonLib"]
        ),
        .testTarget(
            name: "AnotherHttpActivityIndicatorTests",
            dependencies: ["AnotherHttpActivityIndicator"]
        ),
    ]
)
