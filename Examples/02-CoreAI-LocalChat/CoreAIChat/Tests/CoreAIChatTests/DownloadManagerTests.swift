import Foundation
import Testing
@testable import CoreAIChatCore

struct DownloadManagerTests {
    @Test func verifiesKnownSHA256() throws {
        let verifier = ModelChecksumVerifier()
        let data = Data("hello".utf8)

        #expect(verifier.sha256Hex(for: data) == "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
        #expect(throws: Never.self) {
            try verifier.verify(data: data, expectedSHA256: "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
        }
    }

    @Test func downloadManagerStoresAndDeletesArtifactWithoutNetwork() async throws {
        let storageDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let payload = Data("artifact".utf8)
        let checksum = ModelChecksumVerifier().sha256Hex(for: payload)
        let manager = ModelDownloadManager(storageDirectory: storageDirectory) { _ in payload }
        let model = ModelVariant(
            id: "downloadable",
            name: "Downloadable",
            family: "Core AI",
            format: "aimodel",
            quantization: "Q4",
            fileName: "downloadable.aimodel",
            contextWindow: 2048,
            description: "Downloadable test model",
            expectedSizeBytes: payload.count,
            downloadSupported: true,
            downloadURL: "https://example.com/downloadable.zip",
            artifactFileName: "downloadable.zip",
            artifactType: "zip",
            sha256: checksum
        )

        #expect(manager.state(for: model) == .notDownloaded)

        let artifact = try await manager.startDownload(for: model)

        #expect(FileManager.default.fileExists(atPath: artifact.localURL.path))
        #expect(manager.state(for: model) == .downloaded)
        #expect(manager.storageUsageBytes() == Int64(payload.count))

        try manager.deleteArtifact(for: model)

        #expect(manager.state(for: model) == .notDownloaded)
    }
}
