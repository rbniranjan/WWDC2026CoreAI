import Foundation

struct ModelVariant: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let family: String
    let format: String
    let quantization: String
    let fileName: String
    let contextWindow: Int
    let estimatedSize: String?
    let description: String
}
