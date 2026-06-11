import SwiftUI

struct ModelListView: View {
    @ObservedObject var viewModel: ModelLibraryViewModel

    var body: some View {
        NavigationStack {
            Group {
                if let loadError = viewModel.loadError {
                    EmptyStateView(
                        title: "Model manifest unavailable",
                        message: loadError,
                        systemImage: "exclamationmark.triangle"
                    ) {
                        Button {
                            Task { await viewModel.load() }
                        } label: {
                            Label("Retry", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(AppSpacing.xl)
                } else if viewModel.models.isEmpty {
                    EmptyStateView(
                        title: "No models in this catalog",
                        message: "Refresh the bundled catalog or configure a remote manifest in Settings.",
                        systemImage: "cpu"
                    ) {
                        Button {
                            Task { await viewModel.load() }
                        } label: {
                            Label("Refresh Catalog", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(AppSpacing.xl)
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.md) {
                            catalogSummary

                            ForEach(viewModel.models) { model in
                                NavigationLink(value: model) {
                                    modelRow(model)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(AppSpacing.lg)
                        .frame(maxWidth: AppSpacing.readableMaxWidth)
                    }
                    .frame(maxWidth: .infinity)
                    .background(AppColors.background)
                    .refreshable {
                        await viewModel.load()
                    }
                }
            }
            .navigationTitle("Models")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await viewModel.load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh model catalog")
                }
            }
            .navigationDestination(for: ModelVariant.self) { model in
                ModelDetailView(model: model, viewModel: viewModel)
            }
            .task {
                await viewModel.load()
            }
        }
    }

    private var catalogSummary: some View {
        CardView {
            HStack(alignment: .center, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Model Catalog")
                        .font(.headline)
                    Text("\(viewModel.models.count) manifest entries")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                StatusBadgeView(
                    title: viewModel.manifestSource.rawValue,
                    systemImage: "doc.text.magnifyingglass",
                    tint: manifestTint
                )
            }
        }
    }

    private func modelRow(_ model: ModelVariant) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(model.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("\(model.family) - \(model.format)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if viewModel.isActive(model) {
                        StatusBadgeView(title: "Active", systemImage: "checkmark.seal.fill", tint: Color.accentColor)
                    }
                }

                HStack(spacing: AppSpacing.sm) {
                    StatusBadgeView(title: model.quantization, systemImage: "slider.horizontal.3", tint: AppColors.neutral)
                    StatusBadgeView(title: "\(model.contextWindow) tokens", systemImage: "text.word.spacing", tint: AppColors.neutral)
                    ModelAvailabilityBadge(availability: viewModel.availability(for: model))
                }

                HStack(spacing: AppSpacing.sm) {
                    StatusBadgeView(
                        title: viewModel.downloadState(for: model).displayText,
                        systemImage: model.downloadSupported ? "arrow.down.circle" : "hand.raised",
                        tint: model.downloadSupported ? Color.accentColor : AppColors.neutral
                    )
                    StatusBadgeView(
                        title: viewModel.manifestSource.rawValue,
                        systemImage: "doc.text",
                        tint: manifestTint
                    )
                }
            }
        }
    }

    private var manifestTint: Color {
        switch viewModel.manifestSource {
        case .bundled:
            AppColors.neutral
        case .remote:
            AppColors.success
        case .cachedRemote:
            AppColors.warning
        case .fallbackBundled:
            AppColors.warning
        }
    }
}
