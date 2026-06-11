import Foundation
import Testing
@testable import CoreAIChatCore

struct AppSettingsStoreTests {
    @Test func returnsDefaultsAndPersistsSettings() {
        let suiteName = "CoreAIChatSettingsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = AppSettingsStore(defaults: defaults)
        #expect(store.load().generationSettings.contextWindow == 2_048)
        #expect(store.load().generationSettings.maxOutputTokens == 512)

        var settings = store.load()
        settings.useRemoteManifest = true
        settings.remoteManifestURL = " https://example.com/manifest.json "
        settings.generationSettings.temperature = 3
        store.save(settings)

        let loaded = store.load()
        #expect(loaded.useRemoteManifest)
        #expect(loaded.remoteManifestURL == "https://example.com/manifest.json")
        #expect(loaded.generationSettings.temperature == 2)

        store.reset()
        #expect(store.load() == .default)
    }

    @Test func generationSettingsValidationClampsValues() {
        let settings = ChatGenerationSettings(
            contextWindow: 1,
            temperature: 5,
            maxOutputTokens: 0,
            topP: 5
        ).validated()

        #expect(settings.contextWindow == 256)
        #expect(settings.temperature == 2)
        #expect(settings.maxOutputTokens == 1)
        #expect(settings.topP == 1)
    }
}
