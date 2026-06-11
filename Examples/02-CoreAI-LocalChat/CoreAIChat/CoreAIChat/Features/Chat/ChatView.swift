import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: AppSpacing.md) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }

                        if viewModel.isGenerating {
                            HStack {
                                ProgressView()
                                Text("Generating")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, AppSpacing.lg)
                        }
                    }
                    .padding(AppSpacing.lg)
                }
                .background(AppColors.groupedBackground)
                .onChange(of: viewModel.messages.count) {
                    guard let lastID = viewModel.messages.last?.id else { return }
                    withAnimation {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }

            ChatInputBar(
                text: $viewModel.inputText,
                isGenerating: viewModel.isGenerating
            ) {
                Task {
                    await viewModel.send()
                }
            }
        }
        .navigationTitle("Chat")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.clearChat()
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Clear chat")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: viewModel.activeModel == nil ? "cpu" : "checkmark.seal.fill")
                    .foregroundStyle(viewModel.activeModel == nil ? AppColors.warning : AppColors.success)

                Text(viewModel.activeModelDisplayName)
                    .font(.headline)
                    .lineLimit(2)

                Spacer()
            }

            Text(viewModel.runtimeStatus.displayText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
    }
}
