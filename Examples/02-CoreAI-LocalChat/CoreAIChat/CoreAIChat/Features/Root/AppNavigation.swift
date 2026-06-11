import Foundation

enum AppNavigation: String, CaseIterable, Hashable, Identifiable {
    case chat
    case models
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chat:
            "Chat"
        case .models:
            "Models"
        case .settings:
            "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .chat:
            "bubble.left.and.bubble.right"
        case .models:
            "cpu"
        case .settings:
            "gearshape"
        }
    }
}
