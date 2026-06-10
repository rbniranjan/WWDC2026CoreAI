import SwiftUI

struct RuntimeStatusView: View {
    let runtimeInfo: ModelRuntimeInfo

    var body: some View {
        GroupBox("Runtime") {
            VStack(alignment: .leading, spacing: 8) {
                LabeledContent("Mode", value: runtimeInfo.mode.rawValue)
                LabeledContent("Model path", value: runtimeInfo.modelSearchPath)

                Text(runtimeInfo.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

