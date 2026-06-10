import SwiftUI

struct DetectionResultView: View {
    let detections: [PlantDiseaseDetection]
    let runtimeInfo: ModelRuntimeInfo
    let isLoading: Bool

    var body: some View {
        GroupBox("Detections") {
            if isLoading {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Running detector...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if detections.isEmpty {
                EmptyStateView(
                    systemImage: "scope",
                    title: "No Detections Yet",
                    message: "Run the detector to see class names, confidence values, and bounding box summaries."
                )
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(detections) { detection in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .center, spacing: 10) {
                                Text(detection.className)
                                    .font(.headline)
                                ConfidenceBadge(confidence: detection.confidence)
                            }

                            Text(detection.boundingBoxSummary)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if detection.id != detections.last?.id {
                            Divider()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

