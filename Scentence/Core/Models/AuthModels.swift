import Foundation

// MARK: - Request

/// Запрос на отправку кода подтверждения на email.
struct RequestCodeRequest: Encodable {
    let email: String
}

/// Запрос на проверку кода подтверждения.
struct VerifyCodeRequest: Encodable {
    let email: String
    let code: String
}

// MARK: - Response

/// Ответ сервера с парой токенов после верификации или обновления.
struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case tokenType    = "token_type"
    }
}

/// Запрос на обновление токена или выход из аккаунта.
struct RefreshRequest: Encodable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

/// Простой ответ сервера с текстовым сообщением.
struct MessageResponse: Decodable {
    let message: String
}

// MARK: - API Error

/// Ошибка API в формате `{"detail": "..."}`.
struct APIError: Decodable, LocalizedError {
    let detail: String

    var errorDescription: String? { detail }
}
