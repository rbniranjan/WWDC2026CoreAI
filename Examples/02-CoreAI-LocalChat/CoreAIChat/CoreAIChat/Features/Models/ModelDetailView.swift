import SwiftUI

struct ModelDetailView: View {
    let model: ModelVariant
    @ObservedObject var viewModel: ModelLibraryViewModel

    private var isAvailable: Bool {
        viewModel.isAvailable(model)
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
                        detailRow("Context window", "\(model.contextWindow) tokens")
                        detailRow("Estimated size", model.estimatedSize ?? "Not specified")
                        detailRow("Local availability", isAvailable ? "Available" : "Missing")
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

                Text("Download support will be added in Phase 2.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(AppSpacing.xl)
            .frame(maxWidth: 760, alignment: .leading)
        }
        .navigationTitle(model.name)
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
