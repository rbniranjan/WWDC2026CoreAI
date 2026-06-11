// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CoreAIChatCore",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "CoreAIChatCore",
            targets: ["CoreAIChatCore"]
        ),
    ],
    targets: [
        .target(
            name: "CoreAIChatCore",
            path: "CoreAIChat",
            sources: [
                "Features/Chat/ChatMessage.swift",
                "Core/ModelCatalog/ModelManifest.swift",
                "Core/ModelCatalog/ModelVariant.swift",
                "Core/ModelCatalog/ModelCatalogService.swift",
                "Core/Runtime/ChatModelRuntime.swift",
                "Core/Runtime/CoreAIChatRuntime.swift",
                "Core/Runtime/MockChatRuntime.swift",
                "Core/Runtime/RuntimeStatus.swift",
                "Core/Settings/ChatGenerationSettings.swift",
                "Core/Storage/ActiveModelStore.swift",
                "Core/Storage/LocalModelStore.swift",
                "Shared/Utilities/BundleResourceLoader.swift",
            ]
        ),
        .testTarget(
            name: "CoreAIChatTests",
            dependencies: ["CoreAIChatCore"],
            path: "Tests/CoreAIChatTests"
        ),
    ]
)
