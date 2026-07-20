import Foundation

struct ProviderLink {
    let appURL: URL?
    let webURL: URL
}

enum ProviderLinkBuilder {
    private static let appSchemes: [Int: String] = [
        119: "aiv://",
        9: "aiv://",
        283: "crunchyroll://",
        337: "disneyplus://",
        1899: "hbomax://",
        384: "hbomax://",
        531: "paramountplus://",
        307: "globoplay://",
    ]

    private static let searchTemplates: [Int: String] = [
        8: "https://www.netflix.com/search?q={q}",
        119: "https://www.primevideo.com/search?phrase={q}",
        9: "https://www.primevideo.com/search?phrase={q}",
        350: "https://tv.apple.com/search?term={q}",
        2: "https://tv.apple.com/search?term={q}",
        337: "https://www.disneyplus.com/search?q={q}",
        1899: "https://play.max.com/search/result?q={q}",
        384: "https://play.max.com/search/result?q={q}",
        531: "https://www.paramountplus.com/search/?query={q}",
        307: "https://globoplay.globo.com/busca/?q={q}",
        283: "https://www.crunchyroll.com/search?q={q}",
        11: "https://mubi.com/search/films?query={q}",
        300: "https://pluto.tv/en/search/details?query={q}",
    ]

    static func link(for provider: StreamingProvider,
                     title: String,
                     justWatchLink: String?) -> ProviderLink? {
        guard let webURL = webURL(for: provider, title: title, justWatchLink: justWatchLink) else {
            return nil
        }
        let appURL = appSchemes[provider.providerId].flatMap(URL.init(string:))
        return ProviderLink(appURL: appURL, webURL: webURL)
    }

    private static func webURL(for provider: StreamingProvider,
                               title: String,
                               justWatchLink: String?) -> URL? {
        guard let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }

        if let template = searchTemplates[provider.providerId] {
            return URL(string: template.replacingOccurrences(of: "{q}", with: encodedTitle))
        }

        if let justWatchLink, let url = URL(string: justWatchLink) {
            return url
        }

        let query = "\(title) \(provider.providerName)"
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "https://www.google.com/search?q=\(encodedQuery)")
    }
}
