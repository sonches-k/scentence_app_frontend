import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 0) {
                    logoSection
                        .padding(.top, 80)
                        .padding(.bottom, 60)

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
    }

    // MARK: - Logo

    private var logoSection: some View {
        VStack(spacing: 12) {
            Text("Scentence")
                .font(AppFont.display(42))
                .foregroundColor(AppColor.textPrimary)
                .tracking(6)

            Text("подбор ароматов")
                .font(AppFont.caption(13))
                .foregroundColor(AppColor.textSecondary)
                .tracking(4)
                .textCase(.uppercase)

            GoldDivider()
                .frame(width: 60)
                .padding(.top, 8)
        }
    }

    // MARK: - Email Step

    private var emailStep: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Войти / зарегистрироваться")
                    .font(AppFont.title(22))
                    .foregroundColor(AppColor.textPrimary)

                Text("Введите email — пришлём код подтверждения")
                    .font(AppFont.caption(14))
                    .foregroundColor(AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

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
            .buttonStyle(GoldButtonStyle())
            .disabled(viewModel.isLoading)
            .overlay(
                Group {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    }
                }
            )
        }
    }

    // MARK: - Code Step

    private var codeStep: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Введите код")
                    .font(AppFont.title(22))
                    .foregroundColor(AppColor.textPrimary)

                if let msg = viewModel.successMessage {
                    Text(msg)
                        .font(AppFont.caption(14))
                        .foregroundColor(AppColor.textSecondary)
                } else {
                    Text("6-значный код из письма")
                        .font(AppFont.caption(14))
                        .foregroundColor(AppColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            OTPField(code: $viewModel.code)

            if let error = viewModel.errorMessage {
                ErrorLabel(text: error)
            }

            Button("Войти") {
                Task { await viewModel.verifyCode(authState: authState) }
            }
            .buttonStyle(GoldButtonStyle())
            .disabled(viewModel.isLoading || viewModel.code.count < 6)
            .overlay(
                Group {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    }
                }
            )

            HStack(spacing: 16) {
                Button("← Назад") { viewModel.backToEmail() }
                    .font(AppFont.caption(14))
                    .foregroundColor(AppColor.textSecondary)

                Spacer()

                Button("Отправить снова") {
                    Task { await viewModel.resendCode() }
                }
                .font(AppFont.caption(14))
                .foregroundColor(AppColor.gold)
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
                .onChange(of: code) { _, new in
                    if new.count > 6 { code = String(new.prefix(6)) }
                    let filtered = new.filter { $0.isNumber }
                    if filtered != new { code = filtered }
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

    var body: some View {
        Text(digit ?? "")
            .font(AppFont.title(24))
            .foregroundColor(AppColor.textPrimary)
            .frame(width: 44, height: 56)
            .background(.ultraThinMaterial)
            .background(AppColor.gold.opacity(isActive ? 0.10 : 0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppColor.gold.opacity(isActive ? 0.75 : 0.35), lineWidth: isActive ? 1.5 : 1.0)
            )
            .shadow(color: AppColor.gold.opacity(isActive ? 0.35 : 0.15), radius: isActive ? 10 : 6, x: 0, y: 2)
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
