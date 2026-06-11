import Foundation

struct LocalModelStore {
    private let bundle: Bundle
    private let fileManager: FileManager
    private let applicationSupportDirectory: URL?

    init(
        bundle: Bundle = .main,
        fileManager: FileManager = .default,
        applicationSupportDirectory: URL? = nil
    ) {
        self.bundle = bundle
        self.fileManager = fileManager
        self.applicationSupportDirectory = applicationSupportDirectory
    }

    func localURL(for model: ModelVariant) -> URL? {
        if let bundledURL = bundledModelURL(fileName: model.fileName),
           fileManager.fileExists(atPath: bundledURL.path) {
            return bundledURL
        }

        if let supportURL = applicationSupportModelURL(fileName: model.fileName),
           fileManager.fileExists(atPath: supportURL.path) {
            return supportURL
        }

        return nil
    }

    func isAvailableLocally(_ model: ModelVariant) -> Bool {
        localURL(for: model) != nil
    }

    func bundledModelURL(fileName: String) -> URL? {
        let resourceName = (fileName as NSString).deletingPathExtension
        let resourceExtension = (fileName as NSString).pathExtension

        return bundle.url(
            forResource: resourceName,
            withExtension: resourceExtension.isEmpty ? nil : resourceExtension,
            subdirectory: "Resources/AIModels"
        )
    }

    func applicationSupportModelURL(fileName: String) -> URL? {
        guard let applicationSupportDirectory else { return nil }
        return applicationSupportDirectory
            .appendingPathComponent("AIModels", isDirectory: true)
            .appendingPathComponent(fileName)
    }
}
