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
    }
}
