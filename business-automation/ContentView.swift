import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MonthPacket.createdAt, order: .reverse) private var monthPackets: [MonthPacket]

    @State private var selectedMonthID: UUID?
    @State private var lastValidSelectedMonthID: UUID?
    @State private var isClearingSelectionForDeletion = false
    @State private var hasRunLegacyCategoryMigration = false
    @State private var isCreateSheetPresented = false
    @State private var incomingImportNotice: String?
    
    private var readyMonthsCount: Int {
        monthPackets.filter { $0.status == .ready }.count
    }

    private var selectedMonth: MonthPacket? {
        guard let selectedMonthID else { return nil }
        return monthPackets.first(where: { $0.id == selectedMonthID })
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 12) {
                SidebarHeader(
                    totalMonths: monthPackets.count,
                    readyMonths: readyMonthsCount,
                    onCreateTapped: { isCreateSheetPresented = true }
                )

                List(selection: $selectedMonthID) {
                    Section("Month Packets") {
                        ForEach(monthPackets) { month in
                            MonthRow(month: month)
                                .tag(month.id)
                                .hoverPointer()
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deleteMonths)
                    }

                    if monthPackets.isEmpty {
                        Text("No months yet. Start by creating one.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .navigationTitle("Bookkeeping")
            .toolbar {
                ToolbarItem {
                    Button {
                        isCreateSheetPresented = true
                    } label: {
                        Label("New Month", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isCreateSheetPresented) {
                MonthCreateSheet { date in
                    createOrSelectMonth(from: date)
                }
                .preferredColorScheme(.dark)
            }
            .sidebarCanvas()
        } detail: {
            Group {
                if let selectedMonth {
                    MonthDetailHostView(monthPacket: selectedMonth)
                    .id(selectedMonth.id)
                } else {
                    VStack(spacing: 14) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(AppTheme.highlight)

                        Text("Select a Month")
                            .font(.system(.title2, design: .rounded).weight(.bold))

                        Text("Create or select a month packet to track documents.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .darkCanvas()
        }
        .preferredColorScheme(.dark)
        .tint(AppTheme.highlight)
        .onOpenURL { incomingURL in
            handleIncomingSharedFile(incomingURL)
        }
        .task {
            runLegacyCategoryMigrationIfNeeded()
        }
        .onChange(of: selectedMonthID) { _, newValue in
            if let newValue {
                lastValidSelectedMonthID = newValue
                return
            }

            if isClearingSelectionForDeletion {
                isClearingSelectionForDeletion = false
                return
            }

            if let lastValidSelectedMonthID,
               monthPackets.contains(where: { $0.id == lastValidSelectedMonthID }) {
                selectedMonthID = lastValidSelectedMonthID
            }
        }
        .alert("Share Import", isPresented: Binding(
            get: { incomingImportNotice != nil },
            set: { isShown in
                if !isShown {
                    incomingImportNotice = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(incomingImportNotice ?? "")
        }
    }

    private func createOrSelectMonth(from date: Date) {
        let label = monthLabel(for: date)

        if let existing = monthPackets.first(where: { $0.monthLabel == label }) {
            selectedMonthID = existing.id
            return
        }

        let packet = MonthPacket(monthLabel: label)
        modelContext.insert(packet)
        packet.markUpdated()

        do {
            try modelContext.save()
            selectedMonthID = packet.id
        } catch {
            print("Failed to create month packet: \(error)")
        }
    }

    private func deleteMonths(offsets: IndexSet) {
        let deletedIDs = Set(offsets.map { monthPackets[$0].id })

        for index in offsets {
            let month = monthPackets[index]

            for document in month.documents {
                DocumentStorageService.deleteStoredFile(for: document)
            }

            modelContext.delete(month)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete month packets: \(error)")
        }

        if let selectedMonthID, deletedIDs.contains(selectedMonthID) {
            isClearingSelectionForDeletion = true
            self.selectedMonthID = nil
        }
    }

    private func monthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }

    private func handleIncomingSharedFile(_ fileURL: URL) {
        guard let selectedMonth else {
            incomingImportNotice = "Open a month packet first, then share/import the bank report again."
            return
        }

        do {
            try MonthPacketService.addDocuments(
                urls: [fileURL],
                to: selectedMonth,
                category: .bankReport,
                modelContext: modelContext
            )
            incomingImportNotice = "Imported into \(selectedMonth.monthLabel) → Bank Report."
        } catch {
            incomingImportNotice = "Failed to import shared file: \(error.localizedDescription)"
        }
    }

    private func runLegacyCategoryMigrationIfNeeded() {
        guard !hasRunLegacyCategoryMigration else { return }
        hasRunLegacyCategoryMigration = true

        let descriptor = FetchDescriptor<StoredDocument>(
            predicate: #Predicate { document in
                document.categoryRawValue == "invoice1" || document.categoryRawValue == "invoice2"
            }
        )

        do {
            let legacyDocuments = try modelContext.fetch(descriptor)
            guard !legacyDocuments.isEmpty else { return }

            for document in legacyDocuments {
                document.categoryRawValue = DocumentCategory.invoices.rawValue
                document.monthPacket?.markUpdated()
            }

            try modelContext.save()
        } catch {
            print("Failed to migrate legacy invoice categories: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [MonthPacket.self, StoredDocument.self], inMemory: true)
}
