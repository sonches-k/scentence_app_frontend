import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showSignOutAlert = false

    @State private var photoItem: PhotosPickerItem?
    @State private var profileImage: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 0) {
                        avatarSection
                            .padding(.top, 32)
                            .padding(.bottom, 32)

                        GoldDivider().padding(.horizontal, 24)

                        settingsSection
                            .padding(.top, 24)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .glassNavBar()
            .tint(AppColor.gold)
            .alert("Выйти из аккаунта?", isPresented: $showSignOutAlert) {
                Button("Выйти", role: .destructive) { authState.signOut() }
                Button("Отмена", role: .cancel) {}
            }
            .task {
                guard let token = authState.token else { return }
                if authState.currentUser == nil {
                    if let user = await viewModel.loadProfile(token: token) {
                        authState.updateUser(user)
                    }
                }
                loadSavedPhoto()
            }
            .onChange(of: photoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        profileImage = img
                        savePhoto(img)
                    }
                }
            }
        }
    }

    // MARK: - Avatar + Name

    private var avatarSection: some View {
        VStack(spacing: 20) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    avatarCircle
                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white, AppColor.gold)
                        .offset(x: 4, y: 4)
                }
            }
            .buttonStyle(.plain)

            if viewModel.isEditingName {
                nameEditingView
            } else {
                nameDisplayView
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var avatarCircle: some View {
        Group {
            if let img = profileImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(String(authState.currentUser?.displayName.prefix(1).uppercased() ?? "?"))
                    .font(AppFont.display(34))
                    .foregroundColor(AppColor.gold)
            }
        }
        .frame(width: 88, height: 88)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .overlay(Circle().stroke(AppColor.gold.opacity(0.55), lineWidth: 1.5))
            .shadow(color: AppColor.gold.opacity(0.30), radius: 16, x: 0, y: 4)
            .shadow(color: AppColor.gold.opacity(0.12), radius: 32, x: 0, y: 0)
    }

    private var nameDisplayView: some View {
        VStack(spacing: 4) {
            Button {
                viewModel.newName = authState.currentUser?.name ?? ""
                viewModel.isEditingName = true
            } label: {
                HStack(spacing: 6) {
                    Text(authState.currentUser?.displayName ?? "Пользователь")
                        .font(AppFont.title(20))
                        .foregroundColor(AppColor.textPrimary)
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 15))
                        .foregroundColor(AppColor.textMuted)
                }
            }
            Text(authState.currentUser?.email ?? "")
                .font(AppFont.caption(13))
                .foregroundColor(AppColor.textSecondary)
        }
    }

    private var nameEditingView: some View {
        VStack(spacing: 12) {
            TextField("Введите имя", text: $viewModel.newName)
                .font(AppFont.body(17))
                .foregroundColor(AppColor.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .glassInputField(cornerRadius: 14)
                .padding(.horizontal, 48)

            HStack(spacing: 12) {
                Button {
                    viewModel.isEditingName = false
                } label: {
                    Text("Отмена")
                        .font(AppFont.caption(14))
                        .foregroundColor(AppColor.textSecondary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .glassCapsule()
                }

                Button {
                    guard let token = authState.token else { return }
                    Task {
                        if let user = await viewModel.updateName(token: token) {
                            authState.updateUser(user)
                        }
                    }
                } label: {
                    Text("Сохранить")
                        .font(AppFont.caption(14))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(AppColor.gold)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(spacing: 12) {
            settingsRow(
                icon: appState.isDarkMode ? "moon.fill" : "sun.max.fill",
                iconColor: appState.isDarkMode ? Color(hex: "#8B9DE8") : Color(hex: "#F5A623"),
                title: "Тёмная тема"
            ) {
                Toggle("", isOn: $appState.isDarkMode)
                    .labelsHidden()
                    .tint(AppColor.gold)
            }

            Button {
                showSignOutAlert = true
            } label: {
                settingsRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    iconColor: AppColor.error,
                    title: "Выйти из аккаунта"
                ) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.textMuted)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
    }

    private func settingsRow<Trailing: View>(
        icon: String,
        iconColor: Color,
        title: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(title)
                .font(AppFont.body(16))
                .foregroundColor(AppColor.textPrimary)

            Spacer()

            trailing()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .cardStyle()
    }

    // MARK: - Photo persistence

    private func savePhoto(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.6) {
            UserDefaults.standard.set(data, forKey: "profileImageData")
        }
    }

    private func loadSavedPhoto() {
        if let data = UserDefaults.standard.data(forKey: "profileImageData"),
           let img = UIImage(data: data) {
            profileImage = img
        }
    }
}
