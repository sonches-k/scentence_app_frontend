import Foundation

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published var favorites: [FavoritePerfume] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api: APIServiceProtocol

    init(api: APIServiceProtocol = APIService.shared) {
        self.api = api
    }

    func load(token: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            favorites = try await api.getFavorites(token: token).reversed()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeFavorite(perfumeId: Int, token: String) async {
        _ = try? await api.removeFavorite(perfumeId: perfumeId, token: token)
        favorites.removeAll { $0.id == perfumeId }
    }
}
