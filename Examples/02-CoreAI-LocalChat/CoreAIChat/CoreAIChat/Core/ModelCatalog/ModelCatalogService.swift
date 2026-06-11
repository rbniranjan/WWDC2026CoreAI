import Foundation

enum ManifestSource: String, Codable, Equatable, Sendable {
    case bundled = "Bundled"
    case remote = "Remote"
    case cachedRemote = "Cached Remote"
    case fallbackBundled = "Fallback Bundled"
}

struct ModelCatalogResult: Equatable, Sendable {
    let manifest: ModelManifest
    let source: ManifestSource
}

struct ModelCatalogService: @unchecked Sendable {
    private let loader: BundleResourceLoader
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let fileManager: FileManager
    private let cacheDirectory: URL?
    private let remoteDataLoader: @Sendable (URL) async throws -> Data

    init(
        loader: BundleResourceLoader = BundleResourceLoader(),
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        fileManager: FileManager = .default,
        cacheDirectory: URL? = ModelCatalogService.defaultCacheDirectory(),
        remoteDataLoader: @escaping @Sendable (URL) async throws -> Data = { url in
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        }
    ) {
        self.loader = loader
        self.decoder = decoder
        self.encoder = encoder
        self.fileManager = fileManager
        self.cacheDirectory = cacheDirectory
        self.remoteDataLoader = remoteDataLoader
    }

    func loadManifest() throws -> ModelManifest {
        let data = try loader.loadData(
            named: "model_manifest.json",
            subdirectory: "Resources/ModelManifest"
        )
        return try Self.decodeManifest(from: data, decoder: decoder)
    }

    func loadCatalog(useRemote: Bool, remoteManifestURL: String?) async -> ModelCatalogResult {
        guard useRemote,
              let remoteManifestURL,
              let url = URL(string: remoteManifestURL),
              ["http", "https", "file"].contains(url.scheme?.lowercased() ?? "") else {
            return bundledResult(source: .bundled)
        }

        do {
            let data = try await remoteDataLoader(url)
            let manifest = try Self.decodeManifest(from: data, decoder: decoder)
            try cacheRemoteManifestData(data)
            return ModelCatalogResult(manifest: manifest, source: .remote)
        } catch {
            if let cached = try? loadCachedRemoteManifest() {
                return ModelCatalogResult(manifest: cached, source: .cachedRemote)
            }
            return bundledResult(source: .fallbackBundled)
        }
    }

    static func decodeManifest(from data: Data, decoder: JSONDecoder = JSONDecoder()) throws -> ModelManifest {
        try decoder.decode(ModelManifest.self, from: data)
    }

    private func bundledResult(source: ManifestSource) -> ModelCatalogResult {
        do {
            return ModelCatalogResult(manifest: try loadManifest(), source: source)
        } catch {
            return ModelCatalogResult(manifest: ModelManifest(schemaVersion: 1, models: []), source: source)
        }
    }

    private var cacheURL: URL? {
        cacheDirectory?.appendingPathComponent("remote_model_manifest.json")
    }

    private func cacheRemoteManifestData(_ data: Data) throws {
        guard let cacheDirectory, let cacheURL else { return }
        try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try data.write(to: cacheURL, options: .atomic)
    }

    private func loadCachedRemoteManifest() throws -> ModelManifest {
        guard let cacheURL else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try Data(contentsOf: cacheURL)
        return try Self.decodeManifest(from: data, decoder: decoder)
    }

    private static func defaultCacheDirectory() -> URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("CoreAIChat", isDirectory: true)
    }
}
