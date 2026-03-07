import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

struct MonthDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var monthPacket: MonthPacket
    @Binding var selectedMonthID: UUID?
    @State private var exportURL: URL?
    @State private var exportErrorMessage: String?

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Overview")
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                        Text("Track required business documents")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusBadge(status: monthPacket.status)
                }
            }
            .cardRow()

            Section("Categories") {
                ForEach(DocumentCategory.allCases) { category in
                    NavigationLink(value: category) {
                        CategoryRow(category: category, count: monthPacket.documentCount(for: category))
                    }
                    .cardRow()
                }
            }

            Section("Checklist Summary") {
                ForEach(monthPacket.requiredChecklistItems) { item in
                    HStack {
                        Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isComplete ? .green : .secondary)
                        Text(item.category.title)
                        Spacer()
                        Text(item.isComplete ? "Done" : "Missing")
                            .font(.caption)
                            .foregroundStyle(item.isComplete ? .green : .orange)
                    }
                }
                .cardRow()
            }

            Section("All Files") {
                if monthPacket.documents.isEmpty {
                    Text("No files added yet")
                        .foregroundStyle(.secondary)
                        .cardRow()
                } else {
                    ForEach(monthPacket.documents.sorted(by: { $0.addedAt > $1.addedAt })) { document in
                        HStack {
                            Image(systemName: document.category.symbolName)
                                .foregroundStyle(AppTheme.highlight)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(document.displayName)
                                    .font(.subheadline.weight(.medium))
                                Text(document.category.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .cardRow()
                }
            }

            Section("Package Export") {
                Button {
                    prepareExportPackage()
                } label: {
                    Label("Prepare Export Folder", systemImage: "folder.badge.plus")
                }
                .cardRow()

                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label("Share Export Folder", systemImage: "square.and.arrow.up")
                    }
                    .cardRow()
                }
            }

            Section("Email Draft") {
                Text(MonthPacketService.emailDraft(for: monthPacket))
                    .font(.callout.monospaced())
                    .textSelection(.enabled)
                    .cardRow()

                Button {
                    copyEmailDraftToClipboard()
                } label: {
                    Label("Copy Email Draft", systemImage: "doc.on.doc")
                }
                .cardRow()
            }

            Section("Notes") {
                TextEditor(text: $monthPacket.notes)
                    .frame(minHeight: 130)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.black.opacity(0.25))
                    )
                    .onChange(of: monthPacket.notes) {
                        monthPacket.markUpdated()
                    }
            }
            .cardRow()
        }
        .scrollContentBackground(.hidden)
        .safeAreaPadding(.horizontal, 10)
        .navigationTitle(monthPacket.monthLabel)
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .alert("Export Failed", isPresented: Binding(
            get: { exportErrorMessage != nil },
            set: { shown in
                if !shown {
                    exportErrorMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportErrorMessage ?? "Could not export this month.")
        }
        .darkCanvas()
        .onAppear {
            if selectedMonthID != monthPacket.id {
                selectedMonthID = monthPacket.id
            }
            monthPacket.markUpdated()
            try? modelContext.save()
        }
        .onChange(of: monthPacket.id) {
            if selectedMonthID != monthPacket.id {
                selectedMonthID = monthPacket.id
            }
        }
    }

    private func prepareExportPackage() {
        do {
            exportURL = try MonthPacketService.exportPackage(for: monthPacket)
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private func copyEmailDraftToClipboard() {
        let draft = MonthPacketService.emailDraft(for: monthPacket)
#if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(draft, forType: .string)
#elseif os(iOS)
        UIPasteboard.general.string = draft
#endif
    }
}
