//
//  CoreAIConcreteRunnerSkeletons.swift
//  CoreAIChat
//
//  Step 2 file: compile-safe concrete runner skeletons for known external Core AI model families.
//
//  Intended location:
//  Examples/02-CoreAI-LocalChat/CoreAIChat/CoreAIChat/Core/Runtime/CoreAIConcreteRunnerSkeletons.swift
//
//  Depends on:
//  - CoreAIExternalModelCatalog.swift
//  - CoreAIRunnerArchitecture.swift
//
//  Notes:
//  - These runners intentionally do NOT call fake Core AI APIs.
//  - They are safe placeholders that preflight model contracts and block generation with clear errors.
//  - Replace each `generate` implementation only after verifying the exact .aimodel/tokenizer/runtime contract.
//

import Foundation

#if canImport(CoreAI)
import CoreAI
#endif

// MARK: - Registry With Known Adapter Skeletons

extension CoreAIModelRunnerRegistry {
    static func knownExternalModelRegistry() -> CoreAIModelRunnerRegistry {
        let registry = CoreAIModelRunnerRegistry.baseRegistry()

        registry.register(adapter: .coreaiPipelinedNStateText) { CoreAIPipelinedNStateTextRunner() }
        registry.register(adapter: .coreaiPipelinedExtraStateText) { CoreAIPipelinedExtraStateTextRunner() }
        registry.register(adapter: .gemma4MultiStagePipelinedText) { Gemma4MultiStagePipelinedTextRunner() }
        registry.register(adapter: .coreaiPipelinedVisionLanguage) { CoreAIPipelinedVisionLanguageRunner() }
        registry.register(adapter: .coreaiStandardLanguageModel) { CoreAIStandardLanguageModelRunner() }
        registry.registerBundleInspector(QwenCoreAIModelBundleInspector())

        return registry
    }
}

// MARK: - Shared Not-Implemented Generation Helper

enum CoreAIConcreteRunnerSupport {
    static func finishAsNotImplemented(
        request: CoreAIGenerationRequest,
        runnerName: String,
        extraDiagnostics: [String] = []
    ) -> AsyncThrowingStream<CoreAIGenerationEvent, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(.started(modelId: request.model.id))
            continuation.yield(.diagnostic("\(runnerName) is selected but real Core AI generation is not implemented yet."))

            let diagnostics = [
                "runner=\(runnerName)",
                "adapter=\(request.model.runtime.adapter.rawValue)",
                "engine=\(request.model.runtime.engine)",
                "function=\(request.model.runtime.functionName)",
                "inputs=\(request.model.runtime.inputNames.joined(separator: ","))",
                "outputs=\(request.model.runtime.outputNames.joined(separator: ","))",
                "states=\(request.model.runtime.stateNames.joined(separator: ","))"
            ] + extraDiagnostics

            continuation.yield(
                .completed(
                    CoreAIGenerationResult(
                        modelId: request.model.id,
                        text: "Runtime adapter '\(request.model.runtime.adapter.rawValue)' is recognized, but real generation is not implemented yet for \(request.model.name).",
                        generatedTokenCount: nil,
                        finishReason: .notImplemented,
                        diagnostics: diagnostics
                    )
                )
            )

            continuation.finish(
                throwing: CoreAIModelRunnerError.adapterNotImplemented(
                    adapter: request.model.runtime.adapter.rawValue,
                    modelName: request.model.name
                )
            )
        }
    }

    static func preflightForRecognizedAdapter(
        profile: CoreAIExternalModelProfile,
        localArtifacts: [CoreAIResolvedArtifact],
        bundleInspection: ModelBundleInspectionResult?,
        runnerName: String,
        expectedAdapter: CoreAIRuntimeAdapter,
        requiredArtifactRoleAlternatives: [[CoreAIArtifactRole]],
        requiredInputNames: [String] = [],
        requiredOutputNames: [String] = [],
        minimumStateCount: Int? = nil
    ) -> CoreAIRunnerPreflightResult {
        var findings: [CoreAIRunnerFinding] = []

        if profile.runtime.adapter != expectedAdapter {
            findings.append(
                CoreAIRunnerFinding(
                    severity: .error,
                    code: "wrong_adapter",
                    message: "\(runnerName) cannot run adapter '\(profile.runtime.adapter.rawValue)'.",
                    remediation: "Select a runner matching '\(expectedAdapter.rawValue)'."
                )
            )
        }

        findings.append(contentsOf: CoreAIRunnerPreflightSupport.inspectionFindings(
            inspectionResult: bundleInspection
        ))

        let missingArtifacts = CoreAIRunnerPreflightSupport.missingRequiredArtifacts(
            profile: profile,
            localArtifacts: localArtifacts
        )

        for artifact in missingArtifacts {
            findings.append(
                CoreAIRunnerFinding(
                    severity: .error,
                    code: "missing_artifact",
                    message: "Missing required artifact '\(artifact.id)' for \(profile.name).",
                    remediation: "Add '\(artifact.manualInstallDirectoryName)' to the local model storage before running."
                )
            )
        }

        let artifactRoles = Set(profile.requiredArtifacts.map(\.role))
        for roleGroup in requiredArtifactRoleAlternatives
        where artifactRoles.isDisjoint(with: roleGroup) {
            let roleList = roleGroup.map(\.rawValue).joined(separator: " or ")
            findings.append(
                CoreAIRunnerFinding(
                    severity: .warning,
                    code: "missing_expected_artifact_role",
                    message: "Manifest does not include expected artifact role '\(roleList)'.",
                    remediation: "Verify the model manifest against the model card/runtime contract."
                )
            )
        }

        for inputName in requiredInputNames where !profile.runtime.inputNames.contains(inputName) {
            findings.append(
                CoreAIRunnerFinding(
                    severity: .warning,
                    code: "missing_expected_input",
                    message: "Runtime profile does not list expected input '\(inputName)'."
                )
            )
        }

        for outputName in requiredOutputNames where !profile.runtime.outputNames.contains(outputName) {
            findings.append(
                CoreAIRunnerFinding(
                    severity: .warning,
                    code: "missing_expected_output",
                    message: "Runtime profile does not list expected output '\(outputName)'."
                )
            )
        }

        if let minimumStateCount, profile.runtime.stateNames.count < minimumStateCount {
            findings.append(
                CoreAIRunnerFinding(
                    severity: .warning,
                    code: "state_count_lower_than_expected",
                    message: "Runtime profile lists \(profile.runtime.stateNames.count) states, expected at least \(minimumStateCount).",
                    remediation: "Verify KV/cache/state names before implementing generation."
                )
            )
        }

        findings.append(contentsOf: CoreAIRunnerPreflightSupport.runtimeFieldFindings(profile: profile))

        if findings.contains(where: { $0.severity == .error }) {
            return CoreAIRunnerPreflightResult(
                readiness: .missingArtifacts,
                runnerName: runnerName,
                findings: findings,
                bundleInspection: bundleInspection
            )
        }

        // These skeletons recognize the adapter but still need real generation code.
        let readiness: CoreAIRunnerReadiness = profile.runtime.status == .ready || profile.runtime.status == .experimental
            ? .adapterRequired
            : CoreAIRunnerPreflightSupport.readinessForAdapterStatus(profile.runtime.status)

        var finalFindings = findings
        finalFindings.append(
            CoreAIRunnerFinding(
                severity: .warning,
                code: "generation_not_implemented",
                message: "\(runnerName) is a scaffold. Real token generation is not implemented yet.",
                remediation: "Implement tokenizer, prefill/decode loop, state handling, sampling, and stop-token handling."
            )
        )

        return CoreAIRunnerPreflightResult(
            readiness: readiness,
            runnerName: runnerName,
            findings: finalFindings,
            bundleInspection: bundleInspection
        )
    }
}

// MARK: - Text Runner: Core AI Pipelined N-State

struct CoreAIPipelinedNStateTextRunner: CoreAIModelRunner {
    let supportedAdapter: CoreAIRuntimeAdapter = .coreaiPipelinedNStateText
    let displayName = "Core AI Pipelined N-State Text Runner"

    func preflight(
        profile: CoreAIExternalModelProfile,
        localArtifacts: [CoreAIResolvedArtifact],
        bundleInspection: ModelBundleInspectionResult?
    ) -> CoreAIRunnerPreflightResult {
        CoreAIConcreteRunnerSupport.preflightForRecognizedAdapter(
            profile: profile,
            localArtifacts: localArtifacts,
            bundleInspection: bundleInspection,
            runnerName: displayName,
            expectedAdapter: supportedAdapter,
            requiredArtifactRoleAlternatives: [[.languageBundle, .languageDecoder]],
            requiredInputNames: ["input_ids"],
            requiredOutputNames: ["logits"],
            minimumStateCount: 1
        )
    }

    func generate(
        request: CoreAIGenerationRequest
    ) -> AsyncThrowingStream<CoreAIGenerationEvent, Error> {
        CoreAIConcreteRunnerSupport.finishAsNotImplemented(
            request: request,
            runnerName: displayName,
            extraDiagnostics: [
                "expectedFlow=tokenize -> prefill/decode -> logits -> sampler -> text"
            ]
        )
    }
}

// MARK: - Text Runner: Core AI Pipelined Extra-State

struct CoreAIPipelinedExtraStateTextRunner: CoreAIModelRunner {
    let supportedAdapter: CoreAIRuntimeAdapter = .coreaiPipelinedExtraStateText
    let displayName = "Core AI Pipelined Extra-State Text Runner"

    func preflight(
        profile: CoreAIExternalModelProfile,
        localArtifacts: [CoreAIResolvedArtifact],
        bundleInspection: ModelBundleInspectionResult?
    ) -> CoreAIRunnerPreflightResult {
        CoreAIConcreteRunnerSupport.preflightForRecognizedAdapter(
            profile: profile,
            localArtifacts: localArtifacts,
            bundleInspection: bundleInspection,
            runnerName: displayName,
            expectedAdapter: supportedAdapter,
            requiredArtifactRoleAlternatives: [[.languageBundle, .languageDecoder]],
            requiredInputNames: ["input_ids"],
            requiredOutputNames: ["logits"],
            minimumStateCount: 2
        )
    }

    func generate(
        request: CoreAIGenerationRequest
    ) -> AsyncThrowingStream<CoreAIGenerationEvent, Error> {
        CoreAIConcreteRunnerSupport.finishAsNotImplemented(
            request: request,
            runnerName: displayName,
            extraDiagnostics: [
                "expectedFlow=tokenize -> bind extra states -> decode -> logits -> sampler"
            ]
        )
    }
}

// MARK: - Text Runner: Gemma 4 Multi-Stage

struct Gemma4MultiStagePipelinedTextRunner: CoreAIModelRunner {
    let supportedAdapter: CoreAIRuntimeAdapter = .gemma4MultiStagePipelinedText
    let displayName = "Gemma 4 Multi-Stage Pipelined Text Runner"

    func preflight(
        profile: CoreAIExternalModelProfile,
        localArtifacts: [CoreAIResolvedArtifact],
        bundleInspection: ModelBundleInspectionResult?
    ) -> CoreAIRunnerPreflightResult {
        CoreAIConcreteRunnerSupport.preflightForRecognizedAdapter(
            profile: profile,
            localArtifacts: localArtifacts,
            bundleInspection: bundleInspection,
            runnerName: displayName,
            expectedAdapter: supportedAdapter,
            requiredArtifactRoleAlternatives: [[.languageBundle, .languageDecoder], [.frontendGather]],
            requiredInputNames: ["input_ids"],
            requiredOutputNames: ["logits"],
            minimumStateCount: 2
        )
    }

    func generate(
        request: CoreAIGenerationRequest
    ) -> AsyncThrowingStream<CoreAIGenerationEvent, Error> {
        CoreAIConcreteRunnerSupport.finishAsNotImplemented(
            request: request,
            runnerName: displayName,
            extraDiagnostics: [
                "expectedFlow=tokenize -> front-end gather -> core decoder -> head/logits -> sampler"
            ]
        )
    }
}

// MARK: - Vision-Language Runner: Core AI Pipelined Vision Language

struct CoreAIPipelinedVisionLanguageRunner: CoreAIModelRunner {
    let supportedAdapter: CoreAIRuntimeAdapter = .coreaiPipelinedVisionLanguage
    let displayName = "Core AI Pipelined Vision-Language Runner"

    func preflight(
        profile: CoreAIExternalModelProfile,
        localArtifacts: [CoreAIResolvedArtifact],
        bundleInspection: ModelBundleInspectionResult?
    ) -> CoreAIRunnerPreflightResult {
        var result = CoreAIConcreteRunnerSupport.preflightForRecognizedAdapter(
            profile: profile,
            localArtifacts: localArtifacts,
            bundleInspection: bundleInspection,
            runnerName: displayName,
            expectedAdapter: supportedAdapter,
            requiredArtifactRoleAlternatives: [[.languageBundle, .languageDecoder], [.visionEncoder]],
            requiredInputNames: ["input_ids"],
            requiredOutputNames: ["logits"],
            minimumStateCount: 1
        )

        if profile.vision?.imageInputSupported != true {
            result.findings.append(
                CoreAIRunnerFinding(
                    severity: .warning,
                    code: "vision_profile_missing",
                    message: "Vision-language adapter selected but vision profile is missing or disabled.",
                    remediation: "Add image size, image token count, and preprocessing details to the manifest."
                )
            )
        }

        return result
    }

    func generate(
        request: CoreAIGenerationRequest
    ) -> AsyncThrowingStream<CoreAIGenerationEvent, Error> {
        CoreAIConcreteRunnerSupport.finishAsNotImplemented(
            request: request,
            runnerName: displayName,
            extraDiagnostics: [
                "expectedFlow=image preprocess -> vision encoder -> image embeddings -> text decoder -> logits -> sampler"
            ]
        )
    }
}

// MARK: - Standard Language Model Runner

struct CoreAIStandardLanguageModelRunner: CoreAIModelRunner {
    let supportedAdapter: CoreAIRuntimeAdapter = .coreaiStandardLanguageModel
    let displayName = "Core AI Standard Language Model Runner"

    func preflight(
        profile: CoreAIExternalModelProfile,
        localArtifacts: [CoreAIResolvedArtifact],
        bundleInspection: ModelBundleInspectionResult?
    ) -> CoreAIRunnerPreflightResult {
        CoreAIConcreteRunnerSupport.preflightForRecognizedAdapter(
            profile: profile,
            localArtifacts: localArtifacts,
            bundleInspection: bundleInspection,
            runnerName: displayName,
            expectedAdapter: supportedAdapter,
            requiredArtifactRoleAlternatives: [[.languageBundle, .languageDecoder]],
            requiredInputNames: [],
            requiredOutputNames: [],
            minimumStateCount: nil
        )
    }

    func generate(
        request: CoreAIGenerationRequest
    ) -> AsyncThrowingStream<CoreAIGenerationEvent, Error> {
        CoreAIConcreteRunnerSupport.finishAsNotImplemented(
            request: request,
            runnerName: displayName,
            extraDiagnostics: [
                "expectedFlow=use Apple standard language-model session if model contract supports it"
            ]
        )
    }
}
