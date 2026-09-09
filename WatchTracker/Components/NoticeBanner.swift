import SwiftUI

/// A one-line strip above a screen's content: connectivity is gone, or what is below is the
/// last thing we managed to fetch.
///
/// Deliberately not a `ContentUnavailableView` or an `ErrorStateView` — it never takes the
/// screen. Everything under it stays readable and usable, which is the entire point of
/// keeping cached content around.
struct NoticeBanner: View {
    let message: String
    var systemImage: String = "wifi.slash"
    var tint: Color = .orange

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption)
            Text(verbatim: message)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 0) {
        NoticeBanner(message: "You're offline. Changes will sync when you're back.")
        NoticeBanner(
            message: "Couldn't refresh. Showing saved data.",
            systemImage: "clock.arrow.circlepath",
            tint: .secondary
        )
        Spacer()
    }
}
