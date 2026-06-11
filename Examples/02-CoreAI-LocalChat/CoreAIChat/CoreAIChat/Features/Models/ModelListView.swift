import SwiftUI

struct ModelListView: View {
    @ObservedObject var viewModel: ModelLibraryViewModel

    var body: some View {
        NavigationStack {
            Group {
                if let loadError = viewModel.loadError {
                    ContentUnavailableView(
                        "Model manifest unavailable",
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
                    )
                } else {
                    List(viewModel.models) { model in
                        NavigationLink(value: model) {
                            modelRow(model)
                        }
                    }
                    .refreshable {
                        viewModel.load()
                    }
                }
            }
            .navigationTitle("Models")
            .navigationDestination(for: ModelVariant.self) { model in
                ModelDetailView(model: model, viewModel: viewModel)
            }
            .task {
                viewModel.load()
            }
        }
    }

    private func modelRow(_ model: ModelVariant) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(model.name)
                        .font(.headline)
                    Text("\(model.family) - \(model.quantization)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if viewModel.isActive(model) {
                    Text("Active")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }

            HStack(spacing: AppSpacing.md) {
                Label("\(model.contextWindow) tokens", systemImage: "text.word.spacing")
                Label(viewModel.isAvailable(model) ? "Local" : "Missing", systemImage: viewModel.isAvailable(model) ? "checkmark.circle" : "xmark.circle")
                    .foregroundStyle(viewModel.isAvailable(model) ? AppColors.success : AppColors.warning)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}
