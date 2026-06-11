import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: ModelLibraryViewModel
    @State private var draftSettings: AppSettings

    init(viewModel: ModelLibraryViewModel) {
        self.viewModel = viewModel
        _draftSettings = State(initialValue: viewModel.settings)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                activeModelCard
                generationCard
                catalogCard
                storageCard
                developerNotesCard
                actionsCard
            }
            .padding(AppSpacing.xl)
            .frame(maxWidth: AppSpacing.readableMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(AppColors.background)
        .navigationTitle("Settings")
        .onChange(of: viewModel.settings) {
            draftSettings = viewModel.settings
        }
    }

    private var activeModelCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                SectionHeaderView(title: "Active Model", subtitle: "The selected model controls runtime loading when a local `.aimodel` is present.")
                Text(viewModel.activeModelSummary)
                    .font(.headline)
                StatusBadgeView(title: viewModel.manifestSource.rawValue, systemImage: "doc.text", tint: manifestTint)
            }
        }
    }

    private var generationCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                SectionHeaderView(title: "Generation", subtitle: "These values are validated before each chat request.")
                Stepper("Context window: \(draftSettings.generationSettings.contextWindow)", value: $draftSettings.generationSettings.contextWindow, in: 256...131_072, step: 256)
                Stepper("Max output tokens: \(draftSettings.generationSettings.maxOutputTokens)", value: $draftSettings.generationSettings.maxOutputTokens, in: 1...16_384, step: 64)
                labeledSlider(
                    title: "Temperature",
                    value: $draftSettings.generationSettings.temperature,
                    range: 0...2
                )
                labeledSlider(
                    title: "Top P",
                    value: $draftSettings.generationSettings.topP,
                    range: 0.01...1
                )
            }
        }
    }

    private var catalogCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                SectionHeaderView(title: "Model Catalog", subtitle: "Use the bundled manifest or attempt a remote JSON manifest first.")
                Toggle("Use remote manifest", isOn: $draftSettings.useRemoteManifest)
                TextField("Remote manifest URL", text: $draftSettings.remoteManifestURL)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .disabled(!draftSettings.useRemoteManifest)

                HStack {
                    Text("Current source")
                        .foregroundStyle(.secondary)
                    Spacer()
                    StatusBadgeView(title: viewModel.manifestSource.rawValue, systemImage: "doc.text.magnifyingglass", tint: manifestTint)
                }

                if let date = draftSettings.lastManifestRefreshDate {
                    Text("Last remote refresh: \(date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    persist()
                    Task { await viewModel.load() }
                } label: {
                    Label("Refresh Manifest", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var storageCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                SectionHeaderView(title: "Storage", subtitle: "Downloaded artifacts stay in Application Support and out of git.")
                HStack {
                    Label("Downloaded artifacts", systemImage: "internaldrive")
                    Spacer()
                    Text(viewModel.storageUsageText)
                        .fontWeight(.semibold)
                }
                Text("Delete a downloaded artifact from its model detail screen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var developerNotesCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                SectionHeaderView(title: "Developer Notes")
                Text("Real Core AI LLM generation is future work. `CoreAIChatRuntime` remains a compile-safe boundary and the app falls back to `MockChatRuntime` when a runtime-ready `.aimodel` is missing.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var actionsCard: some View {
        CardView {
            VStack(spacing: AppSpacing.md) {
                Button {
                    persist()
                } label: {
                    Label("Save Settings", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    Task {
                        await viewModel.resetSettings()
                        draftSettings = viewModel.settings
                    }
                } label: {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func persist() {
        viewModel.updateSettings(draftSettings)
    }

    private func labeledSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue, format: .number.precision(.fractionLength(2)))
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
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
