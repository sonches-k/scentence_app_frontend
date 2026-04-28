import Foundation
import FoundationModels

// MARK: - PerfumeSearchAnalysis

@available(iOS 26, *)
@Generable
struct PerfumeSearchAnalysis {
    @Guide(description: """
        2 to 4 top/head notes selected from the actual notes of the found fragrances. \
        Choose the most characteristic and frequently appearing ones. \
        Use ONLY real, internationally recognized English perfumery ingredient names. \
        Do NOT invent notes. Do NOT translate — English only.
        """)
    var topNotes: [String]

    @Guide(description: """
        2 to 4 heart/middle notes selected from the actual notes of the found fragrances. \
        Choose the most characteristic and frequently appearing ones. \
        Use ONLY real, internationally recognized English perfumery ingredient names. \
        Do NOT invent notes. Do NOT translate — English only.
        """)
    var middleNotes: [String]

    @Guide(description: """
        2 to 4 base notes selected from the actual notes of the found fragrances. \
        Choose the most characteristic and frequently appearing ones. \
        Use ONLY real, internationally recognized English perfumery ingredient names. \
        Do NOT invent notes. Do NOT translate — English only.
        """)
    var baseNotes: [String]

    @Guide(description: """
        2 to 3 sentences in English. First sentence: which notes dominate the found fragrances and \
        how they reflect the user's query. Second sentence: what unites the selection and \
        what makes it a strong match. Be concise and direct — no preambles like 'Certainly' or 'Great choice'.
        """)
    var explanation: String
}

// MARK: - AppleIntelligenceService

@available(iOS 26, *)
final class AppleIntelligenceService {
    static let shared = AppleIntelligenceService()
    private init() {}

    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    func generate(
        query: String,
        perfumes: [PerfumeWithRelevance]
    ) async throws -> (NotePyramid, String) {
        let perfumeList = perfumes.prefix(5).enumerated().map { i, p -> String in
            var parts: [String] = []
            if !p.topNotes.isEmpty    { parts.append("top: \(p.topNotes.prefix(3).joined(separator: ", "))") }
            if !p.middleNotes.isEmpty { parts.append("heart: \(p.middleNotes.prefix(3).joined(separator: ", "))") }
            if !p.baseNotes.isEmpty   { parts.append("base: \(p.baseNotes.prefix(3).joined(separator: ", "))") }
            let family = p.family.map { " [\($0)]" } ?? ""
            let noteStr = parts.isEmpty ? "" : " — \(parts.joined(separator: " | "))"
            return "\(i + 1). \(p.brand) \(p.name)\(family)\(noteStr)"
        }.joined(separator: "\n")

        let prompt = """
        You are a perfumery consultant. Be concise and direct — no preambles like "Certainly" or "Great choice".
        Present the fragrance selection positively, highlighting strengths.

        User query: "\(query)"

        Top matching fragrances found:
        \(perfumeList)

        Task:
        - Build a note pyramid using the ACTUAL notes from the found fragrances above.
        - Select 2–4 most characteristic and representative notes per level (top/heart/base).
        - Do NOT invent notes — use only notes that appear in the fragrances listed above.
        - Use ONLY real, internationally recognized perfumery ingredient names in English.
        - Write a short explanation (2–3 sentences) about how these notes reflect the query and what unites the selection.
        - Respond in English only.
        """

        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt, generating: PerfumeSearchAnalysis.self)
        let result = response.content

        let pyramid = NotePyramid(
            top: result.topNotes,
            middle: result.middleNotes,
            base: result.baseNotes
        )
        return (pyramid, result.explanation)
    }
}
