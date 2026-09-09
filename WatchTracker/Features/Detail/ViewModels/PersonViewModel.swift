import Foundation

@Observable
@MainActor
final class PersonViewModel {
    private(set) var person: PersonDetail?
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    private let service: MediaDetailServiceProtocol
    private let analytics: AnalyticsTracking

    init(
        service: MediaDetailServiceProtocol,
        analytics: AnalyticsTracking
    ) {
        self.service = service
        self.analytics = analytics
    }

    func load(id: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let detail = try await service.fetchPerson(id: id)
            person = detail
            analytics.capture(.personViewed, properties: [
                "person_id": id,
                "name": detail.name,
                "credits": detail.credits.count
            ])
        } catch {
            errorMessage = error.userFacingMessage
        }
        isLoading = false
    }
}
