import Foundation

struct PlantDiseaseClass: Codable, Identifiable, Hashable {
    let id: Int
    let name: String

    static let placeholderSubset: [PlantDiseaseClass] = [
        PlantDiseaseClass(id: 0, name: "Apple___Apple_scab"),
        PlantDiseaseClass(id: 1, name: "Apple___Black_rot"),
        PlantDiseaseClass(id: 2, name: "Corn___Common_rust"),
        PlantDiseaseClass(id: 3, name: "Grape___Black_rot"),
        PlantDiseaseClass(id: 4, name: "Tomato___Late_blight"),
    ]
}

struct PlantDiseaseLabelCatalog: Codable {
    let status: String
    let todo: String?
    let labels: [PlantDiseaseClass]
}

