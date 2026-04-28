import SwiftUI
import Translation

// MARK: - Glass style modifiers

extension View {
    func cardStyle() -> some View {
        self
            .background(.ultraThinMaterial)
            .background(AppColor.accent.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppColor.accent.opacity(0.60),
                                AppColor.accent.opacity(0.20),
                                AppColor.accent.opacity(0.45),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
            .shadow(color: AppColor.accent.opacity(0.25), radius: 10, x: 0, y: 3)
            .shadow(color: AppColor.accent.opacity(0.10), radius: 28, x: 0, y: 0)
    }

    func glassCapsule(active: Bool = false) -> some View {
        self
            .background(.ultraThinMaterial)
            .background(AppColor.accent.opacity(active ? 0.10 : 0.04))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    LinearGradient(
                        colors: [
                            AppColor.accent.opacity(active ? 0.70 : 0.45),
                            AppColor.accent.opacity(active ? 0.20 : 0.12),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
            )
            .shadow(color: AppColor.accent.opacity(active ? 0.30 : 0.18), radius: 8, x: 0, y: 2)
    }

    func glassInputField(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(.ultraThinMaterial)
            .background(AppColor.accent.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [AppColor.accent.opacity(0.55), AppColor.accent.opacity(0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
            .shadow(color: AppColor.accent.opacity(0.18), radius: 10, x: 0, y: 3)
    }

    func glassNavBar() -> some View {
        self.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }

    func accentBorder() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColor.accent.opacity(0.6), lineWidth: 1)
        )
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }

    func shimmer() -> some View { modifier(ShimmerModifier()) }

    /// Применяет `.translationPresentation` только на iOS 17.4+.
    @ViewBuilder
    func applyTranslationIfAvailable(
        isPresented: Binding<Bool>,
        text: String,
        replacementAction: @escaping (String) -> Void
    ) -> some View {
        if #available(iOS 17.4, *) {
            self.translationPresentation(
                isPresented: isPresented,
                text: text,
                replacementAction: replacementAction
            )
        } else {
            self
        }
    }
}

// MARK: - ShimmerModifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: .clear,                        location: 0.00),
                            .init(color: AppColor.accent.opacity(0.18), location: 0.40),
                            .init(color: AppColor.accent.opacity(0.30), location: 0.50),
                            .init(color: AppColor.accent.opacity(0.18), location: 0.60),
                            .init(color: .clear,                        location: 1.00),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2.5)
                    .offset(x: -geo.size.width * 0.75 + phase * geo.size.width * 2.5)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}
