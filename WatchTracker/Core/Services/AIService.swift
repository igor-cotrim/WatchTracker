import Foundation
import FoundationModels

enum AIModelAvailability: Equatable {
    case available
    case notEligible
    case notEnabled
    case notReady
}

@available(iOS 26, *)
final class AIService {
    private let discoverService: DiscoverService

    init(discoverService: DiscoverService = DiscoverService()) {
        self.discoverService = discoverService
    }

    func checkAvailability() -> AIModelAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return .notEligible
            case .appleIntelligenceNotEnabled:
                return .notEnabled
            case .modelNotReady:
                return .notReady
            default:
                return .notEligible
            }
        }
    }

    private var isPortugueseDevice: Bool {
        Locale.current.language.languageCode?.identifier == "pt"
    }

    func generateSuggestions(from watchlist: [WatchItem], userInput: String = "") async throws -> [AISuggestionItem] {
        let languageInstruction = isPortugueseDevice
            ? "Respond ONLY in Brazilian Portuguese (pt-BR). Write all reasons and text in Portuguese."
            : "Respond in English."

        let session = LanguageModelSession(
            model: .default,
            instructions: """
            You are an expert movie and TV show recommendation assistant with deep knowledge of cinema and television.
            Your goal is to suggest titles the user will genuinely love based on their taste.

            \(languageInstruction)

            Rules:
            - NEVER suggest a title that appears in the user's watchlist.
            - Suggest titles from a diverse range of genres and styles that match the user's taste.
            - Mix popular titles with hidden gems the user might not know.
            - Prioritize titles with high critical acclaim or strong audience reception.
            - For each suggestion, write a specific 1-2 sentence reason that mentions concrete elements shared with titles the user has watched (e.g. same director, similar themes, tone, or genre).
            - Suggest a balanced mix of movies and TV shows.
            - If the user provides a specific request or mood, prioritize that above everything else.
            """
        )

        let prompt = buildPrompt(from: watchlist, userInput: userInput)
        let response = try await session.respond(to: prompt, generating: AISuggestionsResponse.self)
        return response.content.suggestions
    }

    func resolveToMedia(_ suggestion: AISuggestionItem) async throws -> MediaDetail? {
        let type: MediaType = suggestion.mediaType == "movie" ? .movie : .tv
        let results = try await discoverService.search(query: suggestion.title, type: type, year: nil)
        return results.first
    }

    // MARK: - Private

    private enum MediaPreference {
        case anime
        case tvOnly
        case movieOnly
        case balanced
    }

    private func detectMediaPreference(from input: String) -> MediaPreference {
        let lower = input.lowercased()
        let animeKeywords    = ["anime", "animê", "animation", "animação"]
        let tvKeywords       = ["série", "serie", "series", "tv", "show", "temporada", "season", "dorama", "drama"]
        let movieKeywords    = ["filme", "film", "movie", "cinema", "longa"]

        if animeKeywords.contains(where: { lower.contains($0) }) { return .anime }
        if tvKeywords.contains(where:    { lower.contains($0) }) { return .tvOnly }
        if movieKeywords.contains(where: { lower.contains($0) }) { return .movieOnly }
        return .balanced
    }

    private func buildPrompt(from watchlist: [WatchItem], userInput: String = "") -> String {
        let completed  = watchlist.filter { $0.status == .completed }
        let watching   = watchlist.filter { $0.status == .watching }
        let planToWatch = watchlist.filter { $0.status == .planToWatch }

        var selected: [WatchItem] = []
        selected.append(contentsOf: completed.prefix(20))
        selected.append(contentsOf: watching.prefix(12))
        selected.append(contentsOf: planToWatch.prefix(8))

        let trimmedInput = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let preference   = trimmedInput.isEmpty ? .balanced : detectMediaPreference(from: trimmedInput)

        var lines: [String] = []

        let pt = isPortugueseDevice

        // Block: titles to avoid
        let allTitles = watchlist.compactMap(\.title)
        if !allTitles.isEmpty {
            lines.append(pt ? "Títulos já na minha lista (NÃO sugira nenhum destes):" : "Titles already in my watchlist (DO NOT suggest any of these):")
            for title in allTitles { lines.append("- \(title)") }
            lines.append("")
        }

        // Block: taste signal
        let groups: [(String, [WatchItem])] = [
            (pt ? "Assistidos (sinal de gosto mais forte):" : "Completed (strongest taste signal):", selected.filter { $0.status == .completed }),
            (pt ? "Assistindo atualmente:"                  : "Currently watching:",                 selected.filter { $0.status == .watching }),
            (pt ? "Quero assistir:"                         : "Plan to watch:",                      selected.filter { $0.status == .planToWatch })
        ]

        for (label, items) in groups where !items.isEmpty {
            lines.append(label)
            for item in items {
                let title = item.title ?? (pt ? "Desconhecido" : "Unknown")
                let type  = item.mediaType == .movie ? (pt ? "Filme" : "Movie") : "TV"
                let anime = item.isAnime == true ? " (Anime)" : ""
                lines.append("- \(title) [\(type)\(anime)]")
            }
            lines.append("")
        }

        // Block: instruction with media constraint
        let mediaConstraint: String
        switch preference {
        case .anime:
            mediaConstraint = pt
                ? "Sugira APENAS animes (mediaType deve ser \"tv\")."
                : "Suggest ONLY anime TV shows (mediaType must be \"tv\")."
        case .tvOnly:
            mediaConstraint = pt
                ? "Sugira APENAS séries de TV (mediaType deve ser \"tv\")."
                : "Suggest ONLY TV shows (mediaType must be \"tv\")."
        case .movieOnly:
            mediaConstraint = pt
                ? "Sugira APENAS filmes (mediaType deve ser \"movie\")."
                : "Suggest ONLY movies (mediaType must be \"movie\")."
        case .balanced:
            mediaConstraint = pt
                ? "Sugira uma mistura equilibrada de filmes e séries."
                : "Suggest a balanced mix of movies and TV shows."
        }

        let hasTaste = !selected.isEmpty

        if trimmedInput.isEmpty {
            if hasTaste {
                lines.append(pt
                    ? "Com base no meu gosto acima, sugira 6 títulos que eu adoraria. \(mediaConstraint) Não sugira nada da minha lista."
                    : "Based on my taste above, suggest 6 titles I would love. \(mediaConstraint) Do not suggest anything from my watchlist."
                )
            } else {
                lines.append(pt
                    ? "Ainda não adicionei nada à minha lista. Sugira 6 títulos populares e aclamados pela crítica e pelo público, cobrindo gêneros diversos, que a maioria das pessoas adora. \(mediaConstraint)"
                    : "I haven't added anything to my watchlist yet. Suggest 6 popular, critically and audience-acclaimed titles across a diverse range of genres that most people love. \(mediaConstraint)"
                )
            }
        } else {
            lines.append(pt ? "Pedido específico: \(trimmedInput)" : "Specific request: \(trimmedInput)")
            if hasTaste {
                lines.append(pt
                    ? "Priorize este pedido considerando meu gosto acima. Sugira 6 títulos. \(mediaConstraint) Não sugira nada da minha lista."
                    : "Prioritize this request while considering my taste above. Suggest 6 titles. \(mediaConstraint) Do not suggest anything from my watchlist."
                )
            } else {
                lines.append(pt
                    ? "Sugira 6 títulos que combinem com este pedido. \(mediaConstraint)"
                    : "Suggest 6 titles that match this request. \(mediaConstraint)"
                )
            }
        }

        return lines.joined(separator: "\n")
    }
}
