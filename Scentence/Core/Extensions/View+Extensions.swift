import SwiftUI

// MARK: - View modifiers

extension View {
    /// Liquid-glass card: material + rose-tinted border + glow (works in both themes)
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

    /// Glass pill with rose border + glow
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

    /// Glass input field (rounded rect, rose border, glow)
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

    /// Consistent glass nav bar
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
                            .init(color: .clear,                     location: 0.00),
                            .init(color: AppColor.accent.opacity(0.18), location: 0.40),
                            .init(color: AppColor.accent.opacity(0.30), location: 0.50),
                            .init(color: AppColor.accent.opacity(0.18), location: 0.60),
                            .init(color: .clear,                     location: 1.00),
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

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}

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

// MARK: - PrimaryButtonStyle
// Light: navy gradient button (matches branded look on beige bg)
// Dark:  rose gradient button (visible + themed on dark navy bg)

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        let isLight = scheme == .light
        let c1 = isLight ? Color(hex: "#2F4156")  : Color(hex: "#A0707E")
        let c2 = isLight ? Color(hex: "#3A5068")  : Color(hex: "#C08090")

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
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.75)
            )
            .shadow(color: c1.opacity(0.45), radius: 14, x: 0, y: 5)
            .shadow(color: c1.opacity(0.20), radius: 30, x: 0, y: 0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(AppColor.textPrimary)
            .font(AppFont.body(16))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppColor.accent.opacity(0.45), lineWidth: 1.0)
            )
            .shadow(color: AppColor.accent.opacity(0.15), radius: 8, x: 0, y: 2)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

// MARK: - ExpandableMarkdownText

struct ExpandableMarkdownText: View {
    let text: String
    var font: Font = AppFont.body(15)
    var color: Color = AppColor.textPrimary
    var lineSpacing: CGFloat = 5
    var collapsedLineLimit: Int = 5
    var charThreshold: Int = 200

    @State private var isExpanded = false

    private var needsTruncation: Bool { text.count > charThreshold }

    private var attributed: AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(attributed)
                .font(font)
                .foregroundColor(color)
                .lineSpacing(lineSpacing)
                .lineLimit(isExpanded || !needsTruncation ? nil : collapsedLineLimit)
                .fixedSize(horizontal: false, vertical: !needsTruncation || isExpanded)

            if needsTruncation {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
                } label: {
                    Text(isExpanded ? "Свернуть" : "Показать полностью")
                        .font(AppFont.caption(13))
                        .foregroundColor(AppColor.accent)
                }
            }
        }
    }
}

// MARK: - InfoButton (tap for popover tooltip, no alert)

struct InfoButton: View {
    let text: String
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 14))
                .foregroundColor(AppColor.textMuted)
        }
        .popover(isPresented: $isPresented, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
            ScrollView {
                Text(text)
                    .font(AppFont.caption(13))
                    .foregroundColor(AppColor.textPrimary)
                    .lineSpacing(5)
                    .padding(14)
                    .frame(maxWidth: 220, alignment: .leading)
            }
            .frame(maxWidth: 220, maxHeight: 130)
            .background(.ultraThinMaterial)
            .background(AppColor.accent.opacity(0.06))
            .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - MarkdownText

struct MarkdownText: View {
    let text: String
    var font: Font = AppFont.body(15)
    var color: Color = AppColor.textPrimary
    var lineSpacing: CGFloat = 4

    private var attributed: AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }

    var body: some View {
        Text(attributed)
            .font(font)
            .foregroundColor(color)
            .lineSpacing(lineSpacing)
            .fixedSize(horizontal: false, vertical: true)
    }
}
