import SwiftUI

struct RemoteImage: View {
    let url: URL
    var maxHeight: CGFloat = 280

    @State private var image: UIImage?
    @State private var isFailed = false
    @State private var isLoading = true

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: maxHeight)
                    .mask(
                        ZStack {
                            LinearGradient(
                                stops: [
                                    .init(color: .black.opacity(0.7), location: 0),
                                    .init(color: .black, location: 0.08),
                                    .init(color: .black, location: 0.80),
                                    .init(color: .clear,              location: 1),
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .black, location: 0.12),
                                    .init(color: .black, location: 0.88),
                                    .init(color: .clear, location: 1),
                                ],
                                startPoint: .leading, endPoint: .trailing
                            )
                            .blendMode(.multiply)
                        }
                    )
            } else if isFailed {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 28, weight: .thin))
                        .foregroundColor(AppColor.textMuted)
                }
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .background(AppColor.cardBorder.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ProgressView()
                    .tint(AppColor.surface)
                    .frame(height: 200)
            }
        }
        .frame(maxWidth: .infinity)
        .task(id: url) {
            await loadImage()
        }
    }

    // MARK: - Edge-fade mask (reused in preview)
    static func edgeFadeMask() -> some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.7), location: 0),
                    .init(color: .black, location: 0.08),
                    .init(color: .black, location: 0.80),
                    .init(color: .clear,              location: 1),
                ],
                startPoint: .top, endPoint: .bottom
            )
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.12),
                    .init(color: .black, location: 0.88),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .leading, endPoint: .trailing
            )
            .blendMode(.multiply)
        }
    }

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

// MARK: - Preview

#Preview("Edge fade – Light") {
    ZStack {
        AppBackground()
        VStack(spacing: 0) {
            // Имитация фото флакона: цветной прямоугольник с градиентом
            LinearGradient(
                colors: [AppColor.accentLight, AppColor.accent.opacity(0.6)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(height: 280)
            .mask(RemoteImage.edgeFadeMask())

            Text("Chanel No.5")
                .font(AppFont.display(26))
                .foregroundColor(AppColor.textPrimary)
                .padding(.top, 16)
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Edge fade – Dark") {
    ZStack {
        AppBackground()
        VStack(spacing: 0) {
            LinearGradient(
                colors: [AppColor.accentLight, AppColor.accent.opacity(0.6)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(height: 280)
            .mask(RemoteImage.edgeFadeMask())

            Text("Chanel No.5")
                .font(AppFont.display(26))
                .foregroundColor(AppColor.textPrimary)
                .padding(.top, 16)
        }
    }
    .preferredColorScheme(.dark)
}
