import SwiftUI

// MARK: - AppBackground

struct AppBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        LinearGradient(
            colors: [AppColor.background, AppColor.backgroundAlt],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - AccentDivider

struct AccentDivider: View {
    var body: some View {
        LinearGradient(
            colors: [.clear, AppColor.accent.opacity(0.5), .clear],
            startPoint: .leading, endPoint: .trailing
        )
        .frame(height: 0.5)
    }
}
