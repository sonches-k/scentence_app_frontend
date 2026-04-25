import Foundation

// MARK: - SearchRequest

/// Запрос поиска ароматов по текстовому описанию с фильтрами.
struct SearchRequest: Encodable {
    let query: String
    let filters: SearchFilters?
    let limit: Int

    init(query: String, filters: SearchFilters? = nil, limit: Int = 5) {
        self.query = query
        self.filters = filters
        self.limit = limit
    }
}

// MARK: - SearchFilters

/// Набор фильтров для сужения поисковой выдачи.
struct SearchFilters: Encodable {
    var genders: [String]?
    var families: [String]?
    var productTypes: [String]?
    var brands: [String]?
    var notes: [String]?
    var yearFrom: Int?
    var yearTo: Int?

    enum CodingKeys: String, CodingKey {
        case genders, families, brands, notes
        case productTypes = "product_types"
        case yearFrom     = "year_from"
        case yearTo       = "year_to"
    }

    var isEmpty: Bool {
        (genders?.isEmpty ?? true) &&
        (families?.isEmpty ?? true) &&
        (productTypes?.isEmpty ?? true) &&
        (brands?.isEmpty ?? true) &&
        (notes?.isEmpty ?? true) &&
        yearFrom == nil &&
        yearTo == nil
    }

    var activeCount: Int {
        var count = 0
        if let g = genders, !g.isEmpty { count += 1 }
        if let f = families, !f.isEmpty { count += 1 }
        if let p = productTypes, !p.isEmpty { count += 1 }
        if let b = brands, !b.isEmpty { count += 1 }
        if let n = notes, !n.isEmpty { count += 1 }
        if yearFrom != nil || yearTo != nil { count += 1 }
        return count
    }
}

// MARK: - SearchResponse

/// Ответ сервера на поисковый запрос: найденные ароматы, пирамида нот и пояснение.
struct SearchResponse: Decodable {
    let query: String
    let notePyramid: NotePyramid
    let explanation: String
    let perfumes: [PerfumeWithRelevance]
    let filtersApplied: [String: AnyCodable]?
    let totalFound: Int

    enum CodingKeys: String, CodingKey {
        case query, explanation, perfumes
        case notePyramid    = "note_pyramid"
        case filtersApplied = "filters_applied"
        case totalFound     = "total_found"
    }
}

// MARK: - SimilarSearchResponse

/// Ответ на запрос похожих ароматов для заданного парфюма.
struct SimilarSearchResponse: Decodable {
    let sourcePerfumeId: Int
    let similarPerfumes: [PerfumeWithRelevance]

    enum CodingKeys: String, CodingKey {
        case sourcePerfumeId  = "source_perfume_id"
        case similarPerfumes  = "similar_perfumes"
    }
}

// MARK: - AllFiltersResponse

/// Статические фильтры: пол, семейство, тип (без брендов и нот — они через /brands/suggest, /notes/suggest).
struct AllFiltersResponse: Decodable {
    let genders: [String]
    let families: [String]
    let productTypes: [String]

    enum CodingKeys: String, CodingKey {
        case genders, families
        case productTypes = "product_types"
    }
}

// MARK: - AnyCodable

/// Обёртка для произвольных JSON-значений (используется в `filtersApplied`).
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self)   { value = v; return }
        if let v = try? container.decode(Int.self)    { value = v; return }
        if let v = try? container.decode(Double.self) { value = v; return }
        if let v = try? container.decode(String.self) { value = v; return }
        if let v = try? container.decode([String].self) { value = v; return }
        value = NSNull()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as Bool:     try container.encode(v)
        case let v as Int:      try container.encode(v)
        case let v as Double:   try container.encode(v)
        case let v as String:   try container.encode(v)
        default:                try container.encodeNil()
        }
    }
}
