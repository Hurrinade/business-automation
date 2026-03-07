import SwiftUI

struct MonthCreateSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate = Date()

    let onCreate: (Date) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Create Month Packet")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                DatePicker("Month", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.cardFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(AppTheme.cardStroke, lineWidth: 1)
                            )
                    )

                HStack {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }

                    Spacer()

                    Button("Create") {
                        onCreate(selectedDate)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
            .darkCanvas()
        }
    }
}
