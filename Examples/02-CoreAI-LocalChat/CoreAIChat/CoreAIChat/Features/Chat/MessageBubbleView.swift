import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack {
            if isUser {
                Spacer(minLength: 56)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: AppSpacing.xs) {
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(isUser ? .white : .primary)
                    .textSelection(.enabled)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.md)
                    .background(isUser ? AppColors.userBubble : AppColors.assistantBubble)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(metadataText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 620, alignment: isUser ? .trailing : .leading)

            if !isUser {
                Spacer(minLength: 56)
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    private var metadataText: String {
        let role = isUser ? "You" : "Assistant"
        return "\(role) - \(message.createdAt.formatted(date: .omitted, time: .shortened))"
    }
}
