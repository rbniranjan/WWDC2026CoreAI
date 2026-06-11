import Foundation

enum ModelDownloadState: Equatable, Sendable {
    case notAvailable
    case notDownloaded
    case downloading(ModelDownloadProgress)
    case downloaded
    case failed(String)
    case unavailable(String)

    var displayText: String {
        switch self {
        case .notAvailable:
            "Manual only"
        case .notDownloaded:
            "Not downloaded"
        case .downloading(let progress):
            "Downloading \(Int(progress.fractionCompleted * 100))%"
        case .downloaded:
            "Downloaded"
        case .failed(let message):
            "Failed: \(message)"
        case .unavailable(let reason):
            "Unavailable: \(reason)"
        }
    }
}
