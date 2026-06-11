import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum AppColors {
    static let background = platformBackground
    static let surface = platformSurface
    static let elevatedSurface = platformElevatedSurface
    static let groupedBackground = platformBackground
    static let userBubble = Color.accentColor
    static let assistantBubble = platformAssistantBubble
    static let separator = platformSeparator
    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red
    static let neutral = Color.secondary
}

private extension AppColors {
    static let platformBackground: Color = {
        #if canImport(UIKit)
        Color(uiColor: .systemGroupedBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #endif
    }()

    static let platformSurface: Color = {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #endif
    }()

    static let platformElevatedSurface: Color = {
        #if canImport(UIKit)
        Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .textBackgroundColor)
        #endif
    }()

    static let platformAssistantBubble: Color = {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemGroupedBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .unemphasizedSelectedContentBackgroundColor)
        #endif
    }()

    static let platformSeparator: Color = {
        #if canImport(UIKit)
        Color(uiColor: .separator)
        #elseif canImport(AppKit)
        Color(nsColor: .separatorColor)
        #endif
    }()
}
