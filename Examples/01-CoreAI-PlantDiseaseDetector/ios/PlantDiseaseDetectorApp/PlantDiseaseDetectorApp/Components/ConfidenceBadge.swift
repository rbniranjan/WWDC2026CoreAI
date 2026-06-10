import SwiftUI

struct ConfidenceBadge: View {
    let confidence: Double

    private var color: Color {
        switch confidence {
        case 0.8...:
            return .green
        case 0.55...:
            return .orange
        default:
            return .gray
        }
    }

    var body: some View {
        Text(confidence.formatted(.percent.precision(.fractionLength(1))))
            .font(.caption.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

