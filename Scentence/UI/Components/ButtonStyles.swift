import SwiftUI

// MARK: - PrimaryButtonStyle

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        let isLight = scheme == .light
        let c1 = isLight ? Color(hex: "#2F4156") : Color(hex: "#A0707E")
        let c2 = isLight ? Color(hex: "#3A5068") : Color(hex: "#C08090")

        configuration.label
            .foregroundColor(.white)
            .font(AppFont.body(16))
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: configuration.isPressed
                        ? [c1.opacity(0.75), c2.opacity(0.60)]
                        : [c1, c2],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.18), lineWidth: 0.75))
            .shadow(color: c1.opacity(0.45), radius: 14, x: 0, y: 5)
            .shadow(color: c1.opacity(0.20), radius: 30, x: 0, y: 0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - OutlineButtonStyle

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(AppColor.textPrimary)
            .font(AppFont.body(16))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColor.accent.opacity(0.45), lineWidth: 1.0))
            .shadow(color: AppColor.accent.opacity(0.15), radius: 8, x: 0, y: 2)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
