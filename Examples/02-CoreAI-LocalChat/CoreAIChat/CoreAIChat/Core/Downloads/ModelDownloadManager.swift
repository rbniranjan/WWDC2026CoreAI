import Foundation

final class ModelDownloadManager: @unchecked Sendable {
    enum DownloadError: Error, LocalizedError {
        case downloadNotSupported
        case invalidDownloadURL

        var errorDescription: String? {
            switch self {
            case .downloadNotSupported:
                "This model does not support downloads."
            case .invalidDownloadURL:
                "The model download URL is missing or invalid."
            }
        }
    }

    private let fileManager: FileManager
    private let storageDirectory: URL
    private let checksumVerifier: ModelChecksumVerifier
    private let dataLoader: @Sendable (URL) async throws -> Data

    init(
        fileManager: FileManager = .default,
        storageDirectory: URL = ModelDownloadManager.defaultStorageDirectory(),
        checksumVerifier: ModelChecksumVerifier = ModelChecksumVerifier(),
        dataLoader: @escaping @Sendable (URL) async throws -> Data = { url in
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        }
    ) {
        self.fileManager = fileManager
        self.storageDirectory = storageDirectory
        self.checksumVerifier = checksumVerifier
        self.dataLoader = dataLoader
    }

    func state(for model: ModelVariant) -> ModelDownloadState {
        guard model.downloadSupported else { return .notAvailable }

        if fileManager.fileExists(atPath: localArtifactURL(for: model).path) {
            return .downloaded
        }

        guard model.downloadURL != nil else {
            return .unavailable("Download URL is not configured.")
        }

        return .notDownloaded
    }

    func startDownload(
        for model: ModelVariant,
        progress: @escaping @Sendable (ModelDownloadProgress) -> Void = { _ in }
    ) async throws -> DownloadedModelArtifact {
        guard model.downloadSupported else {
            throw DownloadError.downloadNotSupported
        }
        guard let downloadURLString = model.downloadURL,
              let downloadURL = URL(string: downloadURLString) else {
            throw DownloadError.invalidDownloadURL
        }

        progress(.starting)
        let data = try await dataLoader(downloadURL)
        let actualSHA256 = try checksumVerifier.verify(data: data, expectedSHA256: model.sha256)
        try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)

        let destinationURL = localArtifactURL(for: model)
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try data.write(to: destinationURL, options: .atomic)
        progress(ModelDownloadProgress(bytesReceived: Int64(data.count), totalBytes: Int64(data.count)))

        return DownloadedModelArtifact(
            id: model.id,
            modelID: model.id,
            fileName: destinationURL.lastPathComponent,
            artifactType: model.artifactType ?? destinationURL.pathExtension,
            localURL: destinationURL,
            sizeBytes: Int64(data.count),
            sha256: actualSHA256,
            downloadedAt: Date()
        )
    }

    func cancelDownload(for model: ModelVariant) {
        // Streaming cancellation will be added when downloads move to URLSessionDownloadTask.
    }

    func deleteArtifact(for model: ModelVariant) throws {
        let url = localArtifactURL(for: model)
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    func localArtifactURL(for model: ModelVariant) -> URL {
        storageDirectory.appendingPathComponent(artifactFileName(for: model))
    }

    func storageUsageBytes() -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: storageDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        return enumerator.compactMap { item -> Int64? in
            guard let url = item as? URL,
                  let values = try? url.resourceValues(forKeys: [.fileSizeKey]) else {
                return nil
            }
            return Int64(values.fileSize ?? 0)
        }
        .reduce(0, +)
    }

    private func artifactFileName(for model: ModelVariant) -> String {
        model.artifactFileName
            ?? model.downloadURL.flatMap { URL(string: $0)?.lastPathComponent }
            ?? "\(model.id).download"
    }

    static func defaultStorageDirectory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("CoreAIChat", isDirectory: true)
            .appendingPathComponent("DownloadedModels", isDirectory: true)
        ?? URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("CoreAIChat", isDirectory: true)
            .appendingPathComponent("DownloadedModels", isDirectory: true)
    }
}
