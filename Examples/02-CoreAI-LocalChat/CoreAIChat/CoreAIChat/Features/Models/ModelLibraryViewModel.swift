import Foundation

@MainActor
final class ModelLibraryViewModel: ObservableObject {
    @Published private(set) var models: [ModelVariant] = []
    @Published private(set) var availability: [String: Bool] = [:]
    @Published private(set) var activeModelID: String?
    @Published var loadError: String?

    private let catalogService: ModelCatalogService
    private let localModelStore: LocalModelStore
    private let activeModelStore: ActiveModelStore

    init(
        catalogService: ModelCatalogService = ModelCatalogService(),
        localModelStore: LocalModelStore = LocalModelStore(),
        activeModelStore: ActiveModelStore = ActiveModelStore()
    ) {
        self.catalogService = catalogService
        self.localModelStore = localModelStore
        self.activeModelStore = activeModelStore
        self.activeModelID = activeModelStore.activeModelID
    }

    func load() {
        do {
            let manifest = try catalogService.loadManifest()
            models = manifest.models
            activeModelID = activeModelStore.activeModelID
            availability = Dictionary(uniqueKeysWithValues: manifest.models.map { model in
                (model.id, localModelStore.isAvailableLocally(model))
            })
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    func isAvailable(_ model: ModelVariant) -> Bool {
        availability[model.id, default: false]
    }

    func isActive(_ model: ModelVariant) -> Bool {
        activeModelID == model.id
    }

    func setActive(_ model: ModelVariant) {
        activeModelStore.activeModelID = model.id
        activeModelID = model.id
    }
}
