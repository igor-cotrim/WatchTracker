import Testing

extension Tag {
    @Tag static var model: Self
    @Tag static var viewModel: Self
    @Tag static var service: Self
    @Tag static var pure: Self      // synchronous, no network
    @Tag static var async: Self     // async tests with mocks
}
