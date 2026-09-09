import SwiftUI
import Testing
@testable import WatchTracker

/// Renders `Features/Auth/Components/`. These had *incidental* coverage only — the test
/// host launches the real app, so the auth screen rendered on its way up without any
/// test asserting on it. Now they are exercised deliberately, including the states the
/// app's own launch never reaches.
@MainActor
@Suite("Auth components render", .tags(.view, .pure))
struct AuthComponentRenderTests {

    /// `AuthTextField` needs a `FocusState.Binding`, which only a real view can provide.
    private struct FocusHost: View {
        @FocusState private var focus: AuthField?
        let field: AuthField

        var body: some View {
            AuthTextField(
                placeholder: "Placeholder",
                text: .constant("value"),
                field: field,
                focusState: $focus
            )
        }
    }

    @Test func `branding header renders`() {
        _ = render(AuthBrandingHeader(), height: 200)
    }

    @Test(arguments: [true, false])
    func `mode header renders both modes`(isSignUp: Bool) {
        _ = render(AuthModeHeader(isSignUp: isSignUp), height: 140)
    }

    @Test(arguments: [
        (false, false), (true, false), (false, true)
    ])
    func `primary button renders each state`(isLoading: Bool, isDisabled: Bool) {
        rasterize(
            AuthPrimaryButton(title: "Sign in", isLoading: isLoading, isDisabled: isDisabled, action: {}),
            height: 80
        )
    }

    @Test(arguments: AuthField.allCases)
    func `text field renders every kind`(field: AuthField) {
        _ = render(FocusHost(field: field), height: 80)
    }

    @Test(arguments: [
        (false, false, false),
        (true, false, false),
        (true, true, false),
        (true, true, true)
    ])
    func `password requirements render every combination`(
        minLength: Bool, uppercase: Bool, number: Bool
    ) {
        _ = render(
            PasswordRequirementsView(
                hasMinLength: minLength,
                hasUppercase: uppercase,
                hasNumber: number
            ),
            height: 120
        )
    }
}
