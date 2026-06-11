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
                } else if viewModel.modelReferences.isEmpty {
                    EmptyStateView(
                        title: "No models in this catalog",
                        message: "Refresh the bundled catalog or configure a remote manifest in Settings. External catalog entries also load from the bundled schema-v3 catalog.",
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

                            ForEach(viewModel.modelReferences) { reference in
                                NavigationLink(value: reference) {
                                    modelRow(reference)
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
            .navigationDestination(for: CatalogModelReference.self) { reference in
                ModelDetailView(reference: reference, viewModel: viewModel)
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
                    Text("\(viewModel.models.count) manifest models • \(viewModel.externalModels.count) external models")
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

    @ViewBuilder
    private func modelRow(_ reference: CatalogModelReference) -> some View {
        if let model = viewModel.internalModel(for: reference) {
            internalModelRow(model, reference: reference)
        } else if let model = viewModel.externalModel(for: reference) {
            externalModelRow(model)
        }
    }

    private func internalModelRow(_ model: ModelVariant, reference: CatalogModelReference) -> some View {
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

                    if viewModel.isActive(reference) {
                        StatusBadgeView(title: "Active", systemImage: "checkmark.seal.fill", tint: Color.accentColor)
                    }
                }

                horizontalBadges {
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
                    StatusBadgeView(
                        title: "Manifest",
                        systemImage: "internaldrive",
                        tint: AppColors.neutral
                    )
                }
            }
        }
    }

    private func externalModelRow(_ model: CoreAIExternalModelProfile) -> some View {
        let preflight = viewModel.preflight(for: model)

        return CardView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(model.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("\(model.family) - \(model.architecture)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    StatusBadgeView(title: "External", systemImage: "globe", tint: Color.accentColor)
                }

                horizontalBadges {
                    capabilityBadges(for: model, preflight: preflight)
                    StatusBadgeView(title: "\(model.generation.defaultContextWindow) tokens", systemImage: "text.word.spacing", tint: AppColors.neutral)
                }

                HStack(spacing: AppSpacing.sm) {
                    StatusBadgeView(
                        title: readinessTitle(preflight.readiness),
                        systemImage: readinessSystemImage(preflight.readiness),
                        tint: readinessTint(preflight.readiness)
                    )
                    StatusBadgeView(
                        title: model.license,
                        systemImage: "doc.text",
                        tint: AppColors.neutral
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func capabilityBadges(
        for model: CoreAIExternalModelProfile,
        preflight: CoreAIRunnerPreflightResult
    ) -> some View {
        if model.capabilities.supportsTextChat {
            StatusBadgeView(title: "Text Chat", systemImage: "text.bubble", tint: AppColors.success)
        }
        if model.capabilities.supportsImageUpload {
            StatusBadgeView(title: "Image Upload", systemImage: "photo", tint: AppColors.success)
        }
        if model.capabilities.supportsImageTextToText || model.capabilities.supportsImageToText {
            StatusBadgeView(title: "Vision Language", systemImage: "viewfinder", tint: AppColors.success)
        }
        if preflight.readiness == .adapterRequired || model.runtime.status == .adapterRequired {
            StatusBadgeView(title: "Runtime Adapter Required", systemImage: "wrench.and.screwdriver", tint: AppColors.warning)
        }
        if model.artifacts.allSatisfy(\.isManualInstallOnly) {
            StatusBadgeView(title: "Manual Install", systemImage: "shippingbox", tint: AppColors.warning)
        }
    }

    private func horizontalBadges<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                content()
            }
        }
    }

    private func readinessTitle(_ readiness: CoreAIRunnerReadiness) -> String {
        switch readiness {
        case .ready:
            "Ready"
        case .experimental:
            "Experimental"
        case .adapterRequired:
            "Adapter Required"
        case .unsupported:
            "Unsupported"
        case .missingArtifacts:
            "Missing Artifacts"
        case .invalidProfile:
            "Invalid Profile"
        }
    }

    private func readinessSystemImage(_ readiness: CoreAIRunnerReadiness) -> String {
        switch readiness {
        case .ready:
            "checkmark.circle.fill"
        case .experimental:
            "flask"
        case .adapterRequired:
            "wrench.and.screwdriver"
        case .unsupported:
            "xmark.octagon.fill"
        case .missingArtifacts:
            "shippingbox"
        case .invalidProfile:
            "exclamationmark.triangle.fill"
        }
    }

    private func readinessTint(_ readiness: CoreAIRunnerReadiness) -> Color {
        switch readiness {
        case .ready:
            AppColors.success
        case .experimental:
            Color.accentColor
        case .adapterRequired, .missingArtifacts:
            AppColors.warning
        case .unsupported, .invalidProfile:
            AppColors.danger
        }
    }

    private var manifestTint: Color {
        switch viewModel.manifestSource {
        case .bundled:
            AppColors.neutral
        case .remote:
            AppColors.success
        case .cachedRemote, .fallbackBundled:
            AppColors.warning
        }
    }
}
