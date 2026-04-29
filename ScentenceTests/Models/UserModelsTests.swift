import XCTest
@testable import Scentence

final class UserModelsTests: XCTestCase {

    // MARK: - User.displayName

    func test_display_name_returns_name_when_set() {
        let user = User(id: 1, email: "sofia@example.com", name: "Sofia", createdAt: nil)
        XCTAssertEqual(user.displayName, "Sofia")
    }

    func test_display_name_returns_email_prefix_when_name_nil() {
        let user = User(id: 1, email: "sofia@example.com", name: nil, createdAt: nil)
        XCTAssertEqual(user.displayName, "sofia")
    }

    func test_display_name_returns_email_prefix_when_name_empty() {
        let user = User(id: 1, email: "sofia@example.com", name: "", createdAt: nil)
        XCTAssertEqual(user.displayName, "sofia")
    }

    func test_display_name_returns_full_email_when_no_at_sign() {
        let user = User(id: 1, email: "notanemail", name: nil, createdAt: nil)
        XCTAssertEqual(user.displayName, "notanemail")
    }

    // MARK: - SearchHistoryEntry.parsedFilters — JSON-путь (реальный сценарий)

    func test_parsed_filters_from_json_string_arrays() throws {
        let json = """
        {
            "id": 1,
            "query": "тест",
            "filters": {
                "genders": ["male", "unisex"],
                "families": ["Woody"],
                "product_types": ["EDP"],
                "categories": ["Люкс"],
                "brands": ["Dior", "Chanel"],
                "notes": ["Rose"],
                "year_from": 2010,
                "year_to": 2023
            }
        }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(SearchHistoryEntry.self, from: json)
        let filters = entry.parsedFilters

        XCTAssertNotNil(filters)
        XCTAssertEqual(filters?.genders, ["male", "unisex"])
        XCTAssertEqual(filters?.families, ["Woody"])
        XCTAssertEqual(filters?.productTypes, ["EDP"])
        XCTAssertEqual(filters?.categories, ["Люкс"])
        XCTAssertEqual(filters?.brands, ["Dior", "Chanel"])
        XCTAssertEqual(filters?.notes, ["Rose"])
        XCTAssertEqual(filters?.yearFrom, 2010)
        XCTAssertEqual(filters?.yearTo, 2023)
    }

    func test_parsed_filters_year_as_double_from_json() throws {
        // Бэкенд может отдать числа как Double в JSON (2010.0)
        let json = """
        {
            "id": 2,
            "query": "тест",
            "filters": { "year_from": 2010.0 }
        }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(SearchHistoryEntry.self, from: json)
        XCTAssertEqual(entry.parsedFilters?.yearFrom, 2010)
    }

    func test_parsed_filters_returns_nil_when_filters_null() throws {
        let json = """
        { "id": 3, "query": "тест", "filters": null }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(SearchHistoryEntry.self, from: json)
        XCTAssertNil(entry.parsedFilters)
    }

    func test_parsed_filters_returns_nil_when_all_values_empty() throws {
        let json = """
        {
            "id": 4,
            "query": "тест",
            "filters": { "genders": [] }
        }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(SearchHistoryEntry.self, from: json)
        XCTAssertNil(entry.parsedFilters)
    }

    // MARK: - SearchHistoryEntry.filterChips

    func test_filter_chips_populated() throws {
        let json = """
        {
            "id": 5,
            "query": "тест",
            "filters": {
                "genders": ["male"],
                "families": ["Woody"],
                "brands": ["Dior", "Chanel", "Guerlain"],
                "year_from": 2015,
                "year_to": 2023
            }
        }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(SearchHistoryEntry.self, from: json)
        let chips = entry.filterChips

        XCTAssertTrue(chips.contains("male"))
        XCTAssertTrue(chips.contains("Woody"))
        // Бренды ограничены двумя
        XCTAssertTrue(chips.contains("Dior"))
        XCTAssertTrue(chips.contains("Chanel"))
        XCTAssertFalse(chips.contains("Guerlain"))
        // Год в формате "от–до"
        XCTAssertTrue(chips.contains("2015–2023"))
    }

    func test_filter_chips_only_year_from() throws {
        let json = """
        { "id": 6, "query": "тест", "filters": { "year_from": 2000 } }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(SearchHistoryEntry.self, from: json)
        XCTAssertTrue(entry.filterChips.contains("от 2000"))
    }

    func test_filter_chips_empty_when_no_filters() throws {
        let json = """
        { "id": 7, "query": "тест", "filters": null }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(SearchHistoryEntry.self, from: json)
        XCTAssertTrue(entry.filterChips.isEmpty)
    }
}
