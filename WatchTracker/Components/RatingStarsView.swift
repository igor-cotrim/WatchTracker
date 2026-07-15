import SwiftUI

struct RatingStarsView: View {
    let value: Double

    var starCount: Int = 5
    var size: CGFloat = 28
    var spacing: CGFloat = 4
    var filledColor: Color = .ratingStarFilled
    var emptyColor: Color = .ratingStarEmpty

    var onRate: ((Int) -> Void)?

    @State private var previewValue: Double?
    @State private var activeStar: Int?
    @State private var bounceTrigger = 0

    private var displayValue: Double { previewValue ?? value }

    private var isInteractive: Bool { onRate != nil }

    private var totalWidth: CGFloat {
        CGFloat(starCount) * size + CGFloat(starCount - 1) * spacing
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...starCount, id: \.self) { index in
                Image(systemName: symbol(for: index))
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundStyle(displayValue >= Double(index) - 0.5 ? filledColor : emptyColor)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: bounceTrigger)
                    .scaleEffect(activeStar == index ? 1.35 : 1)
                    .animation(.spring(response: 0.28, dampingFraction: 0.55), value: displayValue)
                    .animation(.spring(response: 0.28, dampingFraction: 0.55), value: activeStar)
            }
        }
        .contentShape(.rect)
        .modifier(InteractiveStars(enabled: isInteractive) { x in
            let starValue = valueForLocation(x)
            previewValue = starValue
            activeStar = min(Int(starValue.rounded(.up)), starCount)
        } commit: {
            if let previewValue { onRate?(Int(previewValue * 2)) }
            previewValue = nil
            activeStar = nil
            bounceTrigger += 1
        })
    }

    private func symbol(for index: Int) -> String {
        let v = displayValue
        if v >= Double(index) { return "star.fill" }
        if v >= Double(index) - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }

    private func valueForLocation(_ x: CGFloat) -> Double {
        let cellWidth = size + spacing
        let clampedX = min(max(x, 0), totalWidth)
        let starIndex = Int(clampedX / cellWidth) // 0-based
        let fractionInStar = (clampedX / cellWidth) - Double(starIndex)
        let half = fractionInStar < 0.5 ? 0.5 : 1.0
        let raw = Double(starIndex) + half
        return min(max(raw, 0.5), Double(starCount))
    }
}

private struct InteractiveStars: ViewModifier {
    let enabled: Bool
    let onMove: (CGFloat) -> Void
    let commit: () -> Void

    func body(content: Content) -> some View {
        if enabled {
            content.gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { onMove($0.location.x) }
                    .onEnded { _ in commit() }
            )
        } else {
            content
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        RatingStarsView(value: 3.5)
        RatingStarsView(value: 4, size: 40, onRate: { print("rated \($0)") })
        RatingStarsView(value: 0)
    }
    .padding()
}
