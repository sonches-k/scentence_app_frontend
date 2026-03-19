import XCTest
@testable import Scentence

final class PerfumeTests: XCTestCase {

    // MARK: - Perfume

    func test_perfume_decoding() throws {
        let json = """
        {
            "id": 42,
            "name": "Sauvage",
            "brand": "Dior",
            "year": 2015,
            "product_type": "EDP",
            "family": "Aromatic",
            "gender": "male",
            "description": "Bold and refined fragrance.",
            "image_url": "https://example.com/img.jpg",
            "source_url": "https://example.com/perfume",
            "notes": [
                {"note": {"id": 1, "name": "Bergamot", "category": "Citrus"}, "level": "top"},
                {"note": {"id": 2, "name": "Pepper", "category": "Spicy"}, "level": "middle"},
                {"note": {"id": 3, "name": "Ambroxan", "category": null}, "level": "base"}
            ],
            "tags": [
                {"tag": "fresh", "confidence": 0.95, "source": "llm"},
                {"tag": "masculine", "confidence": null, "source": null}
            ],
            "created_at": "2024-01-15T10:00:00",
            "updated_at": "2024-06-01T12:00:00"
        }
        """.data(using: .utf8)!

        let perfume = try JSONDecoder().decode(Perfume.self, from: json)

        XCTAssertEqual(perfume.id, 42)
        XCTAssertEqual(perfume.name, "Sauvage")
        XCTAssertEqual(perfume.brand, "Dior")
        XCTAssertEqual(perfume.year, 2015)
        XCTAssertEqual(perfume.productType, "EDP")
        XCTAssertEqual(perfume.family, "Aromatic")
        XCTAssertEqual(perfume.gender, "male")
        XCTAssertEqual(perfume.imageUrl, "https://example.com/img.jpg")
        XCTAssertEqual(perfume.notes.count, 3)
        XCTAssertEqual(perfume.tags.count, 2)
        XCTAssertEqual(perfume.notePyramid.top, ["Bergamot"])
        XCTAssertEqual(perfume.notePyramid.middle, ["Pepper"])
        XCTAssertEqual(perfume.notePyramid.base, ["Ambroxan"])
        XCTAssertEqual(perfume.allTagNames, ["fresh", "masculine"])
    }

    func test_perfume_decoding_missing_optional_fields() throws {
        let json = """
        {
            "id": 1,
            "name": "Minimal",
            "brand": "Test",
            "notes": [],
            "tags": []
        }
        """.data(using: .utf8)!

        let perfume = try JSONDecoder().decode(Perfume.self, from: json)

        XCTAssertEqual(perfume.id, 1)
        XCTAssertEqual(perfume.name, "Minimal")
        XCTAssertNil(perfume.year)
        XCTAssertNil(perfume.productType)
        XCTAssertNil(perfume.family)
        XCTAssertNil(perfume.gender)
        XCTAssertNil(perfume.description)
        XCTAssertNil(perfume.imageUrl)
        XCTAssertTrue(perfume.notePyramid.isEmpty)
        XCTAssertTrue(perfume.allTagNames.isEmpty)
    }

    // MARK: - PerfumeWithRelevance

    func test_perfume_with_relevance_decoding() throws {
        let json = """
        {
            "id": 10,
            "name": "Light Blue",
            "brand": "D&G",
            "image_url": null,
            "source_url": null,
            "family": "Citrus",
            "gender": "female",
            "top_notes": ["Apple", "Cedar"],
            "middle_notes": ["Jasmine"],
            "base_notes": ["Musk"],
            "relevance": 0.87
        }
        """.data(using: .utf8)!

        let perfume = try JSONDecoder().decode(PerfumeWithRelevance.self, from: json)

        XCTAssertEqual(perfume.id, 10)
        XCTAssertEqual(perfume.relevancePercent, 87)
        XCTAssertEqual(perfume.notePyramid.top, ["Apple", "Cedar"])
        XCTAssertEqual(perfume.notePyramid.base, ["Musk"])
    }

    // MARK: - FavoritePerfume

    func test_favorite_perfume_decoding() throws {
        let json = """
        {
            "id": 5,
            "name": "Coco",
            "brand": "Chanel",
            "image_url": "https://example.com/img.jpg",
            "source_url": null,
            "family": "Oriental",
            "gender": "female",
            "top_notes": ["Orange"],
            "middle_notes": [],
            "base_notes": ["Vanilla"]
        }
        """.data(using: .utf8)!

        let perfume = try JSONDecoder().decode(FavoritePerfume.self, from: json)

        XCTAssertEqual(perfume.id, 5)
        XCTAssertEqual(perfume.brand, "Chanel")
        XCTAssertEqual(perfume.family, "Oriental")
    }
}
