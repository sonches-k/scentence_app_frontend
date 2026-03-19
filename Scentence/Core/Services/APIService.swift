import Foundation
import OSLog

// MARK: - APIServiceProtocol

/// Протокол сетевого сервиса для Dependency Injection и тестирования.
protocol APIServiceProtocol {
    func requestCode(email: String) async throws -> MessageResponse
    func verifyCode(email: String, code: String) async throws -> TokenResponse
    func getMe(token: String) async throws -> User
    func search(request: SearchRequest, token: String?) async throws -> SearchResponse
    func getSimilar(perfumeId: Int, limit: Int, token: String?) async throws -> SimilarSearchResponse
    func getPerfume(id: Int, token: String?) async throws -> Perfume
    func getAllFilters(token: String?) async throws -> AllFiltersResponse
    func getFavorites(token: String) async throws -> [FavoritePerfume]
    func addFavorite(perfumeId: Int, token: String) async throws -> MessageResponse
    func removeFavorite(perfumeId: Int, token: String) async throws -> MessageResponse
    func getHistory(token: String) async throws -> [SearchHistoryEntry]
    func updateName(name: String, token: String) async throws -> User
}

// MARK: - APIService

final class APIService: APIServiceProtocol {
    static let shared = APIService()

    #if DEBUG
    private let baseURL = "http://localhost:8000/api/v1"
    #else
    private let baseURL = "https://api.scentence.app/api/v1"
    #endif

    private let logger = Logger(subsystem: "com.scentence", category: "API")

    /// Таймаут 120 с из-за медленной генерации LLM на бэкенде
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        return URLSession(configuration: config)
    }()

    private init() {}

    // MARK: - Generic request

    func request<T: Decodable>(
        _ endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        token: String? = nil
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        #if DEBUG
        logger.debug("→ \(method) \(endpoint)")
        #endif

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        #if DEBUG
        logger.debug("← \(httpResponse.statusCode) \(endpoint)")
        #endif

        if !(200...299).contains(httpResponse.statusCode) {
            if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                throw apiError
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Auth

    func requestCode(email: String) async throws -> MessageResponse {
        try await request("/auth/register/", method: "POST", body: RequestCodeRequest(email: email))
    }

    func verifyCode(email: String, code: String) async throws -> TokenResponse {
        try await request("/auth/verify/", method: "POST", body: VerifyCodeRequest(email: email, code: code))
    }

    func getMe(token: String) async throws -> User {
        try await request("/users/profile", token: token)
    }

    // MARK: - Search

    func search(request searchRequest: SearchRequest, token: String?) async throws -> SearchResponse {
        try await request("/search/", method: "POST", body: searchRequest, token: token)
    }

    func getSimilar(perfumeId: Int, limit: Int = 5, token: String?) async throws -> SimilarSearchResponse {
        try await request("/search/similar/\(perfumeId)/?limit=\(limit)", method: "POST", token: token)
    }

    // MARK: - Perfumes

    func getPerfume(id: Int, token: String?) async throws -> Perfume {
        try await request("/perfumes/\(id)", token: token)
    }

    func getAllFilters(token: String?) async throws -> AllFiltersResponse {
        try await request("/perfumes/filters/all", token: token)
    }

    // MARK: - Favorites

    func getFavorites(token: String) async throws -> [FavoritePerfume] {
        try await request("/users/favorites", token: token)
    }

    func addFavorite(perfumeId: Int, token: String) async throws -> MessageResponse {
        try await request("/users/favorites/\(perfumeId)", method: "POST", token: token)
    }

    func removeFavorite(perfumeId: Int, token: String) async throws -> MessageResponse {
        try await request("/users/favorites/\(perfumeId)", method: "DELETE", token: token)
    }

    // MARK: - Profile

    func getHistory(token: String) async throws -> [SearchHistoryEntry] {
        try await request("/users/history", token: token)
    }

    func updateName(name: String, token: String) async throws -> User {
        try await request("/users/profile", method: "PUT", body: UpdateNameRequest(name: name), token: token)
    }
}

// MARK: - NetworkError

/// Ошибки сетевого уровня (до разбора ответа бэкенда).
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:         return "Неверный URL"
        case .invalidResponse:    return "Некорректный ответ сервера"
        case .httpError(let c):   return "Ошибка сервера: \(c)"
        }
    }
}
