import Foundation

enum ExternalRuntimeAvailability: Equatable {
    case available(summary: String)
    case unavailable(reason: String)

    var isAvailable: Bool {
        if case .available = self {
            return true
        }
        return false
    }

    var summary: String {
        switch self {
        case .available(let summary):
            summary
        case .unavailable(let reason):
            reason
        }
    }
}
