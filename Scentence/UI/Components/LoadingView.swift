import SwiftUI

// MARK: - BreathingSearchLoader
// Pulsing glass circle with radiating ripple rings — used during perfume search

struct BreathingSearchLoader: View {
    var message: String = "Подбираем ароматы..."

    @State private var breathe = false
    @State private var ring0 = false
    @State private var ring1 = false
    @State private var ring2 = false

    var body: some View {
        VStack(spacing: 36) {
            ZStack {
                // Ripple ring 0 (first to radiate)
                rippleRing(active: ring0)

                // Ripple ring 1 (0.7s offset)
                rippleRing(active: ring1)

                // Ripple ring 2 (1.4s offset)
                rippleRing(active: ring2)

                // Main breathing circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(Circle().fill(AppColor.gold.opacity(0.14)))
                    .frame(width: 84, height: 84)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [AppColor.gold.opacity(0.65), AppColor.gold.opacity(0.30)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: AppColor.gold.opacity(breathe ? 0.50 : 0.22), radius: breathe ? 24 : 12, x: 0, y: 0)
                    .shadow(color: AppColor.gold.opacity(breathe ? 0.22 : 0.08), radius: breathe ? 48 : 20, x: 0, y: 0)
                    .scaleEffect(breathe ? 1.12 : 0.90)
                    .animation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true), value: breathe)

                // Center icon
                Image(systemName: "sparkles")
                    .font(.system(size: 26, weight: .thin))
                    .foregroundColor(AppColor.gold)
                    .opacity(breathe ? 1.0 : 0.55)
                    .scaleEffect(breathe ? 1.10 : 0.88)
                    .animation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true), value: breathe)
            }
            .onAppear {
                breathe = true
                // Stagger ripples 0.7 s apart
                startRipple(delay: 0.0) { ring0 = $0 }
                startRipple(delay: 0.7) { ring1 = $0 }
                startRipple(delay: 1.4) { ring2 = $0 }
            }

            VStack(spacing: 6) {
                Text(message)
                    .font(AppFont.caption(14))
                    .foregroundColor(AppColor.textSecondary)
                    .tracking(0.5)
                    .opacity(breathe ? 1.0 : 0.5)
                    .animation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true), value: breathe)

                Text("это может занять до минуты")
                    .font(AppFont.caption(11))
                    .foregroundColor(AppColor.textMuted)
                    .tracking(0.3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    @ViewBuilder
    private func rippleRing(active: Bool) -> some View {
        Circle()
            .stroke(AppColor.gold.opacity(active ? 0.0 : 0.40), lineWidth: 1.2)
            .frame(width: 84, height: 84)
            .scaleEffect(active ? 2.8 : 1.0)
            .animation(
                .easeOut(duration: 2.1).repeatForever(autoreverses: false),
                value: active
            )
    }

    private func startRipple(delay: Double, setter: @escaping (Bool) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            setter(true)
        }
    }
}

// MARK: - Generic LoadingView (used in Favorites / History tabs)

struct LoadingView: View {
    var message: String = "Загрузка..."

    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(AppColor.gold.opacity(0.15), lineWidth: 1)
                    .frame(width: 48, height: 48)

                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(
                        LinearGradient(
                            colors: [AppColor.gold, AppColor.gold.opacity(0.2)],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                    )
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
            }

            Text(message)
                .font(AppFont.caption(13))
                .foregroundColor(AppColor.textSecondary)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - EmptyStateView

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .thin))
                .foregroundColor(AppColor.textMuted)

            Text(title)
                .font(AppFont.title(18))
                .foregroundColor(AppColor.textPrimary)

            Text(subtitle)
                .font(AppFont.caption(14))
                .foregroundColor(AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}
