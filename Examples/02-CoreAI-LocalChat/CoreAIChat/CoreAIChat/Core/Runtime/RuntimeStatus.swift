import Foundation

enum RuntimeStatus: Equatable, Sendable {
    case idle
    case loading(String)
    case ready(String)
    case generating
    case failed(String)
    case unavailable(String)

    var displayText: String {
        switch self {
        case .idle:
            "Idle"
        case .loading(let modelName):
            "Loading \(modelName)"
        case .ready(let modelName):
            "Ready: \(modelName)"
        case .generating:
            "Generating"
        case .failed(let reason):
            "Failed: \(reason)"
        case .unavailable(let reason):
            "Unavailable: \(reason)"
        }
    }
}
