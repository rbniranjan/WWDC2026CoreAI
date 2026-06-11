import Foundation

struct ModelCatalogService {
    private let loader: BundleResourceLoader
    private let decoder: JSONDecoder

    init(loader: BundleResourceLoader = BundleResourceLoader(), decoder: JSONDecoder = JSONDecoder()) {
        self.loader = loader
        self.decoder = decoder
    }

    func loadManifest() throws -> ModelManifest {
        let data = try loader.loadData(
            named: "model_manifest.json",
            subdirectory: "Resources/ModelManifest"
        )
        return try Self.decodeManifest(from: data, decoder: decoder)
    }

    static func decodeManifest(from data: Data, decoder: JSONDecoder = JSONDecoder()) throws -> ModelManifest {
        try decoder.decode(ModelManifest.self, from: data)
    }
}
