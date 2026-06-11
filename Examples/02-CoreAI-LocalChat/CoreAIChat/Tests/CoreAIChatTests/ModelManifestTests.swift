import Foundation
import Testing
@testable import CoreAIChatCore

struct ModelManifestTests {
    @Test func decodesManifestModels() throws {
        let json = """
        {
          "schemaVersion": 1,
          "models": [
            {
              "id": "demo",
              "name": "Demo",
              "family": "Core AI",
              "format": "aimodel",
              "quantization": "Q4",
              "fileName": "demo.aimodel",
              "contextWindow": 4096,
              "estimatedSize": "1 GB",
              "description": "Demo model"
            }
          ]
        }
        """.data(using: .utf8)!

        let manifest = try ModelCatalogService.decodeManifest(from: json)

        #expect(manifest.schemaVersion == 1)
        #expect(manifest.models.count == 1)
        #expect(manifest.models[0].fileName == "demo.aimodel")
        #expect(manifest.models[0].downloadSupported == false)
    }

    @Test func decodesDownloadableManifestModel() throws {
        let json = """
        {
          "schemaVersion": 1,
          "models": [
            {
              "id": "downloadable",
              "name": "Downloadable",
              "family": "Gemma",
              "format": "aimodel",
              "quantization": "Q4",
              "fileName": "downloadable.aimodel",
              "contextWindow": 8192,
              "expectedSizeBytes": 12,
              "isBundled": false,
              "downloadSupported": true,
              "downloadURL": "https://example.com/downloadable.zip",
              "artifactFileName": "downloadable.zip",
              "artifactType": "zip",
              "sha256": "abc",
              "minimumOS": "iOS 18",
              "supportedDevices": ["iPhone", "Mac"],
              "description": "Downloadable model"
            }
          ]
        }
        """.data(using: .utf8)!

        let manifest = try ModelCatalogService.decodeManifest(from: json)
        let model = try #require(manifest.models.first)

        #expect(model.downloadSupported)
        #expect(model.expectedSizeBytes == 12)
        #expect(model.artifactType == "zip")
        #expect(model.supportedDevices == ["iPhone", "Mac"])
    }

    @Test func remoteManifestFallsBackToCachedRemote() async throws {
        let cachedJSON = """
        {
          "schemaVersion": 1,
          "models": [
            {
              "id": "cached",
              "name": "Cached",
              "family": "Core AI",
              "format": "aimodel",
              "quantization": "Q4",
              "fileName": "cached.aimodel",
              "contextWindow": 2048,
              "description": "Cached model"
            }
          ]
        }
        """.data(using: .utf8)!
        let cacheDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try cachedJSON.write(to: cacheDirectory.appendingPathComponent("remote_model_manifest.json"))

        let service = ModelCatalogService(cacheDirectory: cacheDirectory) { _ in
            throw URLError(.notConnectedToInternet)
        }

        let result = await service.loadCatalog(useRemote: true, remoteManifestURL: "https://example.com/manifest.json")

        #expect(result.source == .cachedRemote)
        #expect(result.manifest.models.first?.id == "cached")
    }

    @Test func remoteManifestSuccessUsesRemoteSource() async throws {
        let remoteJSON = """
        {
          "schemaVersion": 1,
          "models": [
            {
              "id": "remote",
              "name": "Remote",
              "family": "Core AI",
              "format": "aimodel",
              "quantization": "Q4",
              "fileName": "remote.aimodel",
              "contextWindow": 2048,
              "description": "Remote model"
            }
          ]
        }
        """.data(using: .utf8)!
        let cacheDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let service = ModelCatalogService(cacheDirectory: cacheDirectory) { _ in
            remoteJSON
        }

        let result = await service.loadCatalog(useRemote: true, remoteManifestURL: "https://example.com/manifest.json")

        #expect(result.source == .remote)
        #expect(result.manifest.models.first?.id == "remote")
    }
}
