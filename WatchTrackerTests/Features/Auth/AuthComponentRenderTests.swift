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
        @FocusState private var focus: AuthFocusField?
        let kind: AuthFieldKind
        let field: AuthFocusField

        var body: some View {
            AuthTextField(
                placeholder: "Placeholder",
                text: .constant("value"),
                kind: kind,
                focusState: $focus,
                focusValue: field
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

    @Test(arguments: [
        (AuthFieldKind.name, AuthFocusField.name),
        (AuthFieldKind.email, AuthFocusField.email),
        (AuthFieldKind.password, AuthFocusField.password),
        (AuthFieldKind.code, AuthFocusField.code)
    ])
    func `text field renders every kind`(kind: AuthFieldKind, field: AuthFocusField) {
        _ = render(FocusHost(kind: kind, field: field), height: 80)
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
