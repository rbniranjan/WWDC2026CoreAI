import SwiftUI

struct ModelDetailView: View {
    let model: ModelVariant
    @ObservedObject var viewModel: ModelLibraryViewModel

    private var isAvailable: Bool {
        viewModel.isAvailable(model)
    }

    private var downloadState: ModelDownloadState {
        viewModel.downloadState(for: model)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                CardView {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        HStack(alignment: .top, spacing: AppSpacing.md) {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text(model.name)
                                    .font(.largeTitle.bold())
                                    .lineLimit(3)
                                    .minimumScaleFactor(0.75)
                                Text(model.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if viewModel.isActive(model) {
                                StatusBadgeView(title: "Active", systemImage: "checkmark.seal.fill", tint: Color.accentColor)
                            }
                        }

                        HStack(spacing: AppSpacing.sm) {
                            ModelAvailabilityBadge(availability: viewModel.availability(for: model))
                            StatusBadgeView(title: downloadState.displayText, systemImage: model.downloadSupported ? "arrow.down.circle" : "hand.raised", tint: model.downloadSupported ? Color.accentColor : AppColors.neutral)
                        }
                    }
                }

                if !isAvailable {
                    CardView(background: AppColors.warning.opacity(0.12)) {
                        Label("This model is not runtime-ready. Chat will use the mock runtime until a matching local `.aimodel` is available.", systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.warning)
                    }
                }

                CardView {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        SectionHeaderView(title: "Actions", subtitle: "Set the active model or manage a downloadable artifact.")

                        Button {
                            viewModel.setActive(model)
                        } label: {
                            Label("Set Active Model", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!isAvailable)

                        downloadActions
                    }
                }

                CardView {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        SectionHeaderView(title: "Model Metadata", subtitle: "Values come from the JSON manifest.")
                        LazyVGrid(columns: metadataColumns, alignment: .leading, spacing: AppSpacing.md) {
                            metadataItem("Family", model.family)
                            metadataItem("Format", model.format)
                            metadataItem("Quantization", model.quantization)
                            metadataItem("Context window", "\(model.contextWindow) tokens")
                            metadataItem("Expected size", expectedSizeText)
                            metadataItem("Artifact type", model.artifactType ?? "Manual .aimodel")
                            metadataItem("Checksum", model.sha256 == nil ? "Not provided" : "SHA-256 provided")
                            metadataItem("Local availability", viewModel.availability(for: model).displayText)
                            metadataItem("Download state", downloadState.displayText)
                            metadataItem("Manifest source", viewModel.manifestSource.rawValue)
                            metadataItem("Minimum OS", model.minimumOS ?? "Not specified")
                            metadataItem("Supported devices", model.supportedDevices?.joined(separator: ", ") ?? "Not specified")
                        }
                    }
                }

                if !model.downloadSupported {
                    CardView {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Label("Manual .aimodel required", systemImage: "folder.badge.questionmark")
                                .font(.headline)
                            Text("Copy `\(model.fileName)` into `CoreAIChat/Resources/AIModels/`. The file name must match the manifest entry exactly.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(AppSpacing.xl)
            .frame(maxWidth: AppSpacing.readableMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(AppColors.background)
        .navigationTitle(model.name)
    }

    private var metadataColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 220), spacing: AppSpacing.md, alignment: .topLeading),
        ]
    }

    private var expectedSizeText: String {
        if let expectedSizeBytes = model.expectedSizeBytes {
            return ByteCountFormatter.string(fromByteCount: Int64(expectedSizeBytes), countStyle: .file)
        }
        return model.estimatedSize ?? "Not specified"
    }

    @ViewBuilder
    private var downloadActions: some View {
        switch downloadState {
        case .notAvailable:
            Text("Downloads are not configured for this manifest entry.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .notDownloaded, .unavailable:
            Button {
                Task { await viewModel.downloadModel(model) }
            } label: {
                Label("Download Model", systemImage: "arrow.down.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!(model.downloadSupported && model.downloadURL != nil))
        case .downloading:
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ProgressView()
                Button("Cancel Download") {
                    viewModel.cancelDownload(model)
                }
                .buttonStyle(.bordered)
            }
        case .downloaded:
            Button(role: .destructive) {
                viewModel.deleteDownloadedArtifact(model)
            } label: {
                Label("Delete Downloaded Artifact", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        case .failed:
            Button {
                Task { await viewModel.retryDownload(model) }
            } label: {
                Label("Retry Download", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private func metadataItem(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
    }
}
