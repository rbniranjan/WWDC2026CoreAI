import Testing
@testable import CoreAIChatCore

@MainActor
struct MockChatRuntimeTests {
    @Test func generatesUsefulDemoResponse() async throws {
        let runtime = MockChatRuntime()
        await runtime.load(model: nil, localURL: nil)

        let response = try await runtime.generateResponse(
            for: [ChatMessage(role: .user, content: "How do local models work?")],
            settings: .default
        )

        #expect(response.contains("mock"))
        #expect(response.contains("How do local models work?"))
    }
}
