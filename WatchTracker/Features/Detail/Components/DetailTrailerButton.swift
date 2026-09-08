import SwiftUI

/// Opens the title's trailer on YouTube. The backend already picked the single best
/// video, so this only has to decide between the app and the browser.
struct DetailTrailerButton: View {
    let trailer: MediaTrailer
    let title: String

    var body: some View {
        Button {
            open()
        } label: {
            Label(Strings.Detail.watchTrailer, systemImage: "play.rectangle.fill")
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(.systemGray5))
                .foregroundStyle(.primary)
                .clipShape(.rect(cornerRadius: 10))
        }
        .buttonStyle(PressedButtonStyle())
        .accessibilityLabel(Strings.Detail.watchTrailerAccessibility)
        .accessibilityHint(Strings.Detail.watchTrailerHint)
    }

    /// Tries the YouTube app first. `open(_:completionHandler:)` reports whether the
    /// scheme was actually handled, which is what makes the web fallback work without
    /// declaring `youtube` in `LSApplicationQueriesSchemes`.
    private func open() {
        guard let webURL = trailer.webURL else { return }

        guard let appURL = trailer.appURL else {
            track(openedVia: "web")
            UIApplication.shared.open(webURL)
            return
        }

        UIApplication.shared.open(appURL) { opened in
            track(openedVia: opened ? "app_deeplink" : "web_fallback")
            if !opened {
                UIApplication.shared.open(webURL)
            }
        }
    }

    private func track(openedVia: String) {
        AnalyticsService.shared.capture(.trailerOpened, properties: [
            "title": title,
            "trailer_key": trailer.key,
            "site": trailer.site,
            "opened_via": openedVia
        ])
    }
}
