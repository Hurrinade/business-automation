import SwiftUI

struct CategoryRow: View {
    let category: DocumentCategory
    let count: Int
    let isRequired: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.symbolName)
                .foregroundStyle(AppTheme.highlight)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(category.title)
                    .font(.system(.headline, design: .rounded))
                Text(category.expectedHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(isRequired ? "Required" : "Optional")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isRequired ? .orange : .secondary)
            }

            Spacer()

            if count > 0 {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
            }

            Text("\(count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 24, alignment: .trailing)
        }
        .padding(.vertical, 6)
    }
}
