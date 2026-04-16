import SwiftUI

struct AIUnavailableView: View {
    let availability: AIModelAvailability

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(title)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(Color.brandPrimary)
            }
        } description: {
            Text(subtitle)
        }
    }

    private var icon: String {
        switch availability {
        case .notEligible:
            "apple.intelligence"
        case .notEnabled:
            "gearshape"
        case .notReady:
            "arrow.down.circle"
        case .available:
            "sparkles"
        }
    }

    private var title: String {
        switch availability {
        case .notEligible:
            Strings.AI.unavailableNotEligible
        case .notEnabled:
            Strings.AI.unavailableNotEnabled
        case .notReady:
            Strings.AI.unavailableNotReady
        case .available:
            ""
        }
    }

    private var subtitle: String {
        switch availability {
        case .notEligible:
            Strings.AI.unavailableNotEligibleSubtitle
        case .notEnabled:
            Strings.AI.unavailableNotEnabledSubtitle
        case .notReady:
            Strings.AI.unavailableNotReadySubtitle
        case .available:
            ""
        }
    }
}
