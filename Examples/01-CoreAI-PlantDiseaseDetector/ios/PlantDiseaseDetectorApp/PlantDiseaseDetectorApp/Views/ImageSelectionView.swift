import PhotosUI
import SwiftUI
import UIKit

struct ImageSelectionView: View {
    @Binding var selection: PhotosPickerItem?
    let image: UIImage?
    let detections: [PlantDiseaseDetection]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
                Label("Import Leaf Image", systemImage: "photo.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            GroupBox("Selected Image") {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .frame(height: 320)

                    if let image {
                        GeometryReader { proxy in
                            ZStack {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: proxy.size.width, height: proxy.size.height)

                                DetectionOverlayView(image: image, detections: detections)
                                    .frame(width: proxy.size.width, height: proxy.size.height)
                            }
                        }
                        .padding(12)
                    } else {
                        EmptyStateView(
                            systemImage: "photo.on.rectangle",
                            title: "No Image Selected",
                            message: "Choose a plant or crop image from Photos to preview detections."
                        )
                    }
                }
            }
        }
    }
}
