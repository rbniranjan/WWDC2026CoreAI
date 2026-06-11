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

        let artifacts = [
            CoreAIResolvedArtifact(
                id: "language_bundle_ship",
                artifactRole: .languageBundle,
                expectedDirectoryName: "qwen3_5_0_8b_decode_int8hu_perchan_sym",
                localURL: URL(fileURLWithPath: "/tmp/language_bundle_ship"),
                exists: true,
                isDirectory: true
            ),
        ]

        let result = registry.preflight(profile: model, localArtifacts: artifacts)

        #expect(result.readiness == .adapterRequired)
        #expect(result.runnerName.contains("N-State"))
        #expect(result.findings.contains(where: { $0.code == "generation_not_implemented" }))
    }

    @Test func missingArtifactPreflightWorks() throws {
        let catalog = try loadExternalCatalog()
        let model = try #require(catalog.models.first(where: { $0.id == "qwen3_5_0_8b_coreai_pipelined" }))
        let registry = CoreAIModelRunnerRegistry.knownExternalModelRegistry()

        let result = registry.preflight(profile: model, localArtifacts: [])

        #expect(result.readiness == .missingArtifacts)
        #expect(result.blockingFindings.contains(where: { $0.code == "missing_artifact" }))
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
}
