import SwiftUI

struct SearchFilterBar: View {
    @Binding var selectedType: String?
    @Binding var selectedYear: Int?

    private let types: [(label: String, value: String?)] = [
        ("All", nil),
        ("Movies", "movie"),
        ("TV Shows", "tv")
    ]

    private var years: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 30)...current).reversed()
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(types, id: \.label) { type in
                    typeChip(label: type.label, value: type.value)
                }

                Divider()
                    .frame(height: 20)

                yearMenu
            }
            .padding(.horizontal)
        }
    }

    private func typeChip(label: String, value: String?) -> some View {
        let isSelected = selectedType == value
        return Button {
            selectedType = value
        } label: {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.brandPrimary : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var yearMenu: some View {
        let isSelected = selectedYear != nil
        let label = selectedYear.map { String($0) } ?? "Year"
        return Menu {
            Button("Any Year") { selectedYear = nil }
            Divider()
            ForEach(years, id: \.self) { year in
                Button(String(year)) { selectedYear = year }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                Text(label)
            }
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.brandPrimary : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}
