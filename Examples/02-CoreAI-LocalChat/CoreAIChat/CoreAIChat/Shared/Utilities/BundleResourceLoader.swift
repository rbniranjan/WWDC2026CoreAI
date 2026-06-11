import Foundation

struct BundleResourceLoader {
    enum ResourceError: Error, LocalizedError {
        case missingResource(String)

        var errorDescription: String? {
            switch self {
            case .missingResource(let name):
                "Missing bundled resource: \(name)"
            }
        }
    }

    let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func loadData(named name: String, subdirectory: String? = nil) throws -> Data {
        let resourceName = (name as NSString).deletingPathExtension
        let resourceExtension = (name as NSString).pathExtension
        let url = bundle.url(
            forResource: resourceName,
            withExtension: resourceExtension.isEmpty ? nil : resourceExtension,
            subdirectory: subdirectory
        )

        guard let url else {
            throw ResourceError.missingResource([subdirectory, name].compactMap { $0 }.joined(separator: "/"))
        }

        return try Data(contentsOf: url)
    }
}
