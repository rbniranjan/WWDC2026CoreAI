import Foundation
import Testing
@testable import CoreAIChatCore

struct ExternalModelCatalogTests {
    @Test func externalJSONDecodes() throws {
        let catalog = try loadExternalCatalog()

        #expect(catalog.schemaVersion == 3)
        #expect(catalog.catalogId == "wwdc2026-coreai-external-model-catalog")
        #expect(catalog.models.count == 8)
    }

    @Test func qwen3VLSupportsImageUpload() throws {
        let catalog = try loadExternalCatalog()
        let model = try #require(catalog.models.first(where: { $0.id == "qwen3_vl_2b_coreai_vision_language" }))

        #expect(model.capabilities.supportsTextChat)
        #expect(model.capabilities.supportsImageUpload)
        #expect(model.capabilities.supportsImageTextToText)
    }

    @Test func registryReturnsAdapterRequiredForKnownButUnimplementedRunner() throws {
        let catalog = try loadExternalCatalog()
        let model = try #require(catalog.models.first(where: { $0.id == "qwen3_5_0_8b_coreai_pipelined" }))
        let registry = CoreAIModelRunnerRegistry.knownExternalModelRegistry()
        let bundleRootURL = try makeCompleteQwenBundle()

        let artifacts = model.artifacts.map { artifact in
            CoreAIResolvedArtifact(
                id: artifact.id,
                artifactRole: artifact.role,
                expectedDirectoryName: artifact.manualInstallDirectoryName,
                localURL: resolvedLocalURL(for: artifact, bundleRootURL: bundleRootURL),
                exists: true,
                isDirectory: artifact.role != .metadata
            )
        }

        let result = registry.preflight(
            profile: model,
            localArtifacts: artifacts,
            bundleRootURL: bundleRootURL
        )

        #expect(result.readiness == .adapterRequired)
        #expect(result.runnerName.contains("N-State"))
        #expect(result.findings.contains(where: { $0.code == "language_bundle_api_missing" }))
        #expect(result.findings.contains(where: { $0.code == "tokenizer_api_missing" }))
        #expect(result.bundleInspection?.checks.allSatisfy { $0.isSatisfied } == true)
    }

    @Test func missingArtifactPreflightWorks() throws {
        let catalog = try loadExternalCatalog()
        let model = try #require(catalog.models.first(where: { $0.id == "qwen3_5_0_8b_coreai_pipelined" }))
        let registry = CoreAIModelRunnerRegistry.knownExternalModelRegistry()

        let result = registry.preflight(profile: model, localArtifacts: [])

        #expect(result.readiness == .missingArtifacts)
        #expect(result.blockingFindings.contains(where: { $0.code == "missing_artifact" }))
    }

    @Test func qwenGeneratePathStopsAtDocumentedBlockerWithoutFakeCompletion() async throws {
        let catalog = try loadExternalCatalog()
        let model = try #require(catalog.models.first(where: { $0.id == "qwen3_5_0_8b_coreai_pipelined" }))
        let registry = CoreAIModelRunnerRegistry.knownExternalModelRegistry()
        let bundleRootURL = try makeCompleteQwenBundle()
        defer { try? FileManager.default.removeItem(at: bundleRootURL.deletingLastPathComponent()) }

        let artifacts = model.artifacts.map { artifact in
            CoreAIResolvedArtifact(
                id: artifact.id,
                artifactRole: artifact.role,
                expectedDirectoryName: artifact.manualInstallDirectoryName,
                localURL: resolvedLocalURL(for: artifact, bundleRootURL: bundleRootURL),
                exists: true,
                isDirectory: artifact.role != .metadata
            )
        }

        let request = CoreAIGenerationRequest(
            model: model,
            messages: [
                CoreAIChatTurn(role: .user, content: "Hello")
            ],
            localArtifacts: artifacts
        )

        var sawStarted = false
        var sawCompleted = false
        var diagnostics: [String] = []
        var capturedError: Error?

        do {
            for try await event in registry.generate(request: request) {
                switch event {
                case .started:
                    sawStarted = true
                case .completed:
                    sawCompleted = true
                case .diagnostic(let message):
                    diagnostics.append(message)
                default:
                    break
                }
            }
        } catch {
            capturedError = error
        }

        #expect(sawStarted)
        #expect(!sawCompleted)
        #expect(diagnostics.contains(where: { $0.hasPrefix("bundle.metadata.") }))
        #expect(diagnostics.contains(where: { $0.contains("blocker=") }))

        switch capturedError {
        case let error as CoreAIModelRunnerError:
            switch error {
            case .runtimeAPINotAvailable(let modelName, let reason):
                #expect(modelName == model.name)
                #expect(reason.contains("LanguageBundle"))
                #expect(reason.contains("tokenizer"))
            default:
                Issue.record("Unexpected runner error: \(error)")
            }
        default:
            Issue.record("Expected CoreAIModelRunnerError.runtimeAPINotAvailable")
        }
    }

    private func loadExternalCatalog() throws -> CoreAIExternalModelCatalog {
        let packageRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let catalogURL = packageRoot
            .appendingPathComponent("CoreAIChat", isDirectory: true)
            .appendingPathComponent("Resources/ModelManifest/external_coreai_model_catalog_v3.json")
        let data = try Data(contentsOf: catalogURL)
        return try CoreAIExternalModelCatalogLoader.decode(data: data)
    }

    private func makeCompleteQwenBundle() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("qwen3_5_0_8b_decode_int8hu_perchan_sym", isDirectory: true)

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: root.appendingPathComponent("metadata.json"))

        try FileManager.default.createDirectory(
            at: root.appendingPathComponent("qwen3_5_0_8b_decode_int8hu_perchan_sym.aimodel", isDirectory: true),
            withIntermediateDirectories: true
        )

        let tokenizerDirectory = root.appendingPathComponent("tokenizer", isDirectory: true)
        try FileManager.default.createDirectory(at: tokenizerDirectory, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: tokenizerDirectory.appendingPathComponent("tokenizer.json"))
        try Data("{{ prompt }}".utf8).write(to: tokenizerDirectory.appendingPathComponent("chat_template.jinja"))
        try Data("{}".utf8).write(to: tokenizerDirectory.appendingPathComponent("tokenizer_config.json"))
        try Data("{}".utf8).write(to: tokenizerDirectory.appendingPathComponent("special_tokens_map.json"))

        return root
    }

    private func resolvedLocalURL(
        for artifact: CoreAIModelArtifact,
        bundleRootURL: URL
    ) -> URL {
        let bundlePrefix = artifact.manualInstallDirectoryName + "/"
        if artifact.fileName.hasPrefix(bundlePrefix) {
            let relativePath = String(artifact.fileName.dropFirst(bundlePrefix.count))
            return bundleRootURL.appendingPathComponent(relativePath)
        }
        return bundleRootURL.appendingPathComponent(artifact.fileName)
    }
}
