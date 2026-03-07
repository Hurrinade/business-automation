import SwiftUI

struct MonthRow: View {
    let month: MonthPacket

    private var requiredReadyCount: Int {
        month.completedRequiredCategoryCount
    }

    private var requiredCategoryCount: Int {
        month.requiredCategoryCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Circle()
                    .fill(month.status == .ready ? Color.green : AppTheme.highlight.opacity(0.8))
                    .frame(width: 8, height: 8)

                Text(month.monthLabel)
                    .font(.system(.headline, design: .rounded).weight(.semibold))

                Spacer()

                if requiredCategoryCount == 0 {
                    Text("Optional")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(requiredReadyCount)/\(requiredCategoryCount)")
                        .font(.caption.monospacedDigit().weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(month.documents.count) file\(month.documents.count == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Updated \(month.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.8))
                }

                Spacer()

                StatusBadge(status: month.status)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}
