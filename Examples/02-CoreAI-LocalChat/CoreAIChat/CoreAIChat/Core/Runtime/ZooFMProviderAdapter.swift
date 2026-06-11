import Foundation

#if ENABLE_ZOO_FM_PROVIDER && canImport(ZooFMProvider)
import ZooFMProvider
#endif

struct ZooFMProviderAdapter: ExternalRuntimeProvider {
    let providerID = "zoo_fm_provider"
    let displayName = "ZooFMProvider"

    func availability(for context: ExternalRuntimeContext) -> ExternalRuntimeAvailability {
        #if ENABLE_ZOO_FM_PROVIDER && canImport(ZooFMProvider)
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
}
