import Foundation

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
