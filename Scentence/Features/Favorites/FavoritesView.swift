import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var viewModel = FavoritesViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                if viewModel.isLoading {
                    LoadingView(message: "Загружаем избранное...")
                } else if viewModel.favorites.isEmpty {
                    EmptyStateView(
                        icon: "heart",
                        title: "Нет избранных",
                        subtitle: "Добавляйте ароматы из поиска"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.favorites) { perfume in
                                NavigationLink {
                                    PerfumeDetailView(perfumeId: perfume.id)
                                } label: {
                                    FavoritePerfumeRow(perfume: perfume) {
                                        guard let token = authState.token else { return }
                                        Task { await viewModel.removeFavorite(perfumeId: perfume.id, token: token) }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Избранное")
            .navigationBarTitleDisplayMode(.inline)
            .glassNavBar()
            .tint(AppColor.accent)
            .task {
                guard let token = authState.token else { return }
                await viewModel.load(token: token)
            }
            .refreshable {
                guard let token = authState.token else { return }
                await viewModel.load(token: token)
            }
        }
    }
}

// MARK: - FavoritesViewModel

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published var favorites: [FavoritePerfume] = []
    @Published var isLoading = false

    private let api: APIServiceProtocol

    init(api: APIServiceProtocol = APIService.shared) {
        self.api = api
    }

    func load(token: String) async {
        isLoading = true
        defer { isLoading = false }
        favorites = ((try? await api.getFavorites(token: token)) ?? []).reversed()
    }

    func removeFavorite(perfumeId: Int, token: String) async {
        _ = try? await api.removeFavorite(perfumeId: perfumeId, token: token)
        favorites.removeAll { $0.id == perfumeId }
    }
}

// MARK: - FavoritePerfumeRow

struct FavoritePerfumeRow: View {
    let perfume: FavoritePerfume
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let urlStr = perfume.imageUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        RoundedRectangle(cornerRadius: 8).fill(AppColor.cardBorder.opacity(0.4))
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(perfume.brand.uppercased())
                    .font(AppFont.caption(9))
                    .foregroundColor(AppColor.accent)
                    .tracking(2)
                Text(perfume.name)
                    .font(AppFont.body(16))
                    .foregroundColor(AppColor.textPrimary)
                    .lineLimit(1)

                if let family = perfume.family {
                    Text(family)
                        .font(AppFont.caption(12))
                        .foregroundColor(AppColor.textMuted)
                }
            }
            Spacer()
            Button { onRemove() } label: {
                Image(systemName: "heart.slash")
                    .foregroundColor(AppColor.textMuted)
                    .font(.system(size: 16))
            }
        }
        .padding(14)
        .cardStyle()
    }
}
