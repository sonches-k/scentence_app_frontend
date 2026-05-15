import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var viewModel = AuthViewModel()
    @State private var logoVisible = false
    @FocusState private var isEmailFocused: Bool

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
            .scrollDismissesKeyboard(.interactively)
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
            ZStack {
                Text("Scentence")
                    .font(AppFont.display(52))
                    .foregroundColor(AppColor.textPrimary)
                    .tracking(6)

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
            .focused($isEmailFocused)
            .onSubmit {
                isEmailFocused = false
                Task { await viewModel.requestCode() }
            }

            if let error = viewModel.errorMessage {
                ErrorLabel(text: error)
            }

            Button("Получить код") {
                isEmailFocused = false
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
                hideKeyboard()
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
