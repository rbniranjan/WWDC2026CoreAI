import SwiftUI
import UIKit

struct DetectionOverlayView: View {
    let image: UIImage
    let detections: [PlantDiseaseDetection]

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                ForEach(detections) { detection in
                    let mappedRect = BoundingBoxMapper.mapNormalizedRect(
                        detection.boundingBox,
                        imageSize: image.size,
                        containerSize: proxy.size
                    )

                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.red, lineWidth: 2)
                        .frame(width: mappedRect.width, height: mappedRect.height)
                        .position(x: mappedRect.midX, y: mappedRect.midY)

                    Text(detection.className)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                        .offset(x: mappedRect.minX, y: max(mappedRect.minY - 24, 0))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

