import Foundation

enum CatalogModelKind: String, Hashable {
    case internalModel
    case externalModel
}

struct CatalogModelReference: Hashable, Identifiable {
    let kind: CatalogModelKind
    let modelID: String

    var id: String {
        "\(kind.rawValue):\(modelID)"
    }
}

@MainActor
final class ModelLibraryViewModel: ObservableObject {
    @Published private(set) var models: [ModelVariant] = []
    @Published private(set) var externalModels: [CoreAIExternalModelProfile] = []
    @Published private(set) var availability: [String: ModelAvailability] = [:]
    @Published private(set) var downloadStates: [String: ModelDownloadState] = [:]
    @Published private(set) var manifestSource: ManifestSource = .bundled
    @Published private(set) var activeModelID: String?
    @Published private(set) var settings: AppSettings
    @Published var loadError: String?
    @Published private(set) var externalCatalogLoadError: String?

    private let catalogService: ModelCatalogService
    private let localModelStore: LocalModelStore
    private let activeModelStore: ActiveModelStore
    private let appSettingsStore: AppSettingsStore
    private let downloadManager: ModelDownloadManager
    private let externalRunnerRegistry: CoreAIModelRunnerRegistry

    init(
        catalogService: ModelCatalogService = ModelCatalogService(),
        localModelStore: LocalModelStore = LocalModelStore(),
        activeModelStore: ActiveModelStore = ActiveModelStore(),
        appSettingsStore: AppSettingsStore = AppSettingsStore(),
        downloadManager: ModelDownloadManager = ModelDownloadManager(),
        externalRunnerRegistry: CoreAIModelRunnerRegistry = .knownExternalModelRegistry()
    ) {
        self.catalogService = catalogService
        self.localModelStore = localModelStore
        self.activeModelStore = activeModelStore
        self.appSettingsStore = appSettingsStore
        self.downloadManager = downloadManager
        self.externalRunnerRegistry = externalRunnerRegistry
        self.activeModelID = activeModelStore.activeModelID
        self.settings = appSettingsStore.load()
    }

    var modelReferences: [CatalogModelReference] {
        models.map { CatalogModelReference(kind: .internalModel, modelID: $0.id) }
            + externalModels.map { CatalogModelReference(kind: .externalModel, modelID: $0.id) }
    }

    func load() async {
        settings = appSettingsStore.load()
        let result = await catalogService.loadCatalog(
            useRemote: settings.useRemoteManifest,
            remoteManifestURL: settings.remoteManifestURL
        )

        models = result.manifest.models
        do {
            externalModels = try catalogService.loadExternalCatalog().models
            externalCatalogLoadError = nil
        } catch {
            externalModels = []
            externalCatalogLoadError = error.localizedDescription
        }
        manifestSource = result.source
        activeModelID = activeModelStore.activeModelID
        refreshAvailabilityAndDownloadStates()
        loadError = nil

        if result.source == .remote {
            settings.lastManifestRefreshDate = Date()
            appSettingsStore.save(settings)
        }
    }

    func availability(for model: ModelVariant) -> ModelAvailability {
        availability[model.id, default: .missing]
    }

    func isAvailable(_ model: ModelVariant) -> Bool {
        availability(for: model).isUsable
    }

    func isActive(_ model: ModelVariant) -> Bool {
        activeModelID == model.id
    }

    func isActive(_ reference: CatalogModelReference) -> Bool {
        reference.kind == .internalModel && activeModelID == reference.modelID
    }

    func internalModel(for reference: CatalogModelReference) -> ModelVariant? {
        guard reference.kind == .internalModel else { return nil }
        return models.first(where: { $0.id == reference.modelID })
    }

    func externalModel(for reference: CatalogModelReference) -> CoreAIExternalModelProfile? {
        guard reference.kind == .externalModel else { return nil }
        return externalModels.first(where: { $0.id == reference.modelID })
    }

    func setActive(_ model: ModelVariant) {
        guard isAvailable(model) else { return }
        activeModelStore.activeModelID = model.id
        activeModelID = model.id
    }

    func updateSettings(_ settings: AppSettings) {
        let normalized = AppSettings(
            generationSettings: settings.generationSettings.validated(),
            useRemoteManifest: settings.useRemoteManifest,
            remoteManifestURL: settings.remoteManifestURL,
            lastManifestRefreshDate: settings.lastManifestRefreshDate
        )
        self.settings = normalized
        appSettingsStore.save(normalized)
    }

    func resetSettings() async {
        appSettingsStore.reset()
        settings = appSettingsStore.load()
        await load()
    }

    func downloadState(for model: ModelVariant) -> ModelDownloadState {
        downloadStates[model.id, default: downloadManager.state(for: model)]
    }

    func downloadModel(_ model: ModelVariant) async {
        downloadStates[model.id] = .downloading(.starting)

        do {
            _ = try await downloadManager.startDownload(for: model) { [weak self] progress in
                Task { @MainActor in
                    self?.downloadStates[model.id] = .downloading(progress)
                }
            }
            downloadStates[model.id] = .downloaded
            refreshAvailabilityAndDownloadStates()
        } catch {
            downloadStates[model.id] = .failed(error.localizedDescription)
        }
    }

    func cancelDownload(_ model: ModelVariant) {
        downloadManager.cancelDownload(for: model)
        downloadStates[model.id] = downloadManager.state(for: model)
    }

    func retryDownload(_ model: ModelVariant) async {
        await downloadModel(model)
    }

    func deleteDownloadedArtifact(_ model: ModelVariant) {
        do {
            try downloadManager.deleteArtifact(for: model)
            refreshAvailabilityAndDownloadStates()
        } catch {
            downloadStates[model.id] = .failed(error.localizedDescription)
        }
    }

    var storageUsageText: String {
        ByteCountFormatter.string(fromByteCount: downloadManager.storageUsageBytes(), countStyle: .file)
    }

    var activeModelSummary: String {
        guard let activeModelID,
              let model = models.first(where: { $0.id == activeModelID }) else {
            return "No model selected — using mock runtime."
        }

        let availability = availability(for: model)
        if availability.isUsable {
            return "\(model.name) (\(availability.displayText))"
        }
        return "\(model.name) unavailable — using mock runtime."
    }

    func resolvedArtifacts(for profile: CoreAIExternalModelProfile) -> [CoreAIResolvedArtifact] {
        localModelStore.resolvedArtifacts(for: profile)
    }

    func preflight(for profile: CoreAIExternalModelProfile) -> CoreAIRunnerPreflightResult {
        externalRunnerRegistry.preflight(
            profile: profile,
            localArtifacts: resolvedArtifacts(for: profile),
            bundleRootURL: localModelStore.resolvedExternalBundleRootURL(for: profile)
        )
    }

    func missingRequiredArtifacts(for profile: CoreAIExternalModelProfile) -> [CoreAIModelArtifact] {
        CoreAIRunnerPreflightSupport.missingRequiredArtifacts(
            profile: profile,
            localArtifacts: resolvedArtifacts(for: profile)
        )
    }

    private func refreshAvailabilityAndDownloadStates() {
        availability = Dictionary(uniqueKeysWithValues: models.map { model in
            (model.id, localModelStore.availability(for: model))
        })
        downloadStates = Dictionary(uniqueKeysWithValues: models.map { model in
            (model.id, downloadStates[model.id] ?? downloadManager.state(for: model))
        })
    }
}
