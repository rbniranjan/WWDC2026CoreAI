import Foundation
import Testing
@testable import CoreAIChatCore

@MainActor
struct ChatRuntimeRouterTests {
    @Test func chatRuntimeFallbackStillWorksForNonQwenModels() async throws {
        let runtime = ChatRuntimeRouter(qwenBundleResolver: { nil })
        await runtime.load(model: gemmaModel, localURL: nil)

        let response = try await runtime.generateResponse(
            for: [ChatMessage(role: .user, content: "How does fallback work?")],
            settings: .default
        )

        #expect(response.contains("mock"))
        #expect(runtime.externalRuntimeStatusLine == "External runtime: disabled")
    }

    @Test func qwenSelectedWithoutRuntimeShowsClearUnavailableMessage() async {
        let runtime = ChatRuntimeRouter(qwenBundleResolver: { nil })
        await runtime.load(model: qwenModel, localURL: nil)

        do {
            _ = try await runtime.generateResponse(
                for: [ChatMessage(role: .user, content: "Hello from Qwen")],
                settings: .default
            )
            Issue.record("Expected the Qwen route to fail clearly when the external runtime is disabled.")
        } catch {
            #expect(error.localizedDescription.contains("ENABLE_ZOO_FM_PROVIDER is not enabled"))
            #expect(runtime.externalRuntimeStatusLine == "External runtime: unavailable")

            switch runtime.status {
            case .failed(let reason):
                #expect(reason.contains("ENABLE_ZOO_FM_PROVIDER is not enabled"))
            default:
                Issue.record("Expected failed runtime status, got \(runtime.status.displayText)")
            }
        }
    }

    private var qwenModel: ModelVariant {
        ModelVariant(
            id: "qwen-small-q4-placeholder",
            name: "Qwen Small Q4 Placeholder",
            family: "Qwen",
            format: "aimodel",
            quantization: "Q4",
            fileName: "qwen-small-q4.aimodel",
            contextWindow: 8192,
            description: "Placeholder manifest record for a future Qwen-family local chat model."
        )
    }

    private var gemmaModel: ModelVariant {
        ModelVariant(
            id: "gemma-small-q4-placeholder",
            name: "Gemma Small Q4 Placeholder",
            family: "Gemma",
            format: "aimodel",
            quantization: "Q4",
            fileName: "gemma-small-q4.aimodel",
            contextWindow: 8192,
            description: "Placeholder manifest record for a future Gemma-family local chat model."
        )
    }
}
