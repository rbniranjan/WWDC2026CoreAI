import Foundation

struct DownloadedModelArtifact: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let modelID: String
    let fileName: String
    let artifactType: String
    let localURL: URL
    let sizeBytes: Int64
    let sha256: String?
    let downloadedAt: Date

    var isRuntimeReadyAimodel: Bool {
        artifactType.lowercased() == "aimodel"
    }
}
