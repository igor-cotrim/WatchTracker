import SwiftUI
import UIKit

@MainActor
enum ShareCardRenderer {
    static func render(title: String, posterPath: String?, starValue: Double) async -> UIImage? {
        let poster = await loadPoster(posterPath)
        let card = ShareCardView(posterImage: poster, title: title, starValue: starValue)

        let renderer = ImageRenderer(content: card)
        renderer.scale = 1
        renderer.isOpaque = true
        return renderer.uiImage
    }

    private static func loadPoster(_ path: String?) async -> UIImage? {
        guard let path, let url = URL(string: "https://image.tmdb.org/t/p/w780\(path)") else {
            return nil
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}

struct ShareableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
