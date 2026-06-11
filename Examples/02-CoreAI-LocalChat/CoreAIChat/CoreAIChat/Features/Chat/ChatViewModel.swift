import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, content: "Ask a question to try the Phase 1 mock chat runtime.")
    ]
    @Published var inputText = ""
    @Published private(set) var activeModel: ModelVariant?
    @Published private(set) var runtimeStatus: RuntimeStatus = .idle
    @Published private(set) var isGenerating = false

    private let runtime: ChatModelRuntime
    private let catalogService: ModelCatalogService
    private let activeModelStore: ActiveModelStore
    private let localModelStore: LocalModelStore
    private let generationSettings: ChatGenerationSettings

    init(
        runtime: ChatModelRuntime = MockChatRuntime(),
        catalogService: ModelCatalogService = ModelCatalogService(),
        activeModelStore: ActiveModelStore = ActiveModelStore(),
        localModelStore: LocalModelStore = LocalModelStore(),
        generationSettings: ChatGenerationSettings = .default
    ) {
        self.runtime = runtime
        self.catalogService = catalogService
        self.activeModelStore = activeModelStore
        self.localModelStore = localModelStore
        self.generationSettings = generationSettings
    }

    var activeModelDisplayName: String {
        activeModel?.name ?? "No model selected — using mock runtime."
    }

    func refreshActiveModel() async {
        guard let activeID = activeModelStore.activeModelID,
              let manifest = try? catalogService.loadManifest(),
              let model = manifest.models.first(where: { $0.id == activeID }) else {
            activeModel = nil
            await runtime.load(model: nil, localURL: nil)
            runtimeStatus = runtime.status
            return
        }

        activeModel = model
        await runtime.load(model: model, localURL: localModelStore.localURL(for: model))
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
                settings: generationSettings
            )
            messages.append(ChatMessage(role: .assistant, content: response))
        } catch {
            messages.append(ChatMessage(role: .assistant, content: error.localizedDescription))
        }

        runtimeStatus = runtime.status
        isGenerating = false
    }

    func clearChat() {
        messages = [
            ChatMessage(role: .assistant, content: "Chat cleared. Send a message to start again.")
        ]
    }
}
