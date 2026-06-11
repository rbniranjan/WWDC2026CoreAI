import Foundation
import Testing
@testable import CoreAIChatCore

struct BundleInspectorTests {
    @Test func genericInspectorFindsCompleteBundle() throws {
        let root = try makeBundleRoot()
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        try writeCompleteQwenBundle(at: root)

        let inspector = makeGenericInspector()
        let result = inspector.inspect(profile: stubProfile(), bundleRootURL: root, fileManager: .default)

        #expect(result.checks.count == 4)
        #expect(result.checks.allSatisfy { $0.isSatisfied })
        #expect(!result.hasBlockingIssues)
    }

    @Test func genericInspectorReportsMissingTokenizer() throws {
        let root = try makeBundleRoot()
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        try writeMetadata(at: root)
        try FileManager.default.createDirectory(
            at: root.appendingPathComponent("qwen3_5_0_8b_decode_int8hu_perchan_sym.aimodel", isDirectory: true),
            withIntermediateDirectories: true
        )

        let inspector = makeGenericInspector()
        let result = inspector.inspect(profile: stubProfile(), bundleRootURL: root, fileManager: .default)

        #expect(result.missingRequiredChecks.contains(where: { $0.id == "tokenizer_directory" }))
    }

    @Test func genericInspectorReportsMissingAimodel() throws {
        let root = try makeBundleRoot()
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        try writeMetadata(at: root)
        try writeTokenizerFiles(at: root)

        let inspector = makeGenericInspector()
        let result = inspector.inspect(profile: stubProfile(), bundleRootURL: root, fileManager: .default)

        #expect(result.missingRequiredChecks.contains(where: { $0.id == "language_model_aimodel" }))
    }

    @Test func qwenInspectorMatchesExpectedStructure() throws {
        let root = try makeBundleRoot()
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        try writeCompleteQwenBundle(at: root)

        let inspector = QwenCoreAIModelBundleInspector()
        let profile = stubProfile()
        let result = inspector.inspect(profile: profile, bundleRootURL: root, fileManager: .default)

        #expect(inspector.canInspect(profile: profile))
        #expect(result.checks.count == 8)
        #expect(result.checks.allSatisfy { $0.isSatisfied })
    }

    @Test func registryStillReturnsSkeletonRunner() {
        let registry = CoreAIModelRunnerRegistry.knownExternalModelRegistry()
        let runner = registry.runner(for: stubProfile())

        #expect(runner.supportedAdapter == .coreaiPipelinedNStateText)
        #expect(runner.displayName.contains("N-State"))
    }

    private func makeGenericInspector() -> GenericCoreAIModelBundleInspector {
        GenericCoreAIModelBundleInspector(
            displayName: "Generic Test Inspector",
            matcher: { _ in true },
            expectedPaths: { _ in
                [
                    .init(id: "bundle_root", title: "Bundle root", relativePath: nil, expectedKind: .directory, required: true),
                    .init(id: "bundle_metadata", title: "metadata.json", relativePath: "metadata.json", expectedKind: .file, required: true),
                    .init(
                        id: "language_model_aimodel",
                        title: "Language model .aimodel",
                        relativePath: "qwen3_5_0_8b_decode_int8hu_perchan_sym.aimodel",
                        expectedKind: .directory,
                        required: true
                    ),
                    .init(id: "tokenizer_directory", title: "Tokenizer directory", relativePath: "tokenizer", expectedKind: .directory, required: true),
                ]
            }
        )
    }

    private func stubProfile() -> CoreAIExternalModelProfile {
        CoreAIExternalModelProfile(
            id: "qwen3_5_0_8b_coreai_pipelined",
            name: "Qwen3.5 0.8B Core AI",
            family: "qwen3.5",
            modelSeries: "Qwen3.5",
            displayCategory: "Text Chat",
            parameterScale: "0.8B",
            architecture: "text",
            license: "Apache-2.0",
            description: "stub",
            source: .init(
                provider: "stub",
                repositoryURL: URL(string: "https://example.com/repo")!,
                modelCardURL: URL(string: "https://example.com/card")!,
                upstreamModelURL: nil,
                zooCardURL: nil,
                licenseURL: nil
            ),
            capabilities: .init(
                modalities: [.text],
                inputModes: [.text],
                outputModes: [.text],
                supportsTextChat: true,
                supportsImageUpload: false,
                supportsTextToText: true,
                supportsImageToText: false,
                supportsImageTextToText: false,
                supportsTextToImage: false,
                supportsImageToImage: false,
                supportsEmbedding: false,
                supportsReranking: false,
                supportsObjectDetection: false,
                supportsStreaming: true,
                supportsRAG: false,
                supportsToolCalling: nil
            ),
            artifacts: [
                .init(
                    id: "bundle_metadata",
                    role: .metadata,
                    format: .directory,
                    repositorySubpath: nil,
                    manualInstallDirectoryName: "qwen3_5_0_8b_decode_int8hu_perchan_sym",
                    fileName: "qwen3_5_0_8b_decode_int8hu_perchan_sym/metadata.json",
                    downloadURL: nil,
                    expectedSizeBytes: nil,
                    sha256: nil,
                    required: true,
                    notes: []
                ),
                .init(
                    id: "language_model_aimodel",
                    role: .languageDecoder,
                    format: .aimodel,
                    repositorySubpath: nil,
                    manualInstallDirectoryName: "qwen3_5_0_8b_decode_int8hu_perchan_sym",
                    fileName: "qwen3_5_0_8b_decode_int8hu_perchan_sym/qwen3_5_0_8b_decode_int8hu_perchan_sym.aimodel",
                    downloadURL: nil,
                    expectedSizeBytes: nil,
                    sha256: nil,
                    required: true,
                    notes: []
                ),
                .init(
                    id: "tokenizer_directory",
                    role: .tokenizer,
                    format: .directory,
                    repositorySubpath: nil,
                    manualInstallDirectoryName: "qwen3_5_0_8b_decode_int8hu_perchan_sym",
                    fileName: "qwen3_5_0_8b_decode_int8hu_perchan_sym/tokenizer",
                    downloadURL: nil,
                    expectedSizeBytes: nil,
                    sha256: nil,
                    required: true,
                    notes: []
                ),
            ],
            tokenizer: .init(
                source: "stub",
                type: "qwen-tokenizer",
                chatTemplate: "qwen-chat",
                tokenizerFiles: ["tokenizer/"],
                stopTokenIds: [],
                stopStrings: [],
                notes: []
            ),
            generation: .init(
                defaultContextWindow: 2048,
                maxContextWindow: nil,
                maxOutputTokens: 512,
                temperature: 0.7,
                topP: 0.9,
                topK: nil,
                doSample: true,
                greedySupported: true
            ),
            vision: nil,
            runtime: .init(
                adapter: .coreaiPipelinedNStateText,
                status: .adapterRequired,
                engine: "coreai-pipelined",
                functionName: "main",
                inputNames: ["input_ids"],
                outputNames: ["logits"],
                stateNames: ["keyCache", "valueCache"],
                preferredCompute: .gpu,
                requiresCustomMetalKernels: false,
                requiresCoreAIModelsPatches: true,
                requiredRuntimeFlags: [],
                requiresIncreasedMemoryEntitlement: nil,
                notes: [],
                staticInputNames: nil
            ),
            devicePolicy: .init(
                iPhone: .supported,
                iPad: .supported,
                Mac: .recommended,
                minimumOS: .init(iOS: "27.0", iPadOS: "27.0", macOS: "27.0"),
                notes: []
            ),
            performance: nil
        )
    }

    private func makeBundleRoot() throws -> URL {
        let container = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let root = container.appendingPathComponent(
            "qwen3_5_0_8b_decode_int8hu_perchan_sym",
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func writeCompleteQwenBundle(at root: URL) throws {
        try writeMetadata(at: root)
        try FileManager.default.createDirectory(
            at: root.appendingPathComponent("qwen3_5_0_8b_decode_int8hu_perchan_sym.aimodel", isDirectory: true),
            withIntermediateDirectories: true
        )
        try writeTokenizerFiles(at: root)
    }

    private func writeMetadata(at root: URL) throws {
        try Data("{}".utf8).write(to: root.appendingPathComponent("metadata.json"))
    }

    private func writeTokenizerFiles(at root: URL) throws {
        let tokenizerDirectory = root.appendingPathComponent("tokenizer", isDirectory: true)
        try FileManager.default.createDirectory(at: tokenizerDirectory, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: tokenizerDirectory.appendingPathComponent("tokenizer.json"))
        try Data("{{ prompt }}".utf8).write(to: tokenizerDirectory.appendingPathComponent("chat_template.jinja"))
        try Data("{}".utf8).write(to: tokenizerDirectory.appendingPathComponent("tokenizer_config.json"))
        try Data("{}".utf8).write(to: tokenizerDirectory.appendingPathComponent("special_tokens_map.json"))
    }
}
