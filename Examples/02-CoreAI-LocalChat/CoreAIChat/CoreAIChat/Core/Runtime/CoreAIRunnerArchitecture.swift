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

    var canGenerate: Bool {
        readiness == .ready || readiness == .experimental
    }

    var blockingFindings: [CoreAIRunnerFinding] {
        findings.filter { $0.severity == .error }
    }

    static func ready(runnerName: String, findings: [CoreAIRunnerFinding] = []) -> CoreAIRunnerPreflightResult {
        CoreAIRunnerPreflightResult(readiness: .ready, runnerName: runnerName, findings: findings)
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
}

// MARK: - Runner Protocol

protocol CoreAIModelRunner {
    var supportedAdapter: CoreAIRuntimeAdapter { get }
    var displayName: String { get }

    func canRun(profile: CoreAIExternalModelProfile) -> Bool

    func preflight(
        profile: CoreAIExternalModelProfile,
        localArtifacts: [CoreAIResolvedArtifact]
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
        runnerName: String
    ) -> CoreAIRunnerPreflightResult {
        var findings: [CoreAIRunnerFinding] = []

        findings.append(contentsOf: CoreAIRunnerPreflightSupport.artifactFindings(
            profile: profile,
            localArtifacts: localArtifacts
        ))

        findings.append(contentsOf: CoreAIRunnerPreflightSupport.runtimeFieldFindings(profile: profile))

        if findings.contains(where: { $0.severity == .error }) {
            return CoreAIRunnerPreflightResult(
                readiness: .missingArtifacts,
                runnerName: runnerName,
                findings: findings
            )
        }

        return CoreAIRunnerPreflightResult(
            readiness: CoreAIRunnerPreflightSupport.readinessForAdapterStatus(profile.runtime.status),
            runnerName: runnerName,
            findings: findings
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
        localArtifacts: [CoreAIResolvedArtifact]
    ) -> CoreAIRunnerPreflightResult {
        var findings = CoreAIRunnerPreflightSupport.artifactFindings(
            profile: profile,
            localArtifacts: localArtifacts
        )

        findings.append(
            CoreAIRunnerFinding(
                severity: .error,
                code: "adapter_required",
                message: "No Swift runner is implemented for adapter '\(profile.runtime.adapter.rawValue)'.",
                remediation: "Implement a model-family runner before enabling real generation."
            )
        )

        return CoreAIRunnerPreflightResult(
            readiness: .adapterRequired,
            runnerName: displayName,
            findings: findings
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
        localArtifacts: [CoreAIResolvedArtifact]
    ) -> CoreAIRunnerPreflightResult {
        CoreAIRunnerPreflightResult(
            readiness: .unsupported,
            runnerName: displayName,
            findings: [
                CoreAIRunnerFinding(
                    severity: .error,
                    code: "unsupported_adapter",
                    message: "The runtime adapter '\(profile.runtime.adapter.rawValue)' is unsupported by this app.",
                    remediation: "Choose another model or add a supported runtime adapter."
                )
            ]
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
        localArtifacts: [CoreAIResolvedArtifact]
    ) -> CoreAIRunnerPreflightResult {
        CoreAIRunnerPreflightResult.ready(
            runnerName: displayName,
            findings: [
                CoreAIRunnerFinding(
                    severity: .info,
                    code: "mock_runtime",
                    message: "Mock runner is active. No real Core AI model execution will occur."
                )
            ]
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
    private var runners: [CoreAIRuntimeAdapter: CoreAIModelRunner]

    init(runners: [CoreAIModelRunner] = []) {
        self.runners = [:]
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
        runners[runner.supportedAdapter] = runner
    }

    func runner(for profile: CoreAIExternalModelProfile) -> CoreAIModelRunner {
        if let runner = runners[profile.runtime.adapter] {
            return runner
        }

        if profile.runtime.status == .unsupported {
            return CoreAIUnsupportedRunner(adapter: profile.runtime.adapter)
        }

        return CoreAIAdapterRequiredRunner(adapter: profile.runtime.adapter)
    }

    func preflight(
        profile: CoreAIExternalModelProfile,
        localArtifacts: [CoreAIResolvedArtifact]
    ) -> CoreAIRunnerPreflightResult {
        runner(for: profile).preflight(profile: profile, localArtifacts: localArtifacts)
    }

    func generate(
        request: CoreAIGenerationRequest
    ) -> AsyncThrowingStream<CoreAIGenerationEvent, Error> {
        runner(for: request.model).generate(request: request)
    }
}
