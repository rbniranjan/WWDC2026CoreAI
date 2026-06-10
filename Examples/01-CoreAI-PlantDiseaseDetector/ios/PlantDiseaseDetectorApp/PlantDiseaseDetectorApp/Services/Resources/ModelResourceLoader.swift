import Foundation

struct ModelResourceLoader {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func loadLabels() -> [PlantDiseaseClass] {
        guard let url = bundle.url(
            forResource: "plant_disease_labels",
            withExtension: "json",
            subdirectory: "Resources/Labels"
        ) else {
            return PlantDiseaseClass.placeholderSubset
        }

        do {
            let data = try Data(contentsOf: url)
            let catalog = try JSONDecoder().decode(PlantDiseaseLabelCatalog.self, from: data)
            return catalog.labels.isEmpty ? PlantDiseaseClass.placeholderSubset : catalog.labels
        } catch {
            return PlantDiseaseClass.placeholderSubset
        }
    }

    func primaryModelAssetURL() -> URL? {
        guard let aiModelsURL = bundle.url(forResource: "AIModels", withExtension: nil, subdirectory: "Resources"),
              let urls = try? FileManager.default.contentsOfDirectory(
                at: aiModelsURL,
                includingPropertiesForKeys: nil
              ) else {
            return nil
        }

        return urls.first { url in
            let filename = url.lastPathComponent.lowercased()
            return filename.hasPrefix(".") == false && filename != "readme.md"
        }
    }
}

