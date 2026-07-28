import Foundation
import UIKit

enum FeedbackComposer {
    static var recipient: String { Config.supportEmail }

    static var subject: String {
        Strings.Feedback.subject(appName: Bundle.main.appName)
    }

    static func body(accountEmail: String?) -> String {
        var lines: [String] = [
            Strings.Feedback.bodyPlaceholder,
            "",
            "",
            "—————",
            Strings.Feedback.diagnosticsTitle,
            "\(Strings.Feedback.fieldApp): \(Bundle.main.appName) \(Bundle.main.appVersionWithBuild)",
            "\(Strings.Feedback.fieldSystem): \(UIDevice.current.systemVersion)",
            "\(Strings.Feedback.fieldDevice): \(UIDevice.hardwareIdentifier)",
            "\(Strings.Feedback.fieldLanguage): \(Locale.current.identifier)",
        ]

        if let accountEmail, !accountEmail.isEmpty {
            lines.append("\(Strings.Feedback.fieldAccount): \(accountEmail)")
        }

        return lines.joined(separator: "\n")
    }

    static func mailtoURL(accountEmail: String?) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body(accountEmail: accountEmail)),
        ]
        return components.url
    }
}
