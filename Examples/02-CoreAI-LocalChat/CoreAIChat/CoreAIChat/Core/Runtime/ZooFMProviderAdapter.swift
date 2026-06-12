import Foundation

#if ENABLE_ZOO_FM_PROVIDER && canImport(FoundationModels) && canImport(ZooFMProvider)
import FoundationModels
import ZooFMProvider
#endif

struct ZooFMProviderAdapter: ExternalRuntimeProvider {
    let providerID = "zoo_fm_provider"
    let displayName = "ZooFMProvider"

    func availability(for context: ExternalRuntimeContext) -> ExternalRuntimeAvailability {
        #if ENABLE_ZOO_FM_PROVIDER && canImport(FoundationModels) && canImport(ZooFMProvider)
        guard let bundleURL = context.bundleURL else {
            return .unavailable(
                reason: "ENABLE_ZOO_FM_PROVIDER is set and ZooFMProvider is linked, but no local bundle URL was supplied."
            )
        }

        let pathExists = FileManager.default.fileExists(atPath: bundleURL.path)
        guard pathExists else {
            return .unavailable(
                reason: "ENABLE_ZOO_FM_PROVIDER is set and ZooFMProvider is linked, but the local bundle path does not exist: \(bundleURL.path)"
            )
        }

        var details: [String] = [
            "ENABLE_ZOO_FM_PROVIDER is enabled and ZooFMProvider is importable in this build.",
            "Bundle candidate: \(bundleURL.lastPathComponent).",
            "CoreAIChat does not wire this adapter into ChatModelRuntime yet."
        ]
        return .available(summary: details.joined(separator: " "))
        #else
        if ExternalRuntimeBuildOptions.zooFMProviderCompileFlagEnabled &&
            !ExternalRuntimeBuildOptions.zooFMProviderModuleLinked {
            return .unavailable(
                reason: [
                    "ENABLE_ZOO_FM_PROVIDER is set for this build, but ZooFMProvider is not linked into CoreAIChat.",
                    "Provide the external package only after preparing a patched sibling coreai-models checkout and preserving BSD license notices."
                ].joined(separator: " ")
            )
        }

        return .unavailable(
            reason: [
                "ENABLE_ZOO_FM_PROVIDER is not enabled for this build.",
                "Default CoreAIChat builds keep ZooFMProvider optional and out of the target dependency graph."
            ].joined(separator: " ")
        )
        #endif
    }

    func generateResponse(
        for messages: [ChatMessage],
        settings: ChatGenerationSettings,
        context: ExternalRuntimeContext
    ) async throws -> String {
        let availability = availability(for: context)
        guard availability.isAvailable else {
            throw ExternalRuntimeProviderError.unavailable(availability.summary)
        }

        guard let prompt = messages.last(where: { $0.role == .user })?.content
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !prompt.isEmpty else {
            throw ExternalRuntimeProviderError.missingPrompt
        }

        #if ENABLE_ZOO_FM_PROVIDER && canImport(FoundationModels) && canImport(ZooFMProvider)
        guard let bundleURL = context.bundleURL else {
            throw ExternalRuntimeProviderError.unavailable("ZooFMProvider bundle URL is missing.")
        }

        do {
            let model = try await ZooLanguageModel(resourcesAt: bundleURL)
            let session = LanguageModelSession(
                model: model,
                instructions: "You are a helpful assistant running locally on device."
            )
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            throw ExternalRuntimeProviderError.generationFailed(
                "ZooFMProvider generation failed for \(context.modelName ?? context.modelID ?? "the selected model"): \(error.localizedDescription)"
            )
        }
        #else
        throw ExternalRuntimeProviderError.unavailable(availability.summary)
        #endif
    }
}
