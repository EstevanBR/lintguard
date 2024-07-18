// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LintGuard",
    products: [
        .executable(
            name: "lintguard",
            targets: ["LintGuard"]
        )
    ],
    targets: [
        .executableTarget(
            name: "LintGuard"
        ),
    ]
)
