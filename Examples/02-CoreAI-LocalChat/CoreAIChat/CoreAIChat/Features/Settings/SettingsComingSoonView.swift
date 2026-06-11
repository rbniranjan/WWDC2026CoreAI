import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: ModelLibraryViewModel
    @State private var draftSettings: AppSettings

    init(viewModel: ModelLibraryViewModel) {
        self.viewModel = viewModel
        _draftSettings = State(initialValue: viewModel.settings)
    }

    var body: some View {
        Form {
            Section("Active Model") {
                Text(viewModel.activeModelSummary)
                Text("Manifest: \(viewModel.manifestSource.rawValue)")
                    .foregroundStyle(.secondary)
            }

            Section("Generation") {
                Stepper("Context window: \(draftSettings.generationSettings.contextWindow)", value: $draftSettings.generationSettings.contextWindow, in: 256...131_072, step: 256)
                Stepper("Max output tokens: \(draftSettings.generationSettings.maxOutputTokens)", value: $draftSettings.generationSettings.maxOutputTokens, in: 1...16_384, step: 64)
                VStack(alignment: .leading) {
                    Text("Temperature: \(draftSettings.generationSettings.temperature, specifier: "%.2f")")
                    Slider(value: $draftSettings.generationSettings.temperature, in: 0...2)
                }
                VStack(alignment: .leading) {
                    Text("Top-p: \(draftSettings.generationSettings.topP, specifier: "%.2f")")
                    Slider(value: $draftSettings.generationSettings.topP, in: 0.01...1)
                }
            }

            Section("Model Catalog") {
                Toggle("Use remote manifest", isOn: $draftSettings.useRemoteManifest)
                TextField("Remote manifest URL", text: $draftSettings.remoteManifestURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if let date = draftSettings.lastManifestRefreshDate {
                    Text("Last refresh: \(date.formatted())")
                        .foregroundStyle(.secondary)
                }
                Button {
                    persist()
                    Task { await viewModel.load() }
                } label: {
                    Label("Refresh Model Catalog", systemImage: "arrow.clockwise")
                }
            }

            Section("Storage") {
                Text("Downloaded artifacts: \(viewModel.storageUsageText)")
            }

            Section("Developer") {
                Text("Core AI runtime integration is pending until a compatible `.aimodel` LLM artifact is available.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Save Settings") {
                    persist()
                }
                Button("Reset Settings to Defaults", role: .destructive) {
                    Task {
                        await viewModel.resetSettings()
                        draftSettings = viewModel.settings
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .onChange(of: viewModel.settings) {
            draftSettings = viewModel.settings
        }
    }

    private func persist() {
        viewModel.updateSettings(draftSettings)
    }
}
