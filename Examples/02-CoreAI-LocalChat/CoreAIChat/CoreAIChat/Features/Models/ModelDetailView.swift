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
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(model.name)
                        .font(.largeTitle.bold())
                    Text(model.description)
                        .foregroundStyle(.secondary)
                }

                CardView {
                    VStack(spacing: AppSpacing.md) {
                        detailRow("Family", model.family)
                        detailRow("Format", model.format)
                        detailRow("Quantization", model.quantization)
                        detailRow("File name", model.fileName)
                        detailRow("Artifact type", model.artifactType ?? "Manual .aimodel")
                        detailRow("Context window", "\(model.contextWindow) tokens")
                        detailRow("Estimated size", expectedSizeText)
                        detailRow("Local availability", viewModel.availability(for: model).displayText)
                        detailRow("Download support", model.downloadSupported ? "Supported" : "Manual only")
                        detailRow("Checksum", model.sha256 == nil ? "Not provided" : "SHA-256 provided")
                        detailRow("Manifest source", viewModel.manifestSource.rawValue)
                        detailRow("Minimum OS", model.minimumOS ?? "Not specified")
                        detailRow("Supported devices", model.supportedDevices?.joined(separator: ", ") ?? "Not specified")
                    }
                }

                if !isAvailable {
                    Label("Model file not found in Resources/AIModels.", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(AppColors.warning)
                }

                Button {
                    viewModel.setActive(model)
                } label: {
                    Label("Set as Active Model", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isAvailable)

                downloadActions

                if !model.downloadSupported {
                    CardView {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Label("Manual .aimodel required", systemImage: "folder.badge.questionmark")
                                .font(.headline)
                            Text("Copy a matching `.aimodel` into Resources/AIModels. See Resources/AIModels/README.md.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(AppSpacing.xl)
            .frame(maxWidth: 760, alignment: .leading)
        }
        .navigationTitle(model.name)
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
            EmptyView()
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
            VStack(spacing: AppSpacing.sm) {
                ProgressView()
                Button("Cancel Download") {
                    viewModel.cancelDownload(model)
                }
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

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: AppSpacing.lg)
            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
    }
}
