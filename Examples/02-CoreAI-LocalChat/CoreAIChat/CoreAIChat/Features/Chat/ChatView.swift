import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel

    private let suggestedPrompts = [
        "Explain Core AI",
        "What model is active?",
        "How do local models work?",
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollViewReader { proxy in
                ScrollView {
                    if viewModel.messages.isEmpty {
                        EmptyStateView(
                            title: "Start a local chat",
                            message: "The app is running through the mock runtime until a compatible Core AI LLM artifact is available.",
                            systemImage: "bubble.left.and.bubble.right"
                        ) {
                            promptChips
                        }
                        .frame(minHeight: 360)
                    } else {
                        LazyVStack(spacing: AppSpacing.md) {
                            ForEach(viewModel.messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }

                            if viewModel.isGenerating {
                                generatingRow
                            }
                        }
                        .padding(AppSpacing.lg)
                    }
                }
                .background(AppColors.background)
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
        VStack(spacing: 0) {
            CardView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack(alignment: .top, spacing: AppSpacing.md) {
                        Image(systemName: viewModel.activeModelAvailability.isUsable ? "cpu.fill" : "cpu")
                            .font(.title3)
                            .foregroundStyle(viewModel.activeModelAvailability.isUsable ? AppColors.success : AppColors.warning)
                            .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(viewModel.activeModelDisplayName)
                                .font(.headline)
                                .lineLimit(2)
                            Text(viewModel.runtimeModeText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            Text(viewModel.externalRuntimeStatusLine)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Spacer(minLength: AppSpacing.sm)
                    }

                    HStack(spacing: AppSpacing.sm) {
                        RuntimeStatusView(status: viewModel.runtimeStatus, compact: true)
                        Spacer()
                        ModelAvailabilityBadge(availability: viewModel.activeModelAvailability)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
    }

    private var promptChips: some View {
        FlowLayout(spacing: AppSpacing.sm) {
            ForEach(suggestedPrompts, id: \.self) { prompt in
                Button {
                    Task {
                        await viewModel.useSuggestedPrompt(prompt)
                    }
                } label: {
                    Text(prompt)
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isGenerating)
            }
        }
    }

    private var generatingRow: some View {
        HStack(spacing: AppSpacing.sm) {
            ProgressView()
            Text(viewModel.externalRuntimeStatusLine == "External runtime: running" ? "External runtime is generating" : "Mock runtime is generating")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.assistantBubble)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: spacing) {
                content
            }
            VStack(spacing: spacing) {
                content
            }
        }
    }
}
