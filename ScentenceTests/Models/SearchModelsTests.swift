import XCTest
@testable import Scentence

final class SearchModelsTests: XCTestCase {

    // MARK: - SearchResponse

    func test_search_response_decoding() throws {
        let json = """
        {
            "query": "тёплый аромат",
            "note_pyramid": {
                "top": ["Бергамот"],
                "middle": ["Ирис"],
                "base": ["Ваниль", "Мускус"]
            },
            "explanation": "Подобрали **тёплые** ароматы.",
            "perfumes": [
                {
                    "id": 1,
                    "name": "Test",
                    "brand": "Brand",
                    "image_url": null,
                    "source_url": null,
                    "family": "Oriental",
                    "gender": "unisex",
                    "top_notes": ["Бергамот"],
                    "middle_notes": ["Ирис"],
                    "base_notes": ["Ваниль"],
                    "relevance": 0.92
                }
            ],
            "filters_applied": null,
            "total_found": 1
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(SearchResponse.self, from: json)

        XCTAssertEqual(response.query, "тёплый аромат")
        XCTAssertEqual(response.totalFound, 1)
        XCTAssertEqual(response.perfumes.count, 1)
        XCTAssertEqual(response.notePyramid.base, ["Ваниль", "Мускус"])
        XCTAssertFalse(response.explanation.isEmpty)
    }

    // MARK: - SearchRequest encoding

    func test_search_request_encoding() throws {
        let filters = SearchFilters(
            genders: ["male"],
            families: nil,
            productTypes: nil,
            brands: nil,
            notes: nil,
            yearFrom: 2000,
            yearTo: nil
        )
        let request = SearchRequest(query: "свежий", filters: filters, limit: 10)
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["query"] as? String, "свежий")
        XCTAssertEqual(dict["limit"] as? Int, 10)

        let filtersDict = dict["filters"] as? [String: Any]
        XCTAssertNotNil(filtersDict)
        XCTAssertEqual(filtersDict?["genders"] as? [String], ["male"])
        XCTAssertEqual(filtersDict?["year_from"] as? Int, 2000)
    }

    // MARK: - SearchFilters

    func test_search_filters_empty() {
        let filters = SearchFilters(
            genders: nil, families: nil, productTypes: nil,
            brands: nil, notes: nil, yearFrom: nil, yearTo: nil
        )
        XCTAssertTrue(filters.isEmpty)
        XCTAssertEqual(filters.activeCount, 0)
    }

    func test_search_filters_active_count() {
        let filters = SearchFilters(
            genders: ["male"],
            families: ["Woody", "Oriental"],
            productTypes: nil,
            brands: nil,
            notes: nil,
            yearFrom: 2010,
            yearTo: nil
        )
        XCTAssertFalse(filters.isEmpty)
        XCTAssertEqual(filters.activeCount, 3) // genders + families + year
    }

    // MARK: - SimilarSearchResponse

    func test_similar_search_response_decoding() throws {
        let json = """
        {
            "source_perfume_id": 42,
            "similar_perfumes": []
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(SimilarSearchResponse.self, from: json)

        XCTAssertEqual(response.sourcePerfumeId, 42)
        XCTAssertTrue(response.similarPerfumes.isEmpty)
    }

    // MARK: - AllFiltersResponse

    func test_all_filters_response_decoding() throws {
        let json = """
        {
            "genders": ["male", "female", "unisex"],
            "families": ["Woody"],
            "product_types": ["EDP", "EDT"],
            "brands": ["Dior"],
            "notes": ["Bergamot", "Vanilla"]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(AllFiltersResponse.self, from: json)

        XCTAssertEqual(response.genders.count, 3)
        XCTAssertEqual(response.productTypes, ["EDP", "EDT"])
    }
}
