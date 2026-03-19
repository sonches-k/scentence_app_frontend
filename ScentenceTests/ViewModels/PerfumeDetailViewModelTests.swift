import XCTest
@testable import Scentence

@MainActor
final class PerfumeDetailViewModelTests: XCTestCase {

    private func makePerfume(id: Int = 42) -> Perfume {
        Perfume(
            id: id, name: "Sauvage", brand: "Dior",
            year: 2015, productType: "EDP",
            family: "Aromatic", gender: "male",
            description: "Bold fragrance.",
            imageUrl: nil, sourceUrl: nil,
            notes: [], tags: [],
            createdAt: nil, updatedAt: nil
        )
    }

    func test_load_perfume_success() async {
        let mock = MockAPIService()
        mock.getPerfumeResult = .success(makePerfume())
        mock.getSimilarResult = .success(SimilarSearchResponse(
            sourcePerfumeId: 42,
            similarPerfumes: []
        ))

        let vm = PerfumeDetailViewModel(api: mock)
        await vm.load(perfumeId: 42, token: nil)

        XCTAssertNotNil(vm.perfume)
        XCTAssertEqual(vm.perfume?.id, 42)
        XCTAssertEqual(vm.perfume?.brand, "Dior")
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
        XCTAssertEqual(mock.getPerfumeCallCount, 1)
    }

    func test_load_perfume_error() async {
        let mock = MockAPIService()
        mock.getPerfumeResult = .failure(MockAPIService.MockError.testError)
        mock.getSimilarResult = .failure(MockAPIService.MockError.testError)

        let vm = PerfumeDetailViewModel(api: mock)
        await vm.load(perfumeId: 1, token: nil)

        XCTAssertNil(vm.perfume)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    func test_toggle_favorite_add() async {
        let mock = MockAPIService()
        mock.getPerfumeResult = .success(makePerfume())
        mock.getSimilarResult = .success(SimilarSearchResponse(sourcePerfumeId: 42, similarPerfumes: []))
        mock.getFavoritesResult = .success([])
        mock.addFavoriteResult = .success(MessageResponse(message: "Added"))

        let vm = PerfumeDetailViewModel(api: mock)
        await vm.load(perfumeId: 42, token: "token")

        XCTAssertFalse(vm.isFavorite)

        await vm.toggleFavorite(perfumeId: 42, token: "token")

        XCTAssertTrue(vm.isFavorite)
        XCTAssertEqual(mock.addFavoriteCallCount, 1)
    }

    func test_toggle_favorite_remove() async {
        let mock = MockAPIService()
        mock.getPerfumeResult = .success(makePerfume())
        mock.getSimilarResult = .success(SimilarSearchResponse(sourcePerfumeId: 42, similarPerfumes: []))
        mock.getFavoritesResult = .success([
            FavoritePerfume(
                id: 42, name: "Sauvage", brand: "Dior",
                imageUrl: nil, sourceUrl: nil,
                family: "Aromatic", gender: "male",
                topNotes: [], middleNotes: [], baseNotes: []
            )
        ])
        mock.removeFavoriteResult = .success(MessageResponse(message: "Removed"))

        let vm = PerfumeDetailViewModel(api: mock)
        await vm.load(perfumeId: 42, token: "token")

        XCTAssertTrue(vm.isFavorite)

        await vm.toggleFavorite(perfumeId: 42, token: "token")

        XCTAssertFalse(vm.isFavorite)
        XCTAssertEqual(mock.removeFavoriteCallCount, 1)
    }
}
