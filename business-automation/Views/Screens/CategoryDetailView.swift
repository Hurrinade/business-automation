import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import QuickLook

struct CategoryDetailView: View {
    @Environment(\.modelContext) private var modelContext

    @Bindable var monthPacket: MonthPacket
    let category: DocumentCategory

    @State private var isImporterPresented = false
    @State private var importErrorMessage: String?
    @State private var previewURL: URL?
    @State private var pendingDeleteDocument: StoredDocument?

    private var categoryDocuments: [StoredDocument] {
        monthPacket.documents(for: category)
    }

    var body: some View {
        List {
            Section {
                Label(category.expectedHint, systemImage: category.symbolName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .cardRow()

            Section {
                if categoryDocuments.isEmpty {
                    Text("No files in this category")
                        .foregroundStyle(.secondary)
                        .cardRow()
                } else {
                    ForEach(categoryDocuments) { document in
                        HStack(spacing: 12) {
                            Button {
                                previewURL = DocumentStorageService.absoluteURL(for: document)
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(document.displayName)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text(metadataLine(for: document))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            .hoverPointer()

                            Button(role: .destructive) {
                                pendingDeleteDocument = document
                            } label: {
                                Image(systemName: "trash")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .buttonStyle(.borderless)
                            .hoverPointer()
                        }
                    }
                    .cardRow()
                }
            }
        }
        .scrollContentBackground(.hidden)
        .safeAreaPadding(.horizontal, 10)
        .navigationTitle(category.title)
        .toolbar {
            ToolbarItem {
                Button {
                    isImporterPresented = true
                } label: {
                    Label("Add Files", systemImage: "plus")
                }
                .hoverPointer()
            }
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true,
            onCompletion: handleImportResult
        )
        .alert("Import Failed", isPresented: Binding(
            get: { importErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    importErrorMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage ?? "Unknown import error")
        }
        .alert(
            "Delete File?",
            isPresented: Binding(
                get: { pendingDeleteDocument != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingDeleteDocument = nil
                    }
                }
            ),
            presenting: pendingDeleteDocument
        ) { document in
            Button("Delete", role: .destructive) {
                deleteDocument(document)
            }
            Button("Cancel", role: .cancel) {}
        } message: { document in
            Text("This permanently removes '\(document.displayName)'.")
        }
        .quickLookPreview($previewURL)
        .darkCanvas()
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            importErrorMessage = error.localizedDescription
        case .success(let urls):
            guard !urls.isEmpty else { return }

            do {
                try MonthPacketService.addDocuments(
                    urls: urls,
                    to: monthPacket,
                    category: category,
                    modelContext: modelContext
                )
            } catch {
                importErrorMessage = error.localizedDescription
            }
        }
    }

    private func deleteDocument(_ document: StoredDocument) {
        DocumentStorageService.deleteStoredFile(for: document)
        modelContext.delete(document)
        monthPacket.markUpdated()

        do {
            try modelContext.save()
        } catch {
            importErrorMessage = error.localizedDescription
        }

        pendingDeleteDocument = nil
    }

    private func metadataLine(for document: StoredDocument) -> String {
        let sizeText = fileSizeText(for: document)
        let dateText = document.addedAt.formatted(date: .numeric, time: .shortened)
        return "\(sizeText) • Added \(dateText)"
    }

    private func fileSizeText(for document: StoredDocument) -> String {
        guard let url = DocumentStorageService.absoluteURL(for: document),
              let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let rawSize = attributes[.size] as? NSNumber else {
            return "Unknown size"
        }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: rawSize.int64Value)
    }
}
