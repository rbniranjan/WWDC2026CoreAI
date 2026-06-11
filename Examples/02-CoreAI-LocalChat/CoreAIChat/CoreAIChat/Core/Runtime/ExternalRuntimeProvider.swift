import Foundation

struct ExternalRuntimeContext: Equatable {
    var modelID: String?
    var bundleURL: URL?

    init(modelID: String? = nil, bundleURL: URL? = nil) {
        self.modelID = modelID
        self.bundleURL = bundleURL
    }
}

protocol ExternalRuntimeProvider {
    var providerID: String { get }
    var displayName: String { get }

    func availability(for context: ExternalRuntimeContext) -> ExternalRuntimeAvailability
}
