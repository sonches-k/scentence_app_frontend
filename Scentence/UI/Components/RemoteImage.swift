import SwiftUI

// MARK: - RemoteImage

struct RemoteImage: View {
    let url: URL
    var maxHeight: CGFloat = 260
    var horizontalPadding: CGFloat = 24

    @State private var image: UIImage?
    @State private var isFailed = false
    @State private var isLoading = true

    var body: some View {
        Group {
            if let image {
                imageContainer {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(16)
                }
            } else if isFailed {
                imageContainer {
                    Image(systemName: "photo")
                        .font(.system(size: 32, weight: .thin))
                        .foregroundColor(AppColor.textMuted)
                }
            } else {
                imageContainer {
                    ProgressView()
                        .tint(AppColor.textMuted)
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .frame(maxWidth: .infinity)
        .task(id: url) { await loadImage() }
    }

    // MARK: - Styled container

    @ViewBuilder
    private func imageContainer<C: View>(@ViewBuilder content: () -> C) -> some View {
        ZStack {
            Color.white
            content()
        }
        .frame(maxWidth: .infinity)
        .frame(height: maxHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColor.accent.opacity(0.55), lineWidth: 1.5)
        )
        .shadow(color: AppColor.accent.opacity(0.28), radius: 12, x: 0, y: 0)
        .shadow(color: AppColor.accent.opacity(0.10), radius: 28, x: 0, y: 6)
    }

    // MARK: - Load

    private func loadImage() async {
        isLoading = true
        isFailed = false
        image = nil

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 30
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            let session = URLSession(configuration: config)

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let uiImage = UIImage(data: data) else {
                isFailed = true
                isLoading = false
                return
            }

            image = uiImage
            isLoading = false
        } catch {
            isFailed = true
            isLoading = false
        }
    }
}

// MARK: - Previews

#Preview("Загружено – светлая тема") {
    ZStack {
        AppBackground()
        VStack(spacing: 24) {
            styledContainer(height: 260, horizontalPadding: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "flame")
                        .font(.system(size: 56, weight: .thin))
                        .foregroundColor(AppColor.accent.opacity(0.6))
                    Text("Chanel No.5")
                        .font(AppFont.title(15))
                        .foregroundColor(AppColor.textMuted)
                }
            }

            Text("CHANEL")
                .font(AppFont.caption(11))
                .foregroundColor(AppColor.accent)
                .tracking(2)

            Text("No.5 Eau de Parfum")
                .font(AppFont.title(22))
                .foregroundColor(AppColor.textPrimary)
        }
        .padding(.horizontal, 24)
    }
    .preferredColorScheme(.light)
}

#Preview("Загружено – тёмная тема") {
    ZStack {
        AppBackground()
        VStack(spacing: 24) {
            styledContainer(height: 260, horizontalPadding: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "flame")
                        .font(.system(size: 56, weight: .thin))
                        .foregroundColor(AppColor.accent.opacity(0.6))
                    Text("Tom Ford Noir")
                        .font(AppFont.title(15))
                        .foregroundColor(AppColor.textMuted)
                }
            }

            Text("TOM FORD")
                .font(AppFont.caption(11))
                .foregroundColor(AppColor.accent)
                .tracking(2)

            Text("Noir Eau de Parfum")
                .font(AppFont.title(22))
                .foregroundColor(AppColor.textPrimary)
        }
        .padding(.horizontal, 24)
    }
    .preferredColorScheme(.dark)
}

#Preview("Ошибка загрузки") {
    ZStack {
        AppBackground()
        styledContainer(height: 260, horizontalPadding: 24) {
            Image(systemName: "photo")
                .font(.system(size: 32, weight: .thin))
                .foregroundColor(AppColor.textMuted)
        }
        .padding(.horizontal, 32)
    }
    .preferredColorScheme(.light)
}

@ViewBuilder
private func styledContainer<C: View>(
    height: CGFloat,
    horizontalPadding: CGFloat,
    @ViewBuilder content: () -> C
) -> some View {
    ZStack {
        Color.white
        content()
    }
    .frame(maxWidth: .infinity)
    .frame(height: height)
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .overlay(
        RoundedRectangle(cornerRadius: 20)
            .stroke(AppColor.accent.opacity(0.55), lineWidth: 1.5)
    )
    .shadow(color: AppColor.accent.opacity(0.28), radius: 12, x: 0, y: 0)
    .shadow(color: AppColor.accent.opacity(0.10), radius: 28, x: 0, y: 6)
    .padding(.horizontal, horizontalPadding)
}
