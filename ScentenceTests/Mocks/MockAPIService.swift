import Foundation
@testable import Scentence

/// Мок API-сервиса для unit-тестов. Позволяет задать ответ или ошибку для каждого метода.
final class MockAPIService: APIServiceProtocol {

    // MARK: - Стабы

    var requestCodeResult: Result<MessageResponse, Error> = .failure(MockError.notConfigured)
    var verifyCodeResult: Result<TokenResponse, Error> = .failure(MockError.notConfigured)
    var getMeResult: Result<User, Error> = .failure(MockError.notConfigured)
    var searchResult: Result<SearchResponse, Error> = .failure(MockError.notConfigured)
    var getSimilarResult: Result<SimilarSearchResponse, Error> = .failure(MockError.notConfigured)
    var getPerfumeResult: Result<Perfume, Error> = .failure(MockError.notConfigured)
    var getAllFiltersResult: Result<AllFiltersResponse, Error> = .failure(MockError.notConfigured)
    var getFavoritesResult: Result<[FavoritePerfume], Error> = .failure(MockError.notConfigured)
    var addFavoriteResult: Result<MessageResponse, Error> = .failure(MockError.notConfigured)
    var removeFavoriteResult: Result<MessageResponse, Error> = .failure(MockError.notConfigured)
    var getHistoryResult: Result<[SearchHistoryEntry], Error> = .failure(MockError.notConfigured)
    var updateNameResult: Result<User, Error> = .failure(MockError.notConfigured)

    // MARK: - Счётчики вызовов

    var searchCallCount = 0
    var getPerfumeCallCount = 0
    var getFavoritesCallCount = 0
    var addFavoriteCallCount = 0
    var removeFavoriteCallCount = 0

    // MARK: - MockError

    enum MockError: Error, LocalizedError {
        case notConfigured
        case testError

        var errorDescription: String? {
            switch self {
            case .notConfigured: return "Мок не сконфигурирован"
            case .testError: return "Тестовая ошибка"
            }
        }
    }

    // MARK: - APIServiceProtocol

    func requestCode(email: String) async throws -> MessageResponse {
        try requestCodeResult.get()
    }

    func verifyCode(email: String, code: String) async throws -> TokenResponse {
        try verifyCodeResult.get()
    }

    func getMe(token: String) async throws -> User {
        try getMeResult.get()
    }

    func search(request: SearchRequest, token: String?) async throws -> SearchResponse {
        searchCallCount += 1
        return try searchResult.get()
    }

    func getSimilar(perfumeId: Int, limit: Int, token: String?) async throws -> SimilarSearchResponse {
        try getSimilarResult.get()
    }

    func getPerfume(id: Int, token: String?) async throws -> Perfume {
        getPerfumeCallCount += 1
        return try getPerfumeResult.get()
    }

    func getAllFilters(token: String?) async throws -> AllFiltersResponse {
        try getAllFiltersResult.get()
    }

    func getFavorites(token: String) async throws -> [FavoritePerfume] {
        getFavoritesCallCount += 1
        return try getFavoritesResult.get()
    }

    func addFavorite(perfumeId: Int, token: String) async throws -> MessageResponse {
        addFavoriteCallCount += 1
        return try addFavoriteResult.get()
    }

    func removeFavorite(perfumeId: Int, token: String) async throws -> MessageResponse {
        removeFavoriteCallCount += 1
        return try removeFavoriteResult.get()
    }

    func getHistory(token: String) async throws -> [SearchHistoryEntry] {
        try getHistoryResult.get()
    }

    func updateName(name: String, token: String) async throws -> User {
        try updateNameResult.get()
    }
}
