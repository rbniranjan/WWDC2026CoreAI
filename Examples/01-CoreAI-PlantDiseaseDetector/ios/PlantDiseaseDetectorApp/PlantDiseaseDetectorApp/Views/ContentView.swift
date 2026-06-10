import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PlantDiseaseDetectionViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    RuntimeStatusView(runtimeInfo: viewModel.runtimeInfo)

                    ImageSelectionView(
                        selection: $viewModel.selectedPhotoItem,
                        image: viewModel.selectedImage,
                        detections: viewModel.detections
                    )

                    PrimaryButton(
                        title: "Run Detection",
                        isLoading: viewModel.isLoading,
                        isDisabled: !viewModel.hasImage
                    ) {
                        viewModel.runDetection()
                    }

                    DetectionResultView(
                        detections: viewModel.detections,
                        runtimeInfo: viewModel.runtimeInfo,
                        isLoading: viewModel.isLoading
                    )

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

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Core AI Plant Disease Detector")
                .font(.largeTitle.bold())

            Text("This iOS app is ready for a future on-device detector model and can already run in mock mode with bounding-box overlays.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
