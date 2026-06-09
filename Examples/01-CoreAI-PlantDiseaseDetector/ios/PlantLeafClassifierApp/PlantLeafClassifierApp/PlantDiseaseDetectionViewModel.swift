import Foundation
import PhotosUI
import SwiftUI
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
    @Published var prediction: PlantDiseasePrediction?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let primaryDetector: PlantDiseaseDetectorProtocol
    private let fallbackDetector: PlantDiseaseDetectorProtocol

    init(
        primaryDetector: PlantDiseaseDetectorProtocol = CoreAIPlantDiseaseDetector(),
        fallbackDetector: PlantDiseaseDetectorProtocol = MockPlantDiseaseDetector()
    ) {
        self.primaryDetector = primaryDetector
        self.fallbackDetector = fallbackDetector
    }

    var predictionLabel: String {
        prediction?.label ?? "No prediction yet"
    }

    var confidenceText: String {
        guard let confidence = prediction?.confidence else {
            return "--"
        }
        return confidence.formatted(.percent.precision(.fractionLength(1)))
    }

    var runtimeLabel: String {
        prediction?.runtime.rawValue ?? "Not run"
    }

    func runPrediction() {
        guard let image = selectedImage else {
            errorMessage = "Select an image before running detection."
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            defer { isLoading = false }

            do {
                prediction = try await primaryDetector.predict(image: image)
            } catch {
                do {
                    prediction = try await fallbackDetector.predict(image: image)
                    errorMessage = "Using mock fallback. \(error.localizedDescription)"
                } catch {
                    prediction = nil
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func loadSelectedImage() {
        guard let selectedPhotoItem else { return }

        isLoading = true
        errorMessage = nil
        prediction = nil

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
}
