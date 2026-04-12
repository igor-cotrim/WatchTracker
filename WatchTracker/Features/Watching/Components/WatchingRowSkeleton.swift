import SwiftUI

struct WatchingRowSkeleton: View {
    var body: some View {
        HStack(spacing: 14) {
            SkeletonView()
                .frame(width: 120, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                SkeletonView()
                    .frame(width: 80, height: 10)
                    .clipShape(Capsule())
                SkeletonView()
                    .frame(width: 120, height: 14)
                    .clipShape(Capsule())
                SkeletonView()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 10)
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Circle()
                .fill(Color(.tertiarySystemFill))
                .frame(width: 28, height: 28)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }
}
