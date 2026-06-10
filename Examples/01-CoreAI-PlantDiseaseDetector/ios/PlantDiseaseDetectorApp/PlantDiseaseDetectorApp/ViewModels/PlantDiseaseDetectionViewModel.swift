import Foundation
import PhotosUI
import UIKit

@MainActor
final class PlantDiseaseDetectionViewModel: ObservableObject {
    @Published var selectedPhotoItem: PhotosPickerItem? {
        didSet {
            guard selectedPhotoItem != nil else { return }
            loadSelectedImage()
        }
    }
    @Published var selectedImage: UIImage?
    @Published var detections: [PlantDiseaseDetection] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var runtimeInfo: ModelRuntimeInfo = .mockFallbackReady
    @Published var detectorSelection: DetectorSelection = .automatic

    private let coreAIDetector: PlantDiseaseDetectorProtocol
    private let mockDetector: PlantDiseaseDetectorProtocol

    init(
        coreAIDetector: PlantDiseaseDetectorProtocol = CoreAIPlantDiseaseDetector(),
        mockDetector: PlantDiseaseDetectorProtocol = MockPlantDiseaseDetector()
    ) {
        self.coreAIDetector = coreAIDetector
        self.mockDetector = mockDetector
    }

    enum DetectorSelection: String, CaseIterable, Identifiable {
        case automatic
        case mockOnly

        var id: String { rawValue }
    }

    var hasImage: Bool {
        selectedImage != nil
    }

    var hasDetections: Bool {
        !detections.isEmpty
    }

    func runDetection() {
        guard let image = selectedImage else {
            errorMessage = "Select an image before running detection."
            return
        }

        isLoading = true
        errorMessage = nil
        detections = []

        Task {
            defer { isLoading = false }

            switch detectorSelection {
            case .automatic:
                await runAutomaticDetection(image: image)
            case .mockOnly:
                await runMockDetection(image: image)
            }
        }
    }

    private func loadSelectedImage() {
        guard let selectedPhotoItem else { return }

        isLoading = true
        errorMessage = nil
        detections = []
        runtimeInfo = .mockFallbackReady

        Task {
            defer { isLoading = false }

            do {
                guard let data = try await selectedPhotoItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    errorMessage = "The selected image could not be loaded."
                    return
                }
                selectedImage = image
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func runAutomaticDetection(image: UIImage) async {
        do {
            let results = try await coreAIDetector.detect(in: image)
            detections = results
            runtimeInfo = coreAIDetector.runtimeInfo
        } catch {
            do {
                let results = try await mockDetector.detect(in: image)
                detections = results
                runtimeInfo = mockDetector.runtimeInfo.withDetail("Using mock fallback because \(error.localizedDescription)")
                errorMessage = "Using mock fallback. \(error.localizedDescription)"
            } catch {
                runtimeInfo = mockDetector.runtimeInfo.withDetail("Mock detector also failed.")
                errorMessage = error.localizedDescription
            }
        }
    }

    private func runMockDetection(image: UIImage) async {
        do {
            let results = try await mockDetector.detect(in: image)
            detections = results
            runtimeInfo = mockDetector.runtimeInfo
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
