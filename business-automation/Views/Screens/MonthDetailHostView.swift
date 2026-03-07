import SwiftUI
import SwiftData

struct MonthDetailHostView: View {
    @Bindable var monthPacket: MonthPacket
    @State private var selectedCategory: DocumentCategory?

    var body: some View {
        NavigationStack {
            MonthDetailView(monthPacket: monthPacket) { category in
                // Force a clean transition so first click after month load always pushes.
                selectedCategory = nil
                DispatchQueue.main.async {
                    selectedCategory = category
                }
            }
            .navigationDestination(item: $selectedCategory) { category in
                CategoryDetailView(monthPacket: monthPacket, category: category)
            }
        }
    }
}
