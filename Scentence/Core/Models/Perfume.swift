import Foundation

// MARK: - Perfume

/// Полная модель аромата, соответствует ответу `/perfumes/{id}`.
struct Perfume: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let brand: String
    let year: Int?
    let productType: String?
    let family: String?
    let gender: String?
    let description: String?
    let imageUrl: String?
    let sourceUrl: String?
    let notes: [PerfumeNote]
    let tags: [PerfumeTag]
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, brand, year, family, gender, description, notes, tags
        case productType = "product_type"
        case imageUrl    = "image_url"
        case sourceUrl   = "source_url"
        case createdAt   = "created_at"
        case updatedAt   = "updated_at"
    }

    var notePyramid: NotePyramid {
        NotePyramid(
            top:    notes.filter { $0.level.lowercased() == "top"    }.map { $0.note.name },
            middle: notes.filter { $0.level.lowercased() == "middle" }.map { $0.note.name },
            base:   notes.filter { $0.level.lowercased() == "base"   }.map { $0.note.name }
        )
    }

    var allTagNames: [String] { tags.map { $0.tag } }

    static func == (lhs: Perfume, rhs: Perfume) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - PerfumeNote / Note

/// Связь аромата с нотой определённого уровня (top / middle / base).
struct PerfumeNote: Codable, Hashable {
    let note: Note
    let level: String
}

/// Парфюмерная нота (ингредиент аромата).
struct Note: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let category: String?
}

// MARK: - PerfumeTag

/// Тег аромата с уровнем уверенности (генерируется LLM).
struct PerfumeTag: Codable, Hashable {
    let tag: String
    let confidence: Double?
    let source: String?
}

// MARK: - NotePyramid

/// Пирамида нот аромата: верхние, сердечные и базовые ноты.
struct NotePyramid: Codable, Hashable {
    let top: [String]
    let middle: [String]
    let base: [String]

    var isEmpty: Bool { top.isEmpty && middle.isEmpty && base.isEmpty }
    var allNotes: [String] { top + middle + base }
}

// MARK: - PerfumeWithRelevance

/// Аромат из результатов поиска с оценкой релевантности (0...1).
struct PerfumeWithRelevance: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let brand: String
    let imageUrl: String?
    let sourceUrl: String?
    let family: String?
    let gender: String?
    let topNotes: [String]
    let middleNotes: [String]
    let baseNotes: [String]
    let relevance: Double

    enum CodingKeys: String, CodingKey {
        case id, name, brand, family, gender, relevance
        case imageUrl    = "image_url"
        case sourceUrl   = "source_url"
        case topNotes    = "top_notes"
        case middleNotes = "middle_notes"
        case baseNotes   = "base_notes"
    }

    var notePyramid: NotePyramid {
        NotePyramid(top: topNotes, middle: middleNotes, base: baseNotes)
    }

    var relevanceScore: Double { relevance }
    var relevancePercent: Int { Int((relevance * 100).rounded()) }

    func toPerfume() -> Perfume {
        Perfume(
            id: id, name: name, brand: brand, year: nil,
            productType: nil, family: family, gender: gender,
            description: nil, imageUrl: imageUrl, sourceUrl: sourceUrl,
            notes: [], tags: [], createdAt: nil, updatedAt: nil
        )
    }

    static func == (lhs: PerfumeWithRelevance, rhs: PerfumeWithRelevance) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - FavoritePerfume

/// Аромат из списка избранного пользователя.
struct FavoritePerfume: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let brand: String
    let imageUrl: String?
    let sourceUrl: String?
    let family: String?
    let gender: String?
    let topNotes: [String]
    let middleNotes: [String]
    let baseNotes: [String]

    enum CodingKeys: String, CodingKey {
        case id, name, brand, family, gender
        case imageUrl    = "image_url"
        case sourceUrl   = "source_url"
        case topNotes    = "top_notes"
        case middleNotes = "middle_notes"
        case baseNotes   = "base_notes"
    }

    static func == (lhs: FavoritePerfume, rhs: FavoritePerfume) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
