import SwiftUI

struct AuthBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.07, blue: 0.12),
                    Color(red: 0.12, green: 0.08, blue: 0.10),
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.brandPrimary.opacity(0.35), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 180
            )
            .frame(width: 360, height: 360)
            .offset(y: -200)
            .blur(radius: 20)
            .allowsHitTesting(false)
        }
    }
}
