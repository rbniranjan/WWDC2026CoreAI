import Foundation

@MainActor
final class ChatRuntimeRouter: ChatModelRuntime {
    private enum Route: Equatable {
        case mock
        case externalQwen(ExternalRuntimeContext)
        case externalQwenUnavailable(ExternalRuntimeContext, reason: String)
    }

    static let qwenPlaceholderModelID = "qwen-small-q4-placeholder"
    static let qwenLocalBundleDirectoryName = "qwen3_5_0_8b_decode_int8hu_perchan_sym"

    private(set) var status: RuntimeStatus = .idle
    private(set) var externalRuntimeStatusLine = "External runtime: disabled"

    private let mockRuntime: ChatModelRuntime
    private let externalRuntimeProvider: ExternalRuntimeProvider
    private let qwenBundleResolver: () -> URL?

    private var route: Route = .mock
    private var selectedModel: ModelVariant?

    init(
        mockRuntime: ChatModelRuntime = MockChatRuntime(),
        externalRuntimeProvider: ExternalRuntimeProvider = ZooFMProviderAdapter(),
        qwenBundleResolver: (() -> URL?)? = nil,
        localModelStore: LocalModelStore = LocalModelStore()
    ) {
        self.mockRuntime = mockRuntime
        self.externalRuntimeProvider = externalRuntimeProvider
        self.qwenBundleResolver = qwenBundleResolver ?? {
            localModelStore.externalBundleRootURL(
                directoryName: Self.qwenLocalBundleDirectoryName
            )
        }
    }

    func load(model: ModelVariant?, localURL: URL?) async {
        selectedModel = model
        await mockRuntime.load(model: model, localURL: localURL)

        guard let model else {
            route = .mock
            status = mockRuntime.status
            externalRuntimeStatusLine = "External runtime: disabled"
            return
        }

        guard Self.isQwenCandidate(model) else {
            route = .mock
            status = mockRuntime.status
            externalRuntimeStatusLine = "External runtime: disabled"
            return
        }

        let context = ExternalRuntimeContext(
            modelID: model.id,
            modelName: model.name,
            bundleURL: qwenBundleResolver()
        )

        switch externalRuntimeProvider.availability(for: context) {
        case .available:
            route = .externalQwen(context)
            externalRuntimeStatusLine = "External runtime: available"
            status = .ready("\(model.name) via ZooFMProvider")
        case .unavailable(let reason):
            route = .externalQwenUnavailable(context, reason: reason)
            externalRuntimeStatusLine = "External runtime: unavailable"
            status = .unavailable(reason)
        }
    }

    func generateResponse(
        for messages: [ChatMessage],
        settings: ChatGenerationSettings
    ) async throws -> String {
        switch route {
        case .mock:
            let response = try await mockRuntime.generateResponse(for: messages, settings: settings)
            status = mockRuntime.status
            externalRuntimeStatusLine = "External runtime: disabled"
            return response

        case .externalQwen(let context):
            externalRuntimeStatusLine = "External runtime: running"
            status = .generating

            do {
                let response = try await externalRuntimeProvider.generateResponse(
                    for: messages,
                    settings: settings,
                    context: context
                )
                externalRuntimeStatusLine = "External runtime: available"
                status = .ready("\(selectedModel?.name ?? "Qwen") via ZooFMProvider")
                return response
            } catch {
                externalRuntimeStatusLine = "External runtime: failed"
                status = .failed(error.localizedDescription)
                throw error
            }

        case .externalQwenUnavailable(_, let reason):
            externalRuntimeStatusLine = "External runtime: unavailable"
            status = .failed(reason)
            throw ExternalRuntimeProviderError.unavailable(reason)
        }
    }

    private static func isQwenCandidate(_ model: ModelVariant) -> Bool {
        model.id == qwenPlaceholderModelID || model.family.localizedCaseInsensitiveContains("qwen")
    }
}
