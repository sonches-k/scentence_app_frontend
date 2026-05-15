import SwiftUI

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
                    if new.count > old.count {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    if new.count == 6 { isFocused = false }
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

// MARK: - OTPDigitBox

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
                withAnimation(.spring(response: 0.22, dampingFraction: 0.45)) { bounceScale = 1.18 }
                withAnimation(.spring(response: 0.22, dampingFraction: 0.65).delay(0.1)) { bounceScale = 1.0 }
            }
    }
}
