import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    let isGenerating: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.sm) {
            TextField("Message", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .disabled(isGenerating)
                .onSubmit(onSend)

            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating)
            .accessibilityLabel("Send")
        }
        .padding(AppSpacing.lg)
        .background(.bar)
    }
}
