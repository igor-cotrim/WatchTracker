import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.75
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color(red: 0.039, green: 0.039, blue: 0.039)
                .ignoresSafeArea()

            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 160)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
}
