import Foundation
import UIKit

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

extension UIDevice {
    static var hardwareIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)

        return withUnsafeBytes(of: &systemInfo.machine) { rawBuffer in
            let bytes = rawBuffer.prefix { $0 != 0 }
            return String(decoding: bytes, as: UTF8.self)
        }
    }
}
