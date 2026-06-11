import Foundation
import Testing
@testable import CoreAIChatCore

struct ActiveModelStoreTests {
    @Test func persistsAndClearsActiveModelID() {
        let suiteName = "CoreAIChatTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = ActiveModelStore(defaults: defaults)
        store.activeModelID = "local-demo"

        #expect(store.activeModelID == "local-demo")

        store.clear()

        #expect(store.activeModelID == nil)
    }
}
