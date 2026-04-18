import SwiftUI

struct MoodStripView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: Strings.Discover.moodsTitle)
                .font(.title3.bold())
                .padding(.horizontal)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(MoodPreset.all) { mood in
                        NavigationLink {
                            MoodBrowseView(mood: mood)
                        } label: {
                            Text(verbatim: mood.title)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule().fill(Color.brandAccent.opacity(0.18))
                                )
                                .foregroundStyle(Color.brandAccent)
                        }
                        .buttonStyle(PressedButtonStyle())
                        .accessibilityLabel(Strings.Discover.browseAccessibility(mood.title))
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
    }
}
