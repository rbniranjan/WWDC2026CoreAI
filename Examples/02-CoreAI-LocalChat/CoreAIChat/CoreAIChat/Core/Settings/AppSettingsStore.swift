import Foundation

struct AppSettings: Codable, Equatable, Sendable {
    var generationSettings: ChatGenerationSettings
    var useRemoteManifest: Bool
    var remoteManifestURL: String
    var lastManifestRefreshDate: Date?

    static let `default` = AppSettings(
        generationSettings: .default,
        useRemoteManifest: false,
        remoteManifestURL: "",
        lastManifestRefreshDate: nil
    )
}

struct AppSettingsStore {
    private let defaults: UserDefaults
    private let key: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        defaults: UserDefaults = .standard,
        key: String = "CoreAIChat.appSettings",
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.defaults = defaults
        self.key = key
        self.encoder = encoder
        self.decoder = decoder
    }

    func load() -> AppSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? decoder.decode(AppSettings.self, from: data) else {
            return .default
        }
        return AppSettings(
            generationSettings: settings.generationSettings.validated(),
            useRemoteManifest: settings.useRemoteManifest,
            remoteManifestURL: settings.remoteManifestURL,
            lastManifestRefreshDate: settings.lastManifestRefreshDate
        )
    }

    func save(_ settings: AppSettings) {
        let normalized = AppSettings(
            generationSettings: settings.generationSettings.validated(),
            useRemoteManifest: settings.useRemoteManifest,
            remoteManifestURL: settings.remoteManifestURL.trimmingCharacters(in: .whitespacesAndNewlines),
            lastManifestRefreshDate: settings.lastManifestRefreshDate
        )

        guard let data = try? encoder.encode(normalized) else { return }
        defaults.set(data, forKey: key)
    }

    func reset() {
        defaults.removeObject(forKey: key)
    }
}
