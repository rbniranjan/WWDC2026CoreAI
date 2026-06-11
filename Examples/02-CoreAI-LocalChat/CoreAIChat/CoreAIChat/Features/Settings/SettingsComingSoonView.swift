import SwiftUI

struct SettingsComingSoonView: View {
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "gearshape")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Settings")
                .font(.largeTitle.bold())

            Text("Generation controls and app preferences will be added in a later phase.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xl)
        .navigationTitle("Settings")
    }
}
