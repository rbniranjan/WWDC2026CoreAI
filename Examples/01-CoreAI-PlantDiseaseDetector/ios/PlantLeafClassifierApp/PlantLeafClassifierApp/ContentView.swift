import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PlantDiseaseDetectionViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Core AI Plant Disease Detector")
                            .font(.largeTitle.bold())

                        Text("Detector integration is pending. This scaffold will later visualize on-device detections and bounding boxes.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    LeafImagePicker(selection: $viewModel.selectedPhotoItem)

                    previewCard
                    resultCard

                    Button {
                        viewModel.runPrediction()
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                            }
                            Text("Run Placeholder Detection")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.selectedImage == nil || viewModel.isLoading)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Detector Demo")
        }
    }

    private var previewCard: some View {
        GroupBox("Selected Image") {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .frame(height: 260)

                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(10)
                } else {
                    Text("Choose a leaf image to begin.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var resultCard: some View {
        GroupBox("Detection Placeholder") {
            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.predictionLabel)
                    .font(.title3.weight(.semibold))

                Text("Confidence: \(viewModel.confidenceText)")
                    .foregroundStyle(.secondary)

                LabeledContent("Runtime", value: viewModel.runtimeLabel)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    ContentView()
}
