import Foundation

// MARK: - User

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

struct UpdateNameRequest: Encodable {
    let name: String
}

// MARK: - SearchHistoryEntry

struct SearchHistoryEntry: Codable, Identifiable {
    let id: Int
    let query: String
    let filters: [String: AnyCodable]?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, query, filters
        case createdAt = "created_at"
    }

    var parsedFilters: SearchFilters? {
        guard let filters, !filters.isEmpty else { return nil }

        func strings(_ key: String) -> [String]? {
            guard let raw = filters[key]?.value else { return nil }
            // [String] as? [Any] fails at runtime in Swift (arrays are not covariant),
            // so try the concrete [String] cast first, then fall back to [Any].
            if let arr = raw as? [String] { return arr.isEmpty ? nil : arr }
            if let arr = raw as? [Any] {
                let result = arr.compactMap { $0 as? String }
                return result.isEmpty ? nil : result
            }
            return nil
        }
        func integer(_ key: String) -> Int? {
            if let i = filters[key]?.value as? Int    { return i }
            if let d = filters[key]?.value as? Double { return Int(d) }
            return nil
        }

        let f = SearchFilters(
            genders:      strings("genders"),
            families:     strings("families"),
            productTypes: strings("product_types"),
            categories:   strings("categories"),
            brands:       strings("brands"),
            notes:        strings("notes"),
            yearFrom:     integer("year_from"),
            yearTo:       integer("year_to")
        )
        return f.isEmpty ? nil : f
    }

    var filterChips: [String] {
        guard let f = parsedFilters else { return [] }
        var chips: [String] = []
        chips += f.genders      ?? []
        chips += f.families     ?? []
        chips += f.productTypes ?? []
        chips += f.categories   ?? []
        chips += (f.brands ?? []).prefix(2)
        chips += (f.notes  ?? []).prefix(2)
        if let from = f.yearFrom, let to = f.yearTo { chips.append("\(from)–\(to)") }
        else if let from = f.yearFrom { chips.append("от \(from)") }
        else if let to   = f.yearTo   { chips.append("до \(to)") }
        return chips
    }
}
