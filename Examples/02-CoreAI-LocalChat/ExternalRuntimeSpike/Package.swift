// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ZooFMProviderSpike",
    platforms: [
        .macOS("27.0"),
        .iOS("27.0"),
    ],
    products: [
        .library(name: "ZooFMProvider", targets: ["ZooFMProvider"]),
    ],
    dependencies: [
        // Required Apple dependency. The upstream project documents this as a local
        // checkout with an applied patch stack for hybrid bundles such as Qwen3.5.
        .package(path: "../coreai-models"),
    ],
    targets: [
        .target(
            name: "ZooFMProvider",
            dependencies: [
                .product(name: "CoreAILM", package: "coreai-models"),
            ]
        ),
    ]
)
