import SwiftUI

struct SectionHeaderView<Destination: View>: View {
    let title: String
    var seeAllTitle: String? = nil
    var seeAllDestination: (() -> Destination)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(verbatim: title)
                .font(.title3.bold())
            Spacer()
            if let seeAllDestination, let seeAllTitle {
                NavigationLink(destination: seeAllDestination()) {
                    Text(verbatim: seeAllTitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.brandPrimary)
                }
            }
        }
        .padding(.horizontal)
    }
}

extension SectionHeaderView where Destination == EmptyView {
    init(title: String) {
        self.title = title
        self.seeAllTitle = nil
        self.seeAllDestination = nil
    }
}
