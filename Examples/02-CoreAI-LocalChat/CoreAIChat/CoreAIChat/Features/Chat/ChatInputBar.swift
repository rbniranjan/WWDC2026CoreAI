import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    let isGenerating: Bool
    let onSend: () -> Void

    private var isSendDisabled: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating
    }

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                TextField("Message", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.elevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AppColors.separator.opacity(0.35), lineWidth: 0.5)
                    }
                    .disabled(isGenerating)
                    .onSubmit {
                        guard !isSendDisabled else { return }
                        onSend()
                    }

                Button {
                    guard !isSendDisabled else { return }
                    onSend()
                } label: {
                    if isGenerating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.headline)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isSendDisabled)
                .accessibilityLabel("Send")
            }
        }
        .padding(AppSpacing.lg)
        .background(.bar)
    }
}
