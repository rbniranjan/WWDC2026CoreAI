import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published private(set) var activeModel: ModelVariant?
    @Published private(set) var activeModelAvailability: ModelAvailability = .missing
    @Published private(set) var runtimeStatus: RuntimeStatus = .idle
    @Published private(set) var isGenerating = false

    private let runtime: ChatModelRuntime
    private let catalogService: ModelCatalogService
    private let activeModelStore: ActiveModelStore
    private let localModelStore: LocalModelStore
    private let appSettingsStore: AppSettingsStore

    init(
        runtime: ChatModelRuntime = MockChatRuntime(),
        catalogService: ModelCatalogService = ModelCatalogService(),
        activeModelStore: ActiveModelStore = ActiveModelStore(),
        localModelStore: LocalModelStore = LocalModelStore(),
        appSettingsStore: AppSettingsStore = AppSettingsStore()
    ) {
        self.runtime = runtime
        self.catalogService = catalogService
        self.activeModelStore = activeModelStore
        self.localModelStore = localModelStore
        self.appSettingsStore = appSettingsStore
    }

    var activeModelDisplayName: String {
        guard let activeModel else {
            return "No model selected — using mock runtime."
        }

        if activeModelAvailability.isUsable {
            return activeModel.name
        }

        return "\(activeModel.name) unavailable — using mock runtime."
    }

    var runtimeModeText: String {
        guard activeModel != nil else {
            return "Mock runtime"
        }

        if activeModelAvailability.isUsable {
            return "Core AI boundary"
        }

        return "\(activeModelAvailability.displayText) - mock fallback"
    }

    func refreshActiveModel() async {
        let settings = appSettingsStore.load()
        let result = await catalogService.loadCatalog(
            useRemote: settings.useRemoteManifest,
            remoteManifestURL: settings.remoteManifestURL
        )

        guard let activeID = activeModelStore.activeModelID,
              let model = result.manifest.models.first(where: { $0.id == activeID }) else {
            activeModel = nil
            activeModelAvailability = .missing
            await runtime.load(model: nil, localURL: nil)
            runtimeStatus = runtime.status
            return
        }

        activeModel = model
        activeModelAvailability = localModelStore.availability(for: model)
        await runtime.load(model: activeModelAvailability.isUsable ? model : nil, localURL: localModelStore.localURL(for: model))
        runtimeStatus = runtime.status
    }

    func send() async {
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty, !isGenerating else { return }

        let userMessage = ChatMessage(role: .user, content: trimmedInput)
        messages.append(userMessage)
        inputText = ""
        isGenerating = true

        do {
            let response = try await runtime.generateResponse(
                for: messages,
                settings: appSettingsStore.load().generationSettings
            )
            messages.append(ChatMessage(role: .assistant, content: response))
        } catch {
            messages.append(ChatMessage(role: .assistant, content: error.localizedDescription))
        }

        runtimeStatus = runtime.status
        isGenerating = false
    }

    func clearChat() {
        messages = []
    }

    func useSuggestedPrompt(_ prompt: String) async {
        inputText = prompt
        await send()
    }
}
