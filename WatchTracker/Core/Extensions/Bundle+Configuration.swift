import Foundation

/// Reads the build-time configuration injected through
/// `Config/*.xcconfig` → `Config/Info.plist`.
///
/// Unlike `Bundle+AppInfo`, which tolerates missing keys, a missing configuration
/// value is a broken build rather than a runtime condition — so it traps loudly
/// at launch instead of silently producing an empty string.
extension Bundle {
    func configurationValue(for key: String) -> String {
        guard let value = object(forInfoDictionaryKey: key) as? String, !value.isEmpty else {
            fatalError("Missing configuration key '\(key)'. Check Config/Base.xcconfig.")
        }
        return value
    }

    func configurationURL(for key: String) -> URL {
        let raw = configurationValue(for: key)
        guard let url = URL(string: raw) else {
            fatalError("Configuration key '\(key)' is not a valid URL: \(raw)")
        }
        return url
    }
}
