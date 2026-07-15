import SwiftUI
import UIKit

struct ShareCardView: View {
    let posterImage: UIImage?
    let title: String
    let starValue: Double

    static let canvasSize = CGSize(width: 1080, height: 1920)

    var body: some View {
        VStack(spacing: 64) {
            Spacer(minLength: 0)

            poster
                .frame(width: 660, height: 990)
                .clipShape(.rect(cornerRadius: 32))
                .shadow(color: .black.opacity(0.5), radius: 40, y: 20)

            VStack(spacing: 28) {
                Text(verbatim: title)
                    .font(.system(size: 54, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 80)

                RatingStarsView(
                    value: starValue,
                    size: 64,
                    spacing: 14,
                    filledColor: .brandAccent,
                    emptyColor: .white.opacity(0.25)
                )
            }

            Spacer(minLength: 0)

            footer
                .padding(.bottom, 90)
        }
        .frame(width: Self.canvasSize.width, height: Self.canvasSize.height)
        .background(background)
    }

    private var poster: some View {
        Group {
            if let posterImage {
                Image(uiImage: posterImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color.brandSecondary
                    Image(systemName: "film")
                        .font(.system(size: 160))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 14) {
            HStack(spacing: 20) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)

                Text(verbatim: "Watcheed")
                    .font(.system(size: 52, weight: .heavy))
                    .foregroundStyle(.white)
            }

            Text(Strings.Share.downloadCTA)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color.brandSecondary,
                Color.black,
                Color.brandPrimary.opacity(0.35),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview {
    ShareCardView(posterImage: nil, title: "Fight Club", starValue: 4.5)
        .scaleEffect(0.3)
}
