import Foundation

enum ModelAvailability: Equatable, Sendable {
    case bundled(URL)
    case downloaded(URL)
    case downloadedArchive(URL)
    case missing
    case unavailable(String)

    var isUsable: Bool {
        switch self {
        case .bundled, .downloaded:
            true
        case .downloadedArchive, .missing, .unavailable:
            false
        }
    }

    var displayText: String {
        switch self {
        case .bundled:
            "Local .aimodel"
        case .downloaded:
            "Downloaded .aimodel"
        case .downloadedArchive:
            "Downloaded archive"
        case .missing:
            "Missing"
        case .unavailable(let reason):
            reason
        }
    }
}

struct LocalModelStore {
    private let bundle: Bundle
    private let fileManager: FileManager
    private let applicationSupportDirectory: URL?

    init(
        bundle: Bundle = .main,
        fileManager: FileManager = .default,
        applicationSupportDirectory: URL? = LocalModelStore.defaultApplicationSupportDirectory()
    ) {
        self.bundle = bundle
        self.fileManager = fileManager
        self.applicationSupportDirectory = applicationSupportDirectory
    }

    func localURL(for model: ModelVariant) -> URL? {
        switch availability(for: model) {
        case .bundled(let url), .downloaded(let url):
            return url
        case .downloadedArchive, .missing, .unavailable:
            return nil
        }
    }

    func availability(for model: ModelVariant) -> ModelAvailability {
        if let bundledURL = bundledModelURL(fileName: model.fileName),
           fileManager.fileExists(atPath: bundledURL.path) {
            return .bundled(bundledURL)
        }

        if let supportURL = applicationSupportModelURL(fileName: model.fileName),
           fileManager.fileExists(atPath: supportURL.path) {
            return .downloaded(supportURL)
        }

        if let archiveURL = downloadedArchiveURL(for: model),
           fileManager.fileExists(atPath: archiveURL.path) {
            return .downloadedArchive(archiveURL)
        }

        return .missing
    }

    func isAvailableLocally(_ model: ModelVariant) -> Bool {
        availability(for: model).isUsable
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

    static func defaultApplicationSupportDirectory() -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("CoreAIChat", isDirectory: true)
    }

    func downloadedArchiveURL(for model: ModelVariant) -> URL? {
        guard let applicationSupportDirectory else { return nil }
        let fileName = model.artifactFileName
            ?? model.downloadURL.flatMap { URL(string: $0)?.lastPathComponent }
            ?? "\(model.id).download"

        return applicationSupportDirectory
            .appendingPathComponent("DownloadedModels", isDirectory: true)
            .appendingPathComponent(fileName)
    }

    func resolvedExternalBundleRootURL(for profile: CoreAIExternalModelProfile) -> URL? {
        let directoryNames = Array(NSOrderedSet(array: profile.artifacts.map(\.manualInstallDirectoryName))) as? [String]
            ?? profile.artifacts.map(\.manualInstallDirectoryName)
        let candidates = directoryNames.flatMap(externalBundleRootCandidates(for:))

        return candidates.first(where: bundleExists(at:)) ?? candidates.first
    }

    func externalBundleRootURL(directoryName: String) -> URL? {
        let candidates = externalBundleRootCandidates(for: directoryName)
        return candidates.first(where: bundleExists(at:)) ?? candidates.first
    }

    func resolvedArtifacts(for profile: CoreAIExternalModelProfile) -> [CoreAIResolvedArtifact] {
        let bundleRootURL = resolvedExternalBundleRootURL(for: profile)

        return profile.artifacts.map { artifact in
            let candidates = externalArtifactCandidates(for: artifact, bundleRootURL: bundleRootURL)
            let resolvedURL = candidates.first(where: { fileManager.fileExists(atPath: $0.path) }) ?? candidates.first
            let exists = resolvedURL.map { fileManager.fileExists(atPath: $0.path) } ?? false
            let isDirectory = resolvedURL.flatMap {
                try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory
            } ?? false

            return CoreAIResolvedArtifact(
                id: artifact.id,
                artifactRole: artifact.role,
                expectedDirectoryName: artifact.manualInstallDirectoryName,
                localURL: resolvedURL,
                exists: exists,
                isDirectory: isDirectory,
                notes: artifact.notes
            )
        }
    }

    private func externalArtifactCandidates(
        for artifact: CoreAIModelArtifact,
        bundleRootURL: URL?
    ) -> [URL] {
        var candidates: [URL] = []

        if let resolvedBundleArtifactURL = resolvedBundleArtifactURL(for: artifact, bundleRootURL: bundleRootURL) {
            candidates.append(resolvedBundleArtifactURL)
        }

        if let bundledAIModelsDirectoryURL {
            candidates.append(
                bundledAIModelsDirectoryURL
                    .appendingPathComponent(artifact.manualInstallDirectoryName, isDirectory: true)
            )
            candidates.append(
                bundledAIModelsDirectoryURL
                    .appendingPathComponent(artifact.fileName)
            )
        }
        if let applicationSupportDirectory {
            candidates.append(
                applicationSupportDirectory
                    .appendingPathComponent("AIModels", isDirectory: true)
                    .appendingPathComponent(artifact.manualInstallDirectoryName)
            )
            candidates.append(
                applicationSupportDirectory
                    .appendingPathComponent("AIModels", isDirectory: true)
                    .appendingPathComponent(artifact.fileName)
            )
            candidates.append(
                applicationSupportDirectory
                    .appendingPathComponent("DownloadedModels", isDirectory: true)
                    .appendingPathComponent(artifact.fileName)
            )
        }

        return Array(NSOrderedSet(array: candidates)) as? [URL] ?? candidates
    }

    private var bundledAIModelsDirectoryURL: URL? {
        bundle.bundleURL
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent("AIModels", isDirectory: true)
    }

    private func externalBundleRootCandidates(for directoryName: String) -> [URL] {
        var candidates: [URL] = []

        if let bundledAIModelsDirectoryURL {
            candidates.append(
                bundledAIModelsDirectoryURL
                    .appendingPathComponent(directoryName, isDirectory: true)
            )
        }
        if let applicationSupportDirectory {
            candidates.append(
                applicationSupportDirectory
                    .appendingPathComponent("AIModels", isDirectory: true)
                    .appendingPathComponent(directoryName, isDirectory: true)
            )
            candidates.append(
                applicationSupportDirectory
                    .appendingPathComponent("DownloadedModels", isDirectory: true)
                    .appendingPathComponent(directoryName, isDirectory: true)
            )
        }

        return Array(NSOrderedSet(array: candidates)) as? [URL] ?? candidates
    }

    private func resolvedBundleArtifactURL(
        for artifact: CoreAIModelArtifact,
        bundleRootURL: URL?
    ) -> URL? {
        guard let bundleRootURL else { return nil }

        if artifact.fileName == artifact.manualInstallDirectoryName {
            return bundleRootURL
        }

        let bundlePrefix = artifact.manualInstallDirectoryName + "/"
        if artifact.fileName.hasPrefix(bundlePrefix) {
            let relativePath = String(artifact.fileName.dropFirst(bundlePrefix.count))
            return bundleRootURL.appendingPathComponent(relativePath)
        }

        return bundleRootURL.appendingPathComponent(artifact.fileName)
    }

    private func bundleExists(at url: URL) -> Bool {
        var isDirectory = ObjCBool(false)
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}
