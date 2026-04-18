import SwiftUI

struct AuthBrandingHeader: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "play.tv.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white)
                .shadow(color: Color.brandPrimary.opacity(0.8), radius: 20)

            Text(verbatim: "WatchTracker")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Text(Strings.Auth.trackYourShows)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}
