import FoundationModels

@Generable
struct AISuggestionsResponse {
    @Guide(description: "A list of 5 to 8 movie or TV show suggestions based on the user's watchlist")
    var suggestions: [AISuggestionItem]
}

@Generable
struct AISuggestionItem {
    @Guide(description: "The exact title of the movie or TV show")
    var title: String

    @Guide(description: "Whether this is a movie or tv show", .anyOf(["movie", "tv"]))
    var mediaType: String

    @Guide(description: "A brief 1-2 sentence reason why this is recommended based on patterns in the user's watchlist")
    var reason: String
}
