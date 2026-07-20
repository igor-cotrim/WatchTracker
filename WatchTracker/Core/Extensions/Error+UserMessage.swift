import Foundation

extension Error {
    var userFacingMessage: String {
        let nsError = self as NSError

        let connectionCodes: Set<Int> = [
            URLError.notConnectedToInternet.rawValue,
            URLError.cannotFindHost.rawValue,
            URLError.cannotConnectToHost.rawValue,
            URLError.networkConnectionLost.rawValue,
            URLError.dnsLookupFailed.rawValue,
            URLError.timedOut.rawValue,
            URLError.dataNotAllowed.rawValue,
            URLError.internationalRoamingOff.rawValue
        ]

        if nsError.domain == NSURLErrorDomain, connectionCodes.contains(nsError.code) {
            return Strings.Common.connectionError
        }

        return localizedDescription
    }
}
