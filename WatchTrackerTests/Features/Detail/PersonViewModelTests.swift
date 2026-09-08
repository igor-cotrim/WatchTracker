import Foundation
import Testing
@testable import WatchTracker

@MainActor
@Suite("Person page", .tags(.viewModel), .timeLimit(.minutes(1)))
struct PersonViewModelTests {

    @Test func `load fetches the person and clears the loading flag`() async {
        let service = MockMediaDetailService()
        service.fetchPersonResult = .success(TestFixtures.person(id: 25072, name: "Oscar Isaac"))
        let vm = PersonViewModel(service: service, analytics: MockAnalytics())

        await vm.load(id: 25072)

        #expect(service.fetchPersonCalls == [25072])
        #expect(vm.person?.name == "Oscar Isaac")
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }

    @Test func `load surfaces the error and leaves no person`() async {
        let service = MockMediaDetailService()
        service.fetchPersonResult = .failure(MockError.generic("offline"))
        let vm = PersonViewModel(service: service, analytics: MockAnalytics())

        await vm.load(id: 1)

        #expect(vm.person == nil)
        #expect(vm.errorMessage != nil)
        #expect(vm.isLoading == false)
    }

    @Test func `load reports the person to analytics`() async {
        let service = MockMediaDetailService()
        service.fetchPersonResult = .success(TestFixtures.person(
            id: 25072,
            name: "Oscar Isaac",
            credits: [(id: 438631, mediaType: .movie, title: "Dune", character: "Leto")]
        ))
        let analytics = MockAnalytics()
        let vm = PersonViewModel(service: service, analytics: analytics)

        await vm.load(id: 25072)

        #expect(analytics.capturedEvents.contains(.personViewed))
        #expect(analytics.properties(for: .personViewed)?["credits"] as? Int == 1)
    }
}

@Suite("PersonDetail decoding", .tags(.model, .pure))
struct PersonDetailTests {

    /// `PersonCredit` declares explicit `CodingKeys` on top of the client's
    /// `convertFromSnakeCase` strategy, which is the easiest place to get a wire name wrong.
    @Test func `credit decodes its wire names`() throws {
        let person = TestFixtures.person(credits: [
            (id: 438631, mediaType: .movie, title: "Dune", character: "Duke Leto Atreides")
        ])
        let credit = try #require(person.credits.first)

        #expect(credit.tmdbId == 438631)
        #expect(credit.id == "credit-0")
        #expect(credit.mediaType == .movie)
        #expect(credit.displayTitle == "Dune")
        #expect(credit.character == "Duke Leto Atreides")
        #expect(credit.releaseYear == "2021")
    }

    @Test func `a series credit reads its title from name`() throws {
        let person = TestFixtures.person(credits: [
            (id: 60059, mediaType: .tv, title: "Better Call Saul", character: nil)
        ])
        let credit = try #require(person.credits.first)

        #expect(credit.mediaType == .tv)
        #expect(credit.displayTitle == "Better Call Saul")
        #expect(credit.character == nil)
        #expect(credit.releaseYear == "2021")
    }

    /// TMDB answers a locale it has no translation for with an empty string, not a
    /// missing key, so the view would otherwise render an empty "Biography" section.
    @Test(arguments: [nil, "", "   "])
    func `an absent or blank biography is treated as missing`(biography: String?) {
        #expect(TestFixtures.person(biography: biography).displayBiography == nil)
    }

    @Test func `a real biography survives`() {
        #expect(TestFixtures.person(biography: "An actor.").displayBiography == "An actor.")
    }

    @Test func `profileURL uses the h632 TMDB profile size`() throws {
        let person = TestFixtures.person(profilePath: "/face.jpg")
        #expect(person.profileURL?.absoluteString == "https://image.tmdb.org/t/p/h632/face.jpg")
    }

    @Test func `profileURL is nil without a profile path`() {
        #expect(TestFixtures.person(profilePath: nil).profileURL == nil)
    }
}
