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

/// Ответ сервера с JWT-токеном после успешной верификации.
struct TokenResponse: Decodable {
    let accessToken: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType   = "token_type"
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
