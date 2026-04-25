import Foundation
import OSLog

// MARK: - APIServiceProtocol

protocol APIServiceProtocol {
    func requestCode(email: String) async throws -> MessageResponse
    func verifyCode(email: String, code: String) async throws -> TokenResponse
    func getMe(token: String) async throws -> User
    func search(request: SearchRequest, token: String?) async throws -> SearchResponse
    func getSimilar(perfumeId: Int, limit: Int, token: String?) async throws -> SimilarSearchResponse
    func getPerfume(id: Int, token: String?) async throws -> Perfume
    func getAllFilters(token: String?) async throws -> AllFiltersResponse
    func suggestBrands(q: String, token: String?) async throws -> [String]
    func suggestNotes(q: String, token: String?) async throws -> [String]
    func getFavorites(token: String) async throws -> [FavoritePerfume]
    func addFavorite(perfumeId: Int, token: String) async throws -> MessageResponse
    func removeFavorite(perfumeId: Int, token: String) async throws -> MessageResponse
    func getHistory(token: String) async throws -> [SearchHistoryEntry]
    func deleteHistoryEntry(entryId: Int, token: String) async throws
    func clearHistory(token: String) async throws
    func updateName(name: String, token: String) async throws -> User
    func refreshTokens(refreshToken: String) async throws -> TokenResponse
    func logout(refreshToken: String) async throws -> MessageResponse
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

    /// Таймаут 120 с — LLM на бэкенде может отвечать долго.
    /// URLCache + useProtocolCachePolicy: GET /perfumes/filters отдаёт ETag,
    /// при неизменных данных сервер возвращает 304 и тело не гоняется по сети.
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.urlCache = URLCache(
            memoryCapacity: 4 * 1024 * 1024,
            diskCapacity: 20 * 1024 * 1024,
            diskPath: "scentence_api_cache"
        )
        config.requestCachePolicy = .useProtocolCachePolicy
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
        let urlRequest = try buildURLRequest(endpoint, method: method, body: body, token: token)

        #if DEBUG
        logger.debug("→ \(method) \(endpoint)")
        #endif

        let (data, response) = try await session.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        #if DEBUG
        logger.debug("← \(http.statusCode) \(endpoint)")
        #endif

        // 401 interceptor: refresh + retry (пропускаем auth-эндпоинты чтобы не зациклиться)
        if http.statusCode == 401, !endpoint.hasPrefix("/auth/") {
            let newTokens = try await performTokenRefresh()
            let retryRequest = try buildURLRequest(endpoint, method: method, body: body, token: newTokens.accessToken)
            let (retryData, retryResponse) = try await session.data(for: retryRequest)
            guard let retryHttp = retryResponse as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            return try decode(retryData, statusCode: retryHttp.statusCode)
        }

        return try decode(data, statusCode: http.statusCode)
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

    // MARK: - Token management

    func refreshTokens(refreshToken: String) async throws -> TokenResponse {
        try await request("/auth/refresh", method: "POST", body: RefreshRequest(refreshToken: refreshToken))
    }

    func logout(refreshToken: String) async throws -> MessageResponse {
        try await request("/auth/logout", method: "POST", body: RefreshRequest(refreshToken: refreshToken))
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
        try await request("/perfumes/filters", token: token)
    }

    func suggestBrands(q: String = "", token: String? = nil) async throws -> [String] {
        let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await request("/perfumes/brands/suggest?q=\(encoded)&limit=20", token: token)
    }

    func suggestNotes(q: String = "", token: String? = nil) async throws -> [String] {
        let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await request("/perfumes/notes/suggest?q=\(encoded)&limit=20", token: token)
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

    func deleteHistoryEntry(entryId: Int, token: String) async throws {
        try await requestVoid("/users/history/\(entryId)", method: "DELETE", token: token)
    }

    func clearHistory(token: String) async throws {
        try await requestVoid("/users/history", method: "DELETE", token: token)
    }

    func updateName(name: String, token: String) async throws -> User {
        try await request("/users/profile", method: "PUT", body: UpdateNameRequest(name: name), token: token)
    }

    // MARK: - Private helpers

    private func buildURLRequest(
        _ endpoint: String,
        method: String,
        body: Encodable?,
        token: String?
    ) throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.httpBody = try JSONEncoder().encode(body)
        }
        return req
    }

    private func decode<T: Decodable>(_ data: Data, statusCode: Int) throws -> T {
        try verifyStatus(data, statusCode: statusCode)
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Для эндпоинтов, возвращающих 204 No Content (тело отсутствует).
    private func requestVoid(_ endpoint: String, method: String, token: String?) async throws {
        let urlRequest = try buildURLRequest(endpoint, method: method, body: nil, token: token)

        #if DEBUG
        logger.debug("→ \(method) \(endpoint)")
        #endif

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }

        #if DEBUG
        logger.debug("← \(http.statusCode) \(endpoint)")
        #endif

        if http.statusCode == 401 {
            let newTokens = try await performTokenRefresh()
            let retry = try buildURLRequest(endpoint, method: method, body: nil, token: newTokens.accessToken)
            let (retryData, retryResponse) = try await session.data(for: retry)
            guard let retryHttp = retryResponse as? HTTPURLResponse else { throw NetworkError.invalidResponse }
            try verifyStatus(retryData, statusCode: retryHttp.statusCode)
            return
        }

        try verifyStatus(data, statusCode: http.statusCode)
    }

    private func verifyStatus(_ data: Data, statusCode: Int) throws {
        guard !(200...299).contains(statusCode) else { return }
        if let apiError = try? JSONDecoder().decode(APIError.self, from: data) { throw apiError }
        throw NetworkError.httpError(statusCode)
    }

    /// Обновляет оба токена через /auth/refresh, сохраняет в Keychain и уведомляет AuthState.
    /// При ошибке — постит .forceSignOut.
    private func performTokenRefresh() async throws -> TokenResponse {
        guard let storedRefresh = KeychainService.shared.getRefreshToken() else {
            NotificationCenter.default.post(name: .forceSignOut, object: nil)
            throw NetworkError.unauthorized
        }
        do {
            let tokens: TokenResponse = try await request(
                "/auth/refresh", method: "POST",
                body: RefreshRequest(refreshToken: storedRefresh)
            )
            KeychainService.shared.saveToken(tokens.accessToken)
            KeychainService.shared.saveRefreshToken(tokens.refreshToken)
            NotificationCenter.default.post(name: .tokenRefreshed, object: tokens.accessToken)
            return tokens
        } catch {
            NotificationCenter.default.post(name: .forceSignOut, object: nil)
            throw error
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// APIService постит при успешном авто-обновлении токена. object = новый accessToken (String).
    static let tokenRefreshed = Notification.Name("com.scentence.tokenRefreshed")
    /// APIService постит когда refresh истёк/невалиден — нужно разлогинить.
    static let forceSignOut   = Notification.Name("com.scentence.forceSignOut")
}

// MARK: - NetworkError

/// Ошибки сетевого уровня (до разбора ответа бэкенда).
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:         return "Неверный URL"
        case .invalidResponse:    return "Некорректный ответ сервера"
        case .httpError(let c):   return "Ошибка сервера: \(c)"
        case .unauthorized:       return "Сессия истекла. Войдите снова."
        }
    }
}
