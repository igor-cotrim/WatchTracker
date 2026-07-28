import SwiftUI

/// User-selected colour scheme, persisted in `@AppStorage(AppAppearance.storageKey)`.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "appAppearance"

    var id: String { rawValue }

    /// `nil` hands control back to the system setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var title: String {
        switch self {
        case .system: Strings.Profile.appearanceSystem
        case .light: Strings.Profile.appearanceLight
        case .dark: Strings.Profile.appearanceDark
        }
    }

    var icon: String {
        switch self {
        case .system: "iphone"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }
}
