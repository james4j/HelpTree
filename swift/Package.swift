// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HelpTree",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "HelpTree", targets: ["HelpTree"]),
        .executable(name: "Basic", targets: ["Basic"]),
        .executable(name: "Deep", targets: ["Deep"]),
        .executable(name: "Hidden", targets: ["Hidden"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "HelpTree",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .executableTarget(
            name: "Basic",
            dependencies: ["HelpTree"],
            path: "Examples/Basic"
        ),
        .executableTarget(
            name: "Deep",
            dependencies: ["HelpTree"],
            path: "Examples/Deep"
        ),
        .executableTarget(
            name: "Hidden",
            dependencies: ["HelpTree"],
            path: "Examples/Hidden"
        ),
    ]
)
