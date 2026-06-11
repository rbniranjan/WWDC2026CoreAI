import Foundation

struct ModelManifest: Codable, Equatable, Sendable {
    let schemaVersion: Int
    let models: [ModelVariant]
}
