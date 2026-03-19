import Foundation

// MARK: - User

/// Профиль пользователя, соответствует ответу `/users/profile`.
struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let name: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, email, name
        case createdAt = "created_at"
    }

    var displayName: String {
        if let n = name, !n.isEmpty { return n }
        return email.components(separatedBy: "@").first ?? email
    }
}

// MARK: - UpdateNameRequest

/// Запрос на обновление имени пользователя.
struct UpdateNameRequest: Encodable {
    let name: String
}

// MARK: - SearchHistoryEntry

/// Запись из истории поисковых запросов пользователя.
struct SearchHistoryEntry: Codable, Identifiable {
    let id: Int
    let query: String
    let filters: [String: AnyCodable]?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, query, filters
        case createdAt = "created_at"
    }
}
