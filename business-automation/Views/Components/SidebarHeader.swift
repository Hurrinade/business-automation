import SwiftUI

struct SidebarHeader: View {
    let totalMonths: Int
    let readyMonths: Int
    let onCreateTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Packets")
                        .font(.system(.title3, design: .rounded).weight(.bold))

                    Text("Keep invoices, receipts, and reports organized.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "folder.badge.gearshape")
                    .font(.title3)
                    .foregroundStyle(AppTheme.highlight)
            }

            HStack(spacing: 8) {
                Label("\(totalMonths)", systemImage: "calendar")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())

                Label("\(readyMonths) ready", systemImage: "checkmark.seal")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.18))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            }

            Button(action: onCreateTapped) {
                Label("Create Month", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                )
        )
    }
}
