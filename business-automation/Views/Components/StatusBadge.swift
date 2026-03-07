import SwiftUI

struct StatusBadge: View {
    let status: MonthPacketStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(status == .ready ? Color.green.opacity(0.22) : Color.orange.opacity(0.22))
            .foregroundStyle(status == .ready ? .green : .orange)
            .clipShape(Capsule())
    }
}
