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
