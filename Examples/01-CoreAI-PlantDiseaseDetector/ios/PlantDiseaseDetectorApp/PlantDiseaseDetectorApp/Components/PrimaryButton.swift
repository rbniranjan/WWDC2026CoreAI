import SwiftUI

struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }

                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .background(isDisabled ? Color.gray.opacity(0.45) : Color.green)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .disabled(isDisabled || isLoading)
    }
}

