import SwiftUI

struct CardView<Content: View>: View {
    let content: Content
    var padding: CGFloat
    var background: Color

    init(
        padding: CGFloat = AppSpacing.lg,
        background: Color = AppColors.elevatedSurface,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.background = background
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppColors.separator.opacity(0.35), lineWidth: 0.5)
            }
    }
}

struct StatusBadgeView: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
            .lineLimit(1)
    }
}

struct ModelAvailabilityBadge: View {
    let availability: ModelAvailability

    var body: some View {
        StatusBadgeView(
            title: availability.displayText,
            systemImage: systemImage,
            tint: tint
        )
    }

    private var systemImage: String {
        switch availability {
        case .bundled, .downloaded:
            "checkmark.circle.fill"
        case .downloadedArchive:
            "archivebox.fill"
        case .missing:
            "exclamationmark.triangle.fill"
        case .unavailable:
            "xmark.circle.fill"
        }
    }

    private var tint: Color {
        switch availability {
        case .bundled, .downloaded:
            AppColors.success
        case .downloadedArchive:
            AppColors.warning
        case .missing, .unavailable:
            AppColors.warning
        }
    }
}

struct RuntimeStatusView: View {
    let status: RuntimeStatus
    var compact = false

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            Text(status.displayText)
                .font(compact ? .caption : .subheadline)
                .foregroundStyle(compact ? .secondary : .primary)
                .lineLimit(2)
        }
    }

    private var systemImage: String {
        switch status {
        case .idle:
            "circle"
        case .loading:
            "arrow.triangle.2.circlepath"
        case .ready:
            "checkmark.circle.fill"
        case .generating:
            "sparkles"
        case .failed:
            "xmark.octagon.fill"
        case .unavailable:
            "exclamationmark.triangle.fill"
        }
    }

    private var tint: Color {
        switch status {
        case .ready:
            AppColors.success
        case .failed:
            AppColors.danger
        case .unavailable:
            AppColors.warning
        case .generating, .loading:
            Color.accentColor
        case .idle:
            AppColors.neutral
        }
    }
}

struct EmptyStateView<ActionContent: View>: View {
    let title: String
    let message: String
    let systemImage: String
    let actions: ActionContent

    init(
        title: String,
        message: String,
        systemImage: String,
        @ViewBuilder actions: () -> ActionContent = { EmptyView() }
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actions = actions()
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
            actions
                .padding(.top, AppSpacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xl)
    }
}

struct SectionHeaderView: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(.headline)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
