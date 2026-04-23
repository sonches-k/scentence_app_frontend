import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var viewModel = AuthViewModel()
    @State private var logoVisible = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 0) {
                    logoSection
                        .opacity(logoVisible ? 1 : 0)
                        .offset(y: logoVisible ? 0 : -16)
                        .padding(.top, 80)
                        .padding(.bottom, 56)

                    Group {
                        if viewModel.step == .email {
                            emailStep
                        } else {
                            codeStep
                        }
                    }
                    .padding(.horizontal, 32)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.step)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.1)) {
                logoVisible = true
            }
        }
    }

    // MARK: - Logo

    private var logoSection: some View {
        VStack(spacing: 16) {
            // Текст с лепестками поверх
            ZStack {
                Text("Scentence")
                    .font(AppFont.display(52))
                    .foregroundColor(AppColor.textPrimary)
                    .tracking(6)

                // Лепестки — появляются через 0.8с после логотипа
                if logoVisible {
                    ForEach(0..<10, id: \.self) { i in
                        BloomPetal(index: i)
                    }
                }
            }

            AccentDivider()
                .frame(width: 60)
        }
    }

    // MARK: - Email Step

    private var emailStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Привет! Я твой помощник\nв подборе идеального аромата")
                    .font(AppFont.title(20))
                    .foregroundColor(AppColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Введите почту, чтобы зарегистрироваться\nили войти в аккаунт")
                    .font(AppFont.caption(14))
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)

            ScentenceTextField(
                placeholder: "your@email.com",
                text: $viewModel.email,
                keyboardType: .emailAddress
            )

            if let error = viewModel.errorMessage {
                ErrorLabel(text: error)
            }

            Button("Получить код") {
                Task { await viewModel.requestCode() }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isLoading)
            .overlay(
                Group {
                    if viewModel.isLoading { ProgressView().tint(.white) }
                }
            )
        }
    }

    // MARK: - Code Step

    private var codeStep: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Введите код")
                    .font(AppFont.title(22))
                    .foregroundColor(AppColor.textPrimary)

                Text(viewModel.successMessage ?? "6-значный код из письма")
                    .font(AppFont.caption(14))
                    .foregroundColor(AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // OTP + sparkle overlay
            ZStack {
                OTPField(code: $viewModel.code)

                if viewModel.showSuccessSparkle {
                    SparkleOverlay()
                        .allowsHitTesting(false)
                }
            }

            if let error = viewModel.errorMessage {
                ErrorLabel(text: error)
            }

            Button("Войти") {
                Task { await viewModel.verifyCode(authState: authState) }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isLoading || viewModel.code.count < 6)
            .overlay(
                Group {
                    if viewModel.isLoading { ProgressView().tint(.white) }
                }
            )

            HStack(spacing: 16) {
                Button("← Назад") { viewModel.backToEmail() }
                    .font(AppFont.caption(14))
                    .foregroundColor(AppColor.textSecondary)

                Spacer()

                Button {
                    Task { await viewModel.resendCode() }
                } label: {
                    if viewModel.resendCountdown > 0 {
                        Text("Повторить через \(viewModel.resendCountdown) с")
                            .font(AppFont.caption(14))
                            .foregroundColor(AppColor.textMuted)
                    } else {
                        Text("Отправить снова")
                            .font(AppFont.caption(14))
                            .foregroundColor(AppColor.accent)
                    }
                }
                .disabled(viewModel.resendCountdown > 0)
            }
        }
    }
}

// MARK: - BloomPetal

/// Лепесток-эллипс, всплывающий из логотипа при появлении экрана.
struct BloomPetal: View {
    let index: Int

    private static let xPositions: [CGFloat] = [-90, -65, -40, -15, 10, 35, 60, 85, -52, 22]
    private var xStart: CGFloat { Self.xPositions[index % Self.xPositions.count] }
    // Дрейф: лепесток уходит в сторону от центра пропорционально своей позиции
    private var xDrift: CGFloat { xStart / 90 * 38 }
    private var delay: Double { 0.65 + Double(index) * 0.09 }
    private var rotation: Double { Double(index) * 36 }

    @State private var opacity: Double = 0
    @State private var risen = false

    var body: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [AppColor.accent.opacity(0.95), AppColor.accentLight.opacity(0.60)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: 12, height: 20)
            .rotationEffect(.degrees(rotation))
            .offset(
                x: xStart + (risen ? xDrift : 0),
                y: risen ? -75 : 0
            )
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.25).delay(delay)) {
                    opacity = 1.0
                }
                withAnimation(.easeOut(duration: 1.4).delay(delay + 0.15)) {
                    risen = true
                }
                withAnimation(.easeIn(duration: 0.7).delay(delay + 0.8)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - SparkleOverlay

/// Частицы-кружки разлетаются от центра OTP-поля при успешной авторизации.
struct SparkleOverlay: View {
    private let count = 16
    @State private var expanded = false

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let angle = Double(i) / Double(count) * 2 * .pi
                let distance: CGFloat = expanded ? 72 : 0
                Circle()
                    .fill(i % 2 == 0 ? AppColor.accent : AppColor.accentLight)
                    .frame(width: expanded ? 4 : 7, height: expanded ? 4 : 7)
                    .offset(
                        x: cos(angle) * distance,
                        y: sin(angle) * distance
                    )
                    .opacity(expanded ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) {
                expanded = true
            }
        }
    }
}

// MARK: - ScentenceTextField

struct ScentenceTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(AppFont.body(16))
                    .foregroundColor(AppColor.textMuted)
                    .padding(.horizontal, 16)
            }
            TextField("", text: $text)
                .font(AppFont.body(16))
                .foregroundColor(AppColor.textPrimary)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
        }
        .glassInputField(cornerRadius: 12)
    }
}

// MARK: - OTPField

struct OTPField: View {
    @Binding var code: String
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: code) { old, new in
                    if new.count > 6 { code = String(new.prefix(6)) }
                    let filtered = new.filter { $0.isNumber }
                    if filtered != new { code = filtered }
                    if new.count > old.count { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                }

            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    OTPDigitBox(
                        digit: digit(at: index),
                        isActive: isFocused && code.count == index
                    )
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
        .onAppear { isFocused = true }
    }

    private func digit(at index: Int) -> String? {
        guard index < code.count else { return nil }
        return String(code[code.index(code.startIndex, offsetBy: index)])
    }
}

struct OTPDigitBox: View {
    let digit: String?
    let isActive: Bool

    @State private var bounceScale: CGFloat = 1.0

    var body: some View {
        Text(digit ?? "")
            .font(AppFont.title(24))
            .foregroundColor(AppColor.textPrimary)
            .frame(width: 44, height: 56)
            .background(.ultraThinMaterial)
            .background(AppColor.accent.opacity(isActive ? 0.10 : 0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppColor.accent.opacity(isActive ? 0.75 : 0.35), lineWidth: isActive ? 1.5 : 1.0)
            )
            .shadow(color: AppColor.accent.opacity(isActive ? 0.35 : 0.15), radius: isActive ? 10 : 6, x: 0, y: 2)
            .scaleEffect(bounceScale)
            .onChange(of: digit) { _, new in
                guard new != nil else { return }
                withAnimation(.spring(response: 0.22, dampingFraction: 0.45)) {
                    bounceScale = 1.18
                }
                withAnimation(.spring(response: 0.22, dampingFraction: 0.65).delay(0.1)) {
                    bounceScale = 1.0
                }
            }
    }
}

// MARK: - ErrorLabel

struct ErrorLabel: View {
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 13))
            Text(text)
                .font(AppFont.caption(13))
        }
        .foregroundColor(AppColor.error)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Previews

#Preview("Экран входа – email") {
    AuthView()
        .environmentObject(AuthState())
}

#Preview("Логотип + лепестки") {
    ZStack {
        AppBackground()
        VStack(spacing: 16) {
            ZStack {
                Text("Scentence")
                    .font(AppFont.display(52))
                    .foregroundColor(AppColor.textPrimary)
                    .tracking(6)
                ForEach(0..<10, id: \.self) { i in
                    BloomPetal(index: i)
                }
            }
            AccentDivider().frame(width: 60)
        }
    }
}

#Preview("OTP + Sparkle") {
    ZStack {
        AppBackground()
        VStack(spacing: 32) {
            Text("Введите код")
                .font(AppFont.title(22))
                .foregroundColor(AppColor.textPrimary)
            ZStack {
                OTPField(code: .constant("394017"))
                SparkleOverlay()
            }
        }
        .padding(.horizontal, 32)
    }
}

#Preview("Тёмная тема") {
    AuthView()
        .environmentObject(AuthState())
        .preferredColorScheme(.dark)
}
