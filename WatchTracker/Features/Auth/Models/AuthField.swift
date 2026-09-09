import Foundation

/// One field on the auth screens.
///
/// This is both *what the field is* — which keyboard, content type and submit label it
/// gets — and *what the focus state points at*. Those used to be two enums with identical
/// cases (`AuthFieldKind` and `AuthFocusField`), and every call site passed the same value
/// to both, which meant nothing stopped them from disagreeing.
enum AuthField: CaseIterable {
    case name
    case email
    case password
    case code
}
