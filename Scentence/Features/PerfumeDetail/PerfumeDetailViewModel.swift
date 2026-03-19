import Foundation

@MainActor
final class PerfumeDetailViewModel: ObservableObject {
    @Published var perfume: Perfume?
    @Published var similarPerfumes: [PerfumeWithRelevance] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingSimilar: Bool = false
    @Published var isFavorite: Bool = false
    @Published var isFavoriteLoading: Bool = false
    @Published var errorMessage: String?

    private let api: APIServiceProtocol

    init(api: APIServiceProtocol = APIService.shared) {
        self.api = api
    }

    func load(perfumeId: Int, token: String?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let perfumeResult = api.getPerfume(id: perfumeId, token: token)
            async let similarResult = api.getSimilar(perfumeId: perfumeId, limit: 5, token: token)

            perfume = try await perfumeResult

            if let resp = try? await similarResult {
                similarPerfumes = resp.similarPerfumes
            }

            if let token {
                await checkFavorite(perfumeId: perfumeId, token: token)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func checkFavorite(perfumeId: Int, token: String) async {
        if let favorites = try? await api.getFavorites(token: token) {
            isFavorite = favorites.contains { $0.id == perfumeId }
        }
    }

    func toggleFavorite(perfumeId: Int, token: String) async {
        isFavoriteLoading = true
        defer { isFavoriteLoading = false }

        do {
            if isFavorite {
                _ = try await api.removeFavorite(perfumeId: perfumeId, token: token)
                isFavorite = false
            } else {
                _ = try await api.addFavorite(perfumeId: perfumeId, token: token)
                isFavorite = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
