import Foundation

extension Bundle {
    var appName: String {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? ""
    }

    var appVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    var appBuild: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    }

    var appVersionWithBuild: String {
        "\(appVersion) (\(appBuild))"
    }

    var currentLanguageName: String {
        let code = preferredLocalizations.first ?? developmentLocalization ?? "en"
        let locale = Locale(identifier: code)
        let name = locale.localizedString(forIdentifier: code) ?? code
        return name.prefix(1).uppercased() + name.dropFirst()
    }
}
