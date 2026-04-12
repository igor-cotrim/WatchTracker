import SwiftUI

struct UpcomingSectionHeader: View {
    let sectionKey: String

    var body: some View {
        Text(label)
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.quaternary, in: Capsule())
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .padding(.vertical, 6)
    }

    private var label: String {
        switch sectionKey {
        case "today":    return Strings.Upcoming.today
        case "tomorrow": return Strings.Upcoming.tomorrow
        case "later":    return Strings.Upcoming.later
        default:         return sectionKey.uppercased()
        }
    }
}
