import UIKit

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
