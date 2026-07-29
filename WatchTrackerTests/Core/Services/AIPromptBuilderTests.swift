import Foundation
import Testing
@testable import WatchTracker

@Suite("AIPromptBuilder", .tags(.pure))
struct AIPromptBuilderTests {

    private static let english = AIPromptBuilder(locale: Locale(identifier: "en_US"))
    private static let portuguese = AIPromptBuilder(locale: Locale(identifier: "pt_BR"))

    // MARK: - detectMediaPreference

    @Test(arguments: [
        (input: "quero um anime novo", expected: AIPromptBuilder.MediaPreference.anime),
        (input: "some animation please", expected: .anime),
        (input: "uma boa animação", expected: .anime),
        (input: "uma série longa", expected: .tvOnly),
        (input: "a good tv show", expected: .tvOnly),
        (input: "quero um dorama", expected: .tvOnly),
        (input: "um filme de terror", expected: .movieOnly),
        (input: "a great movie", expected: .movieOnly),
        (input: "something with cinema flair", expected: .movieOnly),
        (input: "algo bom para hoje", expected: .balanced),
        (input: "", expected: .balanced)
    ])
    func `detectMediaPreference maps keywords`(input: String, expected: AIPromptBuilder.MediaPreference) {
        #expect(Self.english.detectMediaPreference(from: input) == expected)
    }

    /// Precedence is anime > tv > movie, and "drama" sits in the TV keyword list —
    /// so a request for a drama *film* is classified as TV.
    @Test func `tv keywords win over movie keywords`() {
        #expect(Self.english.detectMediaPreference(from: "a drama movie") == .tvOnly)
    }

    @Test func `anime keywords win over everything`() {
        #expect(Self.english.detectMediaPreference(from: "an anime movie series") == .anime)
    }

    @Test func `detectMediaPreference is case insensitive`() {
        #expect(Self.english.detectMediaPreference(from: "A GREAT MOVIE") == .movieOnly)
    }

    /// "animation" maps to `.anime`, which the prompt then pins to `mediaType == "tv"` —
    /// so asking for an animated *feature film* still gets constrained to TV shows.
    @Test func `an animation film request is constrained to TV`() {
        let prompt = Self.english.buildPrompt(from: [], userInput: "an animation film")
        #expect(prompt.contains("Suggest ONLY anime TV shows"))
    }

    /// The keyword list has "animation" but not "animated", so the more natural
    /// English phrasing falls through to the movie keyword instead.
    @Test func `the word animated is not recognised as an anime request`() {
        #expect(Self.english.detectMediaPreference(from: "an animated film") == .movieOnly)
        #expect(Self.english.detectMediaPreference(from: "animated") == .balanced)
    }

    // MARK: - Watchlist blocks

    /// The avoid list is uncapped even though the taste signal is capped at 20 — the
    /// model must never suggest something the user already has.
    @Test func `every watchlist title lands in the avoid block`() {
        let watchlist = (0..<25).map {
            TestFixtures.watchItem(id: $0, tmdbId: $0, status: .completed)
        }
        let prompt = Self.english.buildPrompt(from: watchlist)

        #expect(prompt.contains("Titles already in my watchlist"))
        // Every fixture shares the title "Test Title", so count the rendered lines.
        let avoidLines = prompt.split(separator: "\n").filter { $0 == "- Test Title" }
        #expect(avoidLines.count == 25)
    }

    @Test func `the taste signal is capped at 20 completed, 12 watching and 8 planned`() {
        let watchlist =
            (0..<30).map { TestFixtures.watchItem(id: $0, tmdbId: $0, status: .completed) }
            + (100..<120).map { TestFixtures.watchItem(id: $0, tmdbId: $0, status: .watching) }
            + (200..<220).map { TestFixtures.watchItem(id: $0, tmdbId: $0, status: .planToWatch) }

        let prompt = Self.english.buildPrompt(from: watchlist)
        let tasteLines = prompt.split(separator: "\n").filter { $0.hasPrefix("- Test Title [") }

        #expect(tasteLines.count
            == AIPromptBuilder.completedCap + AIPromptBuilder.watchingCap + AIPromptBuilder.planToWatchCap)
    }

    @Test func `an empty watchlist omits the avoid block`() {
        #expect(!Self.english.buildPrompt(from: []).contains("Titles already in my watchlist"))
    }

    @Test func `anime entries are marked`() {
        let watchlist = [TestFixtures.watchItem(mediaType: .tv, status: .completed, isAnime: true)]
        #expect(Self.english.buildPrompt(from: watchlist).contains("[TV (Anime)]"))
    }

    @Test func `movies and shows are labelled distinctly`() {
        let prompt = Self.english.buildPrompt(from: [
            TestFixtures.watchItem(id: 1, mediaType: .movie, status: .completed),
            TestFixtures.watchItem(id: 2, mediaType: .tv, status: .completed)
        ])

        #expect(prompt.contains("[Movie]"))
        #expect(prompt.contains("[TV]"))
    }

    @Test func `each status gets its own heading`() {
        let prompt = Self.english.buildPrompt(from: [
            TestFixtures.watchItem(id: 1, status: .completed),
            TestFixtures.watchItem(id: 2, status: .watching),
            TestFixtures.watchItem(id: 3, status: .planToWatch)
        ])

        #expect(prompt.contains("Completed (strongest taste signal):"))
        #expect(prompt.contains("Currently watching:"))
        #expect(prompt.contains("Plan to watch:"))
    }

    @Test func `a status with no items has no heading`() {
        let prompt = Self.english.buildPrompt(from: [TestFixtures.watchItem(status: .completed)])

        #expect(prompt.contains("Completed (strongest taste signal):"))
        #expect(!prompt.contains("Currently watching:"))
    }

    // MARK: - The four instruction branches

    @Test func `no taste and no input asks for popular titles`() {
        let prompt = Self.english.buildPrompt(from: [], userInput: "")
        #expect(prompt.contains("I haven't added anything to my watchlist yet"))
    }

    @Test func `taste and no input asks for titles based on taste`() {
        let prompt = Self.english.buildPrompt(
            from: [TestFixtures.watchItem(status: .completed)], userInput: ""
        )
        #expect(prompt.contains("Based on my taste above"))
    }

    @Test func `no taste with input matches the request alone`() {
        let prompt = Self.english.buildPrompt(from: [], userInput: "space opera")
        #expect(prompt.contains("Specific request: space opera"))
        #expect(prompt.contains("Suggest 6 titles that match this request"))
    }

    @Test func `taste with input prioritises the request`() {
        let prompt = Self.english.buildPrompt(
            from: [TestFixtures.watchItem(status: .completed)], userInput: "space opera"
        )
        #expect(prompt.contains("Prioritize this request while considering my taste above"))
    }

    @Test func `whitespace-only input counts as no input`() {
        let prompt = Self.english.buildPrompt(from: [], userInput: "   \n  ")
        #expect(prompt.contains("I haven't added anything to my watchlist yet"))
        #expect(!prompt.contains("Specific request"))
    }

    @Test func `input is trimmed before being embedded`() {
        #expect(Self.english.buildPrompt(from: [], userInput: "  space opera  ")
            .contains("Specific request: space opera"))
    }

    /// A watchlist made only of titles the builder does not sample still counts as
    /// "no taste", because the cap-based selection is what drives the branch.
    @Test(arguments: [
        (input: "", constraint: "Suggest a balanced mix of movies and TV shows."),
        (input: "a movie", constraint: "Suggest ONLY movies"),
        (input: "a series", constraint: "Suggest ONLY TV shows"),
        (input: "an anime", constraint: "Suggest ONLY anime TV shows")
    ])
    func `the media constraint follows the detected preference`(input: String, constraint: String) {
        #expect(Self.english.buildPrompt(from: [], userInput: input).contains(constraint))
    }

    // MARK: - Localisation

    @Test func `a Portuguese locale produces a Portuguese prompt`() {
        let prompt = Self.portuguese.buildPrompt(
            from: [TestFixtures.watchItem(status: .completed)], userInput: "um filme"
        )

        #expect(prompt.contains("Títulos já na minha lista"))
        #expect(prompt.contains("Assistidos (sinal de gosto mais forte):"))
        #expect(prompt.contains("Pedido específico: um filme"))
        #expect(prompt.contains("Sugira APENAS filmes"))
    }

    @Test func `a Portuguese locale labels movies in Portuguese`() {
        let prompt = Self.portuguese.buildPrompt(
            from: [TestFixtures.watchItem(mediaType: .movie, status: .completed)]
        )
        #expect(prompt.contains("[Filme]"))
    }

    @Test func `the instructions carry the language directive`() {
        #expect(Self.portuguese.instructions.contains("Brazilian Portuguese"))
        #expect(Self.english.instructions.contains("Respond in English."))
    }

    @Test(arguments: [
        (identifier: "pt_BR", isPortuguese: true),
        (identifier: "pt_PT", isPortuguese: true),
        (identifier: "en_US", isPortuguese: false),
        (identifier: "es_ES", isPortuguese: false)
    ])
    func `isPortuguese follows the injected locale`(identifier: String, isPortuguese: Bool) {
        #expect(AIPromptBuilder(locale: Locale(identifier: identifier)).isPortuguese == isPortuguese)
    }
}
