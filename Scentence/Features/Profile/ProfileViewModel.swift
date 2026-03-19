import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var isEditingName: Bool = false
    @Published var newName: String = ""
    @Published var errorMessage: String?

    private let api: APIServiceProtocol

    init(api: APIServiceProtocol = APIService.shared) {
        self.api = api
    }

    func loadProfile(token: String) async -> User? {
        do {
            return try await api.getMe(token: token)
        } catch {
            return nil
        }
    }

    func updateName(token: String) async -> User? {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return nil }
        do {
            let user = try await api.updateName(name: name, token: token)
            isEditingName = false
            return user
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
