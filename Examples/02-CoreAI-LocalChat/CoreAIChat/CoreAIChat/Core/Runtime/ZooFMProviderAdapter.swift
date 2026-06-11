import Foundation

#if canImport(ZooFMProvider)
import ZooFMProvider
#endif

struct ZooFMProviderAdapter: ExternalRuntimeProvider {
    let providerID = "zoo_fm_provider"
    let displayName = "ZooFMProvider"

    func availability(for context: ExternalRuntimeContext) -> ExternalRuntimeAvailability {
        #if canImport(ZooFMProvider)
        var details: [String] = [
            "ZooFMProvider is importable in this build.",
            "CoreAIChat does not wire this adapter into ChatModelRuntime yet."
        ]
        if let bundleURL = context.bundleURL {
            details.append("Bundle candidate: \(bundleURL.lastPathComponent)")
        } else {
            details.append("No local bundle path supplied yet.")
        }
        return .available(summary: details.joined(separator: " "))
        #else
        return .unavailable(
            reason: [
                "ZooFMProvider is not linked into CoreAIChat.",
                "Add the external package dependency only after providing a patched sibling coreai-models checkout and preserving BSD license notices."
            ].joined(separator: " ")
        )
        #endif
    }
}
