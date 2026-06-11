import Foundation
import Testing
@testable import CoreAIChatCore

struct ExternalRuntimeProviderTests {
    @Test func zooFMProviderAdapterReportsUnavailableWhenPackageIsNotLinked() {
        let adapter = ZooFMProviderAdapter()
        let availability = adapter.availability(
            for: ExternalRuntimeContext(
                modelID: "qwen3_5_0_8b_coreai_pipelined",
                bundleURL: URL(fileURLWithPath: "/tmp/qwen3_5_0_8b_decode_int8hu_perchan_sym")
            )
        )

        #if canImport(ZooFMProvider)
        switch availability {
        case .available(let summary):
            #expect(summary.contains("importable"))
        case .unavailable(let reason):
            Issue.record("Expected availability when ZooFMProvider is importable, got: \(reason)")
        }
        #else
        switch availability {
        case .available(let summary):
            Issue.record("Expected unavailable adapter, got: \(summary)")
        case .unavailable(let reason):
            #expect(reason.contains("not linked into CoreAIChat"))
            #expect(reason.contains("patched sibling coreai-models checkout"))
            #expect(!availability.isAvailable)
        }
        #endif
    }
}
