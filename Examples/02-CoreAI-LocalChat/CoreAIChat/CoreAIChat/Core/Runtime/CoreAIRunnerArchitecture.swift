//
//  CoreAIRunnerArchitecture.swift
//  CoreAIChat
//
//  Step 1 file: generic runner architecture for Core AI model profiles.
//
//  Intended location:
//  Examples/02-CoreAI-LocalChat/CoreAIChat/CoreAIChat/Core/Runtime/CoreAIRunnerArchitecture.swift
//
//  Depends on:
//  - CoreAIExternalModelCatalog.swift
//
//  Notes:
//  - This file does not implement real Core AI inference.
//  - It defines the model-runner contract, registry, preflight model, and safe fallback runners.
//  - Real model-family runners should be added separately.
//

import Foundation

// MARK: - Hashable Conformance for Catalog Enums

extension CoreAIRuntimeAdapter: Hashable {}
extension CoreAIRuntimeStatus: Hashable {}
extension CoreAIArtifactRole: Hashable {}
extension CoreAIArtifactFormat: Hashable {}
extension CoreAIComputePreference: Hashable {}

// MARK: - Chat Runtime Request/Response Models

enum CoreAIChatRole: String, Codable, Equatable, Hashable {
    case system
    case user
    case assistant
    case tool
}

enum CoreAIChatAttachmentKind: String, Codable, Equatable, Hashable {
    case image
    case audio
    case video
    case document
    case unknown
}

struct CoreAIChatAttachment: Codable, Equatable, Hashable, Identifiable {
    var id: String
    var kind: CoreAIChatAttachmentKind
    var localURL: URL?
    var mimeType: String?
    var displayName: String?
    var metadata: [String: String]

    init(
        id: String = UUID().uuidString,
        kind: CoreAIChatAttachmentKind,
        localURL: URL? = nil,
        mimeType: String? = nil,
        displayName: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.kind = kind
        self.localURL = localURL
        self.mimeType = mimeType
        self.displayName = displayName
        self.metadata = metadata
    }
}

struct CoreAIChatTurn: Codable, Equatable, Hashable, Identifiable {
    var id: String
    var role: CoreAIChatRole
    var content: String
    var attachments: [CoreAIChatAttachment]
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        role: CoreAIChatRole,
        content: String,
        attachments: [CoreAIChatAttachment] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.attachments = attachments
        self.createdAt = createdAt
    }
}

struct CoreAIRunnerGenerationSettings: Codable, Equatable, Hashable {
    var contextWindow: Int
    var maxOutputTokens: Int
    var temperature: Double
    var topP: Double
    var topK: Int?
    var doSample: Bool
    var stopTokenIds: [Int]
    var stopStrings: [String]

    static let `default` = CoreAIRunnerGenerationSettings(
        contextWindow: 2048,
        maxOutputTokens: 512,
        temperature: 0.7,
        topP: 0.9,
        topK: nil,
        doSample: true,
        stopTokenIds: [],
        stopStrings: []
    )

    static func from(profile: CoreAIExternalModelProfile) -> CoreAIRunnerGenerationSettings {
        CoreAIRunnerGenerationSettings(
            contextWindow: profile.generation.defaultContextWindow,
            maxOutputTokens: profile.generation.maxOutputTokens,
            temperature: profile.generation.temperature,
            topP: profile.generation.topP,
            topK: profile.generation.topK,
            doSample: profile.generation.doSample,
            stopTokenIds: profile.tokenizer.stopTokenIds,
            stopStrings: profile.tokenizer.stopStrings
        )
    }
}

struct CoreAIResolvedArtifact: Equatable, Hashable, Identifiable {
    var id: String
    var artifactRole: CoreAIArtifactRole
    var expectedDirectoryName: String
    var localURL: URL?
    var exists: Bool
    var isDirectory: Bool
    var notes: [String]

    init(
        id: String,
        artifactRole: CoreAIArtifactRole,
        expectedDirectoryName: String,
        localURL: URL?,
        exists: Bool,
        isDirectory: Bool,
        notes: [String] = []
    ) {
        self.id = id
        self.artifactRole = artifactRole
        self.expectedDirectoryName = expectedDirectoryName
        self.localURL = localURL
        self.exists = exists
        self.isDirectory = isDirectory
        self.notes = notes
    }
}

// MARK: - Bundle Inspection

enum ArtifactCheckExpectedKind: String, Codable, Equatable, Hashable {
    case file
    case directory
}

struct ArtifactCheckResult: Codable, Equatable, Hashable, Identifiable {
    var id: String
    var title: String
    var relativePath: String?
    var expectedKind: ArtifactCheckExpectedKind
    var required: Bool
    var actualURL: URL?
    var exists: Bool
    var kindMatches: Bool
    var isDirectory: Bool?

    var isSatisfied: Bool {
        exists && kindMatches
    }

    var expectedLocationDescription: String {
        relativePath ?? "bundle root"
    }
}

struct ModelBundleInspectionResult: Codable, Equatable, Hashable {
    var inspectorName: String
    var bundleRootURL: URL?
    var checks: [ArtifactCheckResult]

    var missingRequiredChecks: [ArtifactCheckResult] {
        checks.filter { $0.required && !$0.isSatisfied }
    }

    var hasBlockingIssues: Bool {
        !missingRequiredChecks.isEmpty
    }
}

protocol ModelBundleInspector {
    var displayName: String { get }

    func canInspect(profile: CoreAIExternalModelProfile) -> Bool

    func inspect(
        profile: CoreAIExternalModelProfile,
        bundleRootURL: URL?,
        fileManager: FileManager
    ) -> ModelBundleInspectionResult
}

struct GenericCoreAIModelBundleInspector: ModelBundleInspector {
    struct ExpectedPath {
        var id: String
        var title: String
        var relativePath: String?
        var expectedKind: ArtifactCheckExpectedKind
        var required: Bool
    }

    let displayName: String
    private let matcher: (CoreAIExternalModelProfile) -> Bool
    private let expectedPaths: (CoreAIExternalModelProfile) -> [ExpectedPath]

    init(
        displayName: String,
        matcher: @escaping (CoreAIExternalModelProfile) -> Bool,
        expectedPaths: @escaping (CoreAIExternalModelProfile) -> [ExpectedPath]
    ) {
        self.displayName = displayName
        self.matcher = matcher
        self.expectedPaths = expectedPaths
    }

    func canInspect(profile: CoreAIExternalModelProfile) -> Bool {
        matcher(profile)
    }

    func inspect(
        profile: CoreAIExternalModelProfile,
        bundleRootURL: URL?,
        fileManager: FileManager = .default
    ) -> ModelBundleInspectionResult {
        let checks = expectedPaths(profile).map { expectedPath -> ArtifactCheckResult in
            let targetURL = resolvedURL(for: expectedPath, bundleRootURL: bundleRootURL)
            let exists = targetURL.map { fileManager.fileExists(atPath: $0.path) } ?? false
            let isDirectory = targetURL.flatMap {
                try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory
            }
            let kindMatches: Bool
            if let isDirectory {
                kindMatches = expectedPath.expectedKind == .directory ? isDirectory : !isDirectory
            } else {
                kindMatches = false
            }

            return ArtifactCheckResult(
                id: expectedPath.id,
                title: expectedPath.title,
                relativePath: expectedPath.relativePath,
                expectedKind: expectedPath.expectedKind,
                required: expectedPath.required,
                actualURL: targetURL,
                exists: exists,
                kindMatches: kindMatches,
                isDirectory: isDirectory
            )
        }

        return ModelBundleInspectionResult(
            inspectorName: displayName,
            bundleRootURL: bundleRootURL,
            checks: checks
        )
    }

    private func resolvedURL(
        for expectedPath: ExpectedPath,
        bundleRootURL: URL?
    ) -> URL? {
        guard let bundleRootURL else { return nil }
        guard let relativePath = expectedPath.relativePath else { return bundleRootURL }
        return bundleRootURL.appendingPathComponent(relativePath)
    }
}

struct QwenCoreAIModelBundleInspector: ModelBundleInspector {
    let displayName = "Qwen Core AI Model Bundle Inspector"

    private let genericInspector = GenericCoreAIModelBundleInspector(
        displayName: "Qwen Core AI Model Bundle Inspector",
        matcher: { profile in
            profile.id == "qwen3_5_0_8b_coreai_pipelined"
        },
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
                .init(id: "tokenizer_json", title: "tokenizer.json", relativePath: "tokenizer/tokenizer.json", expectedKind: .file, required: true),
                .init(id: "chat_template", title: "chat_template.jinja", relativePath: "tokenizer/chat_template.jinja", expectedKind: .file, required: true),
                .init(id: "tokenizer_config", title: "tokenizer_config.json", relativePath: "tokenizer/tokenizer_config.json", expectedKind: .file, required: true),
                .init(id: "special_tokens_map", title: "special_tokens_map.json", relativePath: "tokenizer/special_tokens_map.json", expectedKind: .file, required: true),
            ]
        }
    )

    func canInspect(profile: CoreAIExternalModelProfile) -> Bool {
        genericInspector.canInspect(profile: profile)
    }

    func inspect(
        profile: CoreAIExternalModelProfile,
        bundleRootURL: URL?,
        fileManager: FileManager = .default
    ) -> ModelBundleInspectionResult {
        genericInspector.inspect(
            profile: profile,
            bundleRootURL: bundleRootURL,
            fileManager: fileManager
        )
    }
}

struct CoreAIGenerationRequest: Equatable {
    var model: CoreAIExternalModelProfile
    var messages: [CoreAIChatTurn]
    var settings: CoreAIRunnerGenerationSettings
    var localArtifacts: [CoreAIResolvedArtifact]

    init(
        model: CoreAIExternalModelProfile,
        messages: [CoreAIChatTurn],
        settings: CoreAIRunnerGenerationSettings? = nil,
        localArtifacts: [CoreAIResolvedArtifact] = []
    ) {
        self.model = model
        self.messages = messages
        self.settings = settings ?? CoreAIRunnerGenerationSettings.from(profile: model)
        self.localArtifacts = localArtifacts
    }
}

enum CoreAIGenerationEvent: Equatable {
    case started(modelId: String)
    case token(String)
    case partialText(String)
    case completed(CoreAIGenerationResult)
    case diagnostic(String)
}

struct CoreAIGenerationResult: Equatable {
    var modelId: String
    var text: String
    var generatedTokenCount: Int?
    var finishReason: CoreAIGenerationFinishReason
    var diagnostics: [String]

    init(
        modelId: String,
        text: String,
        generatedTokenCount: Int? = nil,
        finishReason: CoreAIGenerationFinishReason,
        diagnostics: [String] = []
    ) {
        self.modelId = modelId
        self.text = text
        self.generatedTokenCount = generatedTokenCount
        self.finishReason = finishReason
        self.diagnostics = diagnostics
    }
}

enum CoreAIGenerationFinishReason: String, Codable, Equatable, Hashable {
    case stopToken
    case stopString
    case maxTokens
    case cancelled
    case error
    case notImplemented
}

// MARK: - Runner Errors

enum CoreAIModelRunnerError: Error, LocalizedError, Equatable {
    case adapterNotImplemented(adapter: String, modelName: String)
    case unsupportedModel(adapter: String, modelName: String)
    case missingRequiredArtifacts(modelName: String, missingArtifactIds: [String])
    case invalidRuntimeProfile(modelName: String, reason: String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .adapterNotImplemented(let adapter, let modelName):
            return "Runtime adapter '\(adapter)' is not implemented yet for \(modelName)."
        case .unsupportedModel(let adapter, let modelName):
            return "\(modelName) uses unsupported runtime adapter '\(adapter)'."
        case .missingRequiredArtifacts(let modelName, let missingArtifactIds):
            return "\(modelName) is missing required artifacts: \(missingArtifactIds.joined(separator: ", "))."
        case .invalidRuntimeProfile(let modelName, let reason):
            return "\(modelName) has an invalid runtime profile: \(reason)."
        case .cancelled:
            return "Generation was cancelled."
        }
    }
}

// MARK: - Preflight

enum CoreAIRunnerReadiness: String, Codable, Equatable, Hashable {
    case ready
    case experimental
    case adapterRequired
    case unsupported
    case missingArtifacts
    case invalidProfile
}

enum CoreAIRunnerFindingSeverity: String, Codable, Equatable, Hashable {
    case info
    case warning
    case error
}

struct CoreAIRunnerFinding: Codable, Equatable, Hashable, Identifiable {
    var id: String
    var severity: CoreAIRunnerFindingSeverity
    var code: String
    var message: String
    var remediation: String?

    init(
        id: String = UUID().uuidString,
        severity: CoreAIRunnerFindingSeverity,
        code: String,
        message: String,
        remediation: String? = nil
    ) {
        self.id = id
        self.severity = severity
        self.code = code
        self.message = message
        self.remediation = remediation
    }
}

struct CoreAIRunnerPreflightResult: Codable, Equatable, Hashable {
    var readiness: CoreAIRunnerReadiness
    var runnerName: String
    var findings: [CoreAIRunnerFinding]
    var bundleInspection: ModelBundleInspectionResult?

    var canGenerate: Bool {
        readiness == .ready || readiness == .experimental
    }

    var blockingFindings: [CoreAIRunnerFinding] {
        findings.filter { $0.severity == .error }
    }

    static func ready(
        runnerName: String,
        findings: [CoreAIRunnerFinding] = [],
        bundleInspection: ModelBundleInspectionResult? = nil
    ) -> CoreAIRunnerPreflightResult {
        CoreAIRunnerPreflightResult(
            readiness: .ready,
            runnerName: runnerName,
            findings: findings,
            bundleInspection: bundleInspection
        )
    }
}

enum CoreAIRunnerPreflightSupport {
    static func missingRequiredArtifacts(
        profile: CoreAIExternalModelProfile,
        localArtifacts: [CoreAIResolvedArtifact]
    ) -> [CoreAIModelArtifact] {
        let existingIds = Set(localArtifacts.filter(\.exists).map(\.id))
        return profile.requiredArtifacts.filter { !existingIds.contains($0.id) }
    }

    static func artifactFindings(
        profile: CoreAIExternalModelProfile,
        localArtifacts: [CoreAIResolvedArtifact]
    ) -> [CoreAIRunnerFinding] {
        let missing = missingRequiredArtifacts(profile: profile, localArtifacts: localArtifacts)

        guard !missing.isEmpty else {
            return [
                CoreAIRunnerFinding(
                    severity: .info,
                    code: "required_artifacts_present",
                    message: "All required artifacts are present."
                )
            ]
        }

        return missing.map { artifact in
            CoreAIRunnerFinding(
                severity: .error,
                code: "missing_artifact",
                message: "Missing required artifact '\(artifact.id)' for \(profile.name).",
                remediation: "Manually add '\(artifact.manualInstallDirectoryName)' or download it before running this model."
            )
        }
    }

    static func runtimeFieldFindings(profile: CoreAIExternalModelProfile) -> [CoreAIRunnerFinding] {
        var findings: [CoreAIRunnerFinding] = []

        if profile.runtime.functionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            findings.append(
                CoreAIRunnerFinding(
                    severity: .warning,
                    code: "missing_function_name",
                    message: "Runtime profile does not declare a Core AI function name.",
                    remediation: "Verify the .aimodel bundle function contract before implementing this runner."
                )
            )
        }

        if profile.runtime.inputNames.isEmpty {
            findings.append(
                CoreAIRunnerFinding(
                    severity: .warning,
                    code: "missing_input_names",
                    message: "Runtime profile does not declare input names."
                )
            )
        }

        if profile.runtime.outputNames.isEmpty {
            findings.append(
                CoreAIRunnerFinding(
                    severity: .warning,
                    code: "missing_output_names",
                    message: "Runtime profile does not declare output names."
                )
            )
        }

        return findings
    }

    static func inspectionFindings(
        inspectionResult: ModelBundleInspectionResult?
    ) -> [CoreAIRunnerFinding] {
        guard let inspectionResult else { return [] }

        return inspectionResult.checks.map { check in
            if check.isSatisfied {
                return CoreAIRunnerFinding(
                    severity: .info,
                    code: "\(check.id)_found",
                    message: "\(check.title) found."
                )
            }

            let message: String
            if check.exists && !check.kindMatches {
                message = "\(check.title) exists but is not a \(check.expectedKind.rawValue)."
            } else {
                message = "\(check.title) missing."
            }

            let remediation = inspectionRemediation(
                for: check,
                bundleRootURL: inspectionResult.bundleRootURL
            )

            return CoreAIRunnerFinding(
                severity: check.required ? .error : .warning,
                code: "\(check.id)_missing",
                message: message,
                remediation: remediation
            )
        }
    }

    static func readinessForAdapterStatus(_ status: CoreAIRuntimeStatus) -> CoreAIRunnerReadiness {
        switch status {
        case .ready:
            return .ready
        case .experimental:
            return .experimental
        case .adapterRequired:
            return .adapterRequired
        case .unsupported:
            return .unsupported
        }
    }

    private static func inspectionRemediation(
        for check: ArtifactCheckResult,
        bundleRootURL: URL?
    ) -> String? {
        guard check.required else { return nil }
        if let bundleRootURL {
            return "Ensure '\(check.expectedLocationDescription)' exists inside '\(bundleRootURL.path)'."
        }
        return "Install the local model bundle before using this runner."
    }
}

// MARK: - Runner Protocol

protocol CoreAIModelRunner {
    var supportedAdapter: CoreAIRuntimeAdapter { get }
    var displayName: String { get }

    func canRun(profile: CoreAIExternalModelProfile) -> Bool

    func preflight(
        profile: CoreAIExternalModelProfile,
        localArtifacts: [CoreAIResolvedArtifact],
        bundleInspection: ModelBundleInspectionResult?
    ) -> CoreAIRunnerPreflightResult

    func generate(
        request: CoreAIGenerationRequest
    ) -> AsyncThrowingStream<CoreAIGenerationEvent, Error>
}

extension CoreAIModelRunner {
    func canRun(profile: CoreAIExternalModelProfile) -> Bool {
        profile.runtime.adapter == supportedAdapter
    }

    func basePreflight(
        profile: CoreAIExternalModelProfile,
        localArtifacts: [CoreAIResolvedArtifact],
        runnerName: String,
        bundleInspection: ModelBundleInspectionResult?
    ) -> CoreAIRunnerPreflightResult {
        var findings: [CoreAIRunnerFinding] = []

        findings.append(contentsOf: CoreAIRunnerPreflightSupport.artifactFindings(
            profile: profile,
            localArtifacts: localArtifacts
        ))

        findings.append(contentsOf: CoreAIRunnerPreflightSupport.runtimeFieldFindings(profile: profile))
        findings.append(contentsOf: CoreAIRunnerPreflightSupport.inspectionFindings(
            inspectionResult: bundleInspection
        ))

        if findings.contains(where: { $0.severity == .error }) {
            return CoreAIRunnerPreflightResult(
                readiness: .missingArtifacts,
                runnerName: runnerName,
                findings: findings,
                bundleInspection: bundleInspection
            )
        }

        return CoreAIRunnerPreflightResult(
            readiness: CoreAIRunnerPreflightSupport.readinessForAdapterStatus(profile.runtime.status),
            runnerName: runnerName,
            findings: findings,
            bundleInspection: bundleInspection
        )
    }
}

// MARK: - Safe Fallback Runners

struct CoreAIAdapterRequiredRunner: CoreAIModelRunner {
    var supportedAdapter: CoreAIRuntimeAdapter
    var displayName: String {
        "Adapter Required: \(supportedAdapter.rawValue)"
    }

    init(adapter: CoreAIRuntimeAdapter) {
        self.supportedAdapter = adapter
    }

    func preflight(
        profile: CoreAIExternalModelProfile,
        localArtifacts: [CoreAIResolvedArtifact],
        bundleInspection: ModelBundleInspectionResult?
    ) -> CoreAIRunnerPreflightResult {
        var findings = CoreAIRunnerPreflightSupport.artifactFindings(
            profile: profile,
            localArtifacts: localArtifacts
        )
        findings.append(contentsOf: CoreAIRunnerPreflightSupport.inspectionFindings(
            inspectionResult: bundleInspection
        ))

        findings.append(
            CoreAIRunnerFinding(
                severity: .error,
                code: "adapter_required",
                message: "No Swift runner is implemented for adapter '\(profile.runtime.adapter.rawValue)'.",
                remediation: "Implement a model-family runner before enabling real generation."
            )
        )

        let readiness: CoreAIRunnerReadiness = findings.contains(where: { $0.severity == .error && $0.code != "adapter_required" })
            ? .missingArtifacts
            : .adapterRequired

        return CoreAIRunnerPreflightResult(
            readiness: readiness,
            runnerName: displayName,
            findings: findings,
            bundleInspection: bundleInspection
        )
    }

    func generate(
        request: CoreAIGenerationRequest
    ) -> AsyncThrowingStream<CoreAIGenerationEvent, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(
                throwing: CoreAIModelRunnerError.adapterNotImplemented(
                    adapter: request.model.runtime.adapter.rawValue,
                    modelName: request.model.name
                )
            )
        }
    }
}

struct CoreAIUnsupportedRunner: CoreAIModelRunner {
    var supportedAdapter: CoreAIRuntimeAdapter
    var displayName: String {
        "Unsupported Adapter: \(supportedAdapter.rawValue)"
    }

    init(adapter: CoreAIRuntimeAdapter) {
        self.supportedAdapter = adapter
    }

    func preflight(
        profile: CoreAIExternalModelProfile,
        localArtifacts: [CoreAIResolvedArtifact],
        bundleInspection: ModelBundleInspectionResult?
    ) -> CoreAIRunnerPreflightResult {
        let findings = CoreAIRunnerPreflightSupport.inspectionFindings(
            inspectionResult: bundleInspection
        ) + [
            CoreAIRunnerFinding(
                severity: .error,
                code: "unsupported_adapter",
                message: "The runtime adapter '\(profile.runtime.adapter.rawValue)' is unsupported by this app.",
                remediation: "Choose another model or add a supported runtime adapter."
            )
        ]

        return CoreAIRunnerPreflightResult(
            readiness: .unsupported,
            runnerName: displayName,
            findings: findings,
            bundleInspection: bundleInspection
        )
    }

    func generate(
        request: CoreAIGenerationRequest
    ) -> AsyncThrowingStream<CoreAIGenerationEvent, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(
                throwing: CoreAIModelRunnerError.unsupportedModel(
                    adapter: request.model.runtime.adapter.rawValue,
                    modelName: request.model.name
                )
            )
        }
    }
}

struct CoreAIMockExternalCatalogRunner: CoreAIModelRunner {
    let supportedAdapter: CoreAIRuntimeAdapter = .mock
    let displayName = "Mock External Catalog Runner"

    func preflight(
        profile: CoreAIExternalModelProfile,
        localArtifacts: [CoreAIResolvedArtifact],
        bundleInspection: ModelBundleInspectionResult?
    ) -> CoreAIRunnerPreflightResult {
        CoreAIRunnerPreflightResult.ready(
            runnerName: displayName,
            findings: [
                CoreAIRunnerFinding(
                    severity: .info,
                    code: "mock_runtime",
                    message: "Mock runner is active. No real Core AI model execution will occur."
                )
            ],
            bundleInspection: bundleInspection
        )
    }

    func generate(
        request: CoreAIGenerationRequest
    ) -> AsyncThrowingStream<CoreAIGenerationEvent, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(.started(modelId: request.model.id))

            let lastUserText = request.messages.last(where: { $0.role == .user })?.content ?? "Hello"
            let response = """
            Mock response from \(request.model.name).

            Received: \(lastUserText)

            Runtime adapter: \(request.model.runtime.adapter.rawValue)
            Context window: \(request.settings.contextWindow)
            Max output tokens: \(request.settings.maxOutputTokens)
            """

            continuation.yield(.partialText(response))
            continuation.yield(
                .completed(
                    CoreAIGenerationResult(
                        modelId: request.model.id,
                        text: response,
                        generatedTokenCount: nil,
                        finishReason: .stopString,
                        diagnostics: ["mock_runtime"]
                    )
                )
            )
            continuation.finish()
        }
    }
}

// MARK: - Registry

final class CoreAIModelRunnerRegistry {
    private var runnerFactories: [CoreAIRuntimeAdapter: () -> any CoreAIModelRunner]
    private var bundleInspectors: [any ModelBundleInspector]

    init(
        runners: [CoreAIModelRunner] = [],
        bundleInspectors: [any ModelBundleInspector] = []
    ) {
        self.runnerFactories = [:]
        self.bundleInspectors = bundleInspectors
        runners.forEach { register($0) }
    }

    static func baseRegistry() -> CoreAIModelRunnerRegistry {
        CoreAIModelRunnerRegistry(
            runners: [
                CoreAIMockExternalCatalogRunner()
            ]
        )
    }

    func register(_ runner: CoreAIModelRunner) {
        runnerFactories[runner.supportedAdapter] = { runner }
    }

    func register(
        adapter: CoreAIRuntimeAdapter,
        makeRunner: @escaping () -> any CoreAIModelRunner
    ) {
        runnerFactories[adapter] = makeRunner
    }

    func registerBundleInspector(_ inspector: any ModelBundleInspector) {
        bundleInspectors.append(inspector)
    }

    func runner(for profile: CoreAIExternalModelProfile) -> CoreAIModelRunner {
        if let makeRunner = runnerFactories[profile.runtime.adapter] {
            return makeRunner()
        }

        if profile.runtime.status == .unsupported {
            return CoreAIUnsupportedRunner(adapter: profile.runtime.adapter)
        }

        return CoreAIAdapterRequiredRunner(adapter: profile.runtime.adapter)
    }

    func bundleInspector(for profile: CoreAIExternalModelProfile) -> (any ModelBundleInspector)? {
        bundleInspectors.first(where: { $0.canInspect(profile: profile) })
    }

    func inspectBundle(
        profile: CoreAIExternalModelProfile,
        bundleRootURL: URL?,
        fileManager: FileManager = .default
    ) -> ModelBundleInspectionResult? {
        bundleInspector(for: profile)?.inspect(
            profile: profile,
            bundleRootURL: bundleRootURL,
            fileManager: fileManager
        )
    }

    func preflight(
        profile: CoreAIExternalModelProfile,
        localArtifacts: [CoreAIResolvedArtifact],
        bundleRootURL: URL? = nil,
        fileManager: FileManager = .default
    ) -> CoreAIRunnerPreflightResult {
        let inspection = inspectBundle(
            profile: profile,
            bundleRootURL: bundleRootURL,
            fileManager: fileManager
        )
        return runner(for: profile).preflight(
            profile: profile,
            localArtifacts: localArtifacts,
            bundleInspection: inspection
        )
    }

    func generate(
        request: CoreAIGenerationRequest
    ) -> AsyncThrowingStream<CoreAIGenerationEvent, Error> {
        runner(for: request.model).generate(request: request)
    }
}
