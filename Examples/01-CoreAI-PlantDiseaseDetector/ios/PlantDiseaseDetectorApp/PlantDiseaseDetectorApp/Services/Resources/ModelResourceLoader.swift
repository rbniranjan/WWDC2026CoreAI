import Foundation

struct RawDetectorModelContract: Codable, Equatable {
    struct TensorSpec: Codable, Equatable {
        let name: String
        let shape: [Int]
        let layout: String
        let dtype: String
        let semantic: String
    }

    let modelName: String
    let task: String
    let runtimeEntrypoint: String
    let input: TensorSpec
    let outputs: [TensorSpec]
    let classesCount: Int
    let confidenceThreshold: Double
    let iouThreshold: Double
    let postprocessingResponsibility: String
    let notes: [String]

    private enum CodingKeys: String, CodingKey {
        case modelName = "model_name"
        case task
        case runtimeEntrypoint = "runtime_entrypoint"
        case input
        case outputs
        case classesCount = "classes_count"
        case confidenceThreshold = "confidence_threshold"
        case iouThreshold = "iou_threshold"
        case postprocessingResponsibility = "postprocessing_responsibility"
        case notes
    }
}

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

    func loadModelContract() -> RawDetectorModelContract? {
        guard let url = bundle.url(
            forResource: "model_contract",
            withExtension: "json",
            subdirectory: "Resources/ModelContract"
        ) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(RawDetectorModelContract.self, from: data)
        } catch {
            return nil
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
