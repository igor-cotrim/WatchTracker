import Foundation

@Observable
final class MediaDetailViewModel {
    var media: MediaDetail?
    var isLoading = false
    var userRating: Int?
    var errorMessage: String?

    private var mediaType: String = ""
    private var mediaId: Int = 0
    private let api = APIClient.shared

    func fetchDetails(type: String, id: Int) async {
        self.mediaType = type
        self.mediaId = id
        isLoading = true
        errorMessage = nil
        do {
            media = try await api.get(.mediaDetail(type: type, id: id))
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func rateMedia(rating: Int) async {
        do {
            try await api.post(.rateMedia(type: mediaType, id: mediaId, rating: rating))
            userRating = rating
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markEpisodeWatched(season: Int, episode: Int) async {
        guard mediaType == "tv" else { return }
        do {
            try await api.post(.watchEpisode(tvId: mediaId, season: season, episode: episode))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
