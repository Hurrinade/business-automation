import SwiftUI

struct MonthRow: View {
    let month: MonthPacket

    private var requiredReadyCount: Int {
        let requiredCategories: [DocumentCategory] = [.invoice1, .invoice2, .bankReport]
        return requiredCategories.filter { !month.documents(for: $0).isEmpty }.count
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

                Text("\(requiredReadyCount)/3")
                    .font(.caption.monospacedDigit().weight(.medium))
                    .foregroundStyle(.secondary)
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
