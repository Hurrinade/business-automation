import Foundation
import SwiftData

struct MonthPacketService {
    enum ServiceError: Error {
        case fileCopyFailed
        case noExportableFiles
    }

    static func addDocuments(
        urls: [URL],
        to monthPacket: MonthPacket,
        category: DocumentCategory,
        modelContext: ModelContext
    ) throws {
        guard !urls.isEmpty else { return }

        for url in urls {
            let stored = try DocumentStorageService.copyImportedFile(from: url, monthID: monthPacket.id, category: category)
            let document = StoredDocument(
                category: category,
                originalFileName: url.lastPathComponent,
                storedFileName: stored.storedFileName,
                storedRelativePath: stored.storedRelativePath,
                monthPacket: monthPacket
            )
            modelContext.insert(document)
        }

        monthPacket.markUpdated()
        try modelContext.save()
    }

    static func exportPackage(for monthPacket: MonthPacket) throws -> URL {
        guard !monthPacket.documents.isEmpty else {
            throw ServiceError.noExportableFiles
        }

        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory
            .appendingPathComponent("MonthPacketExports", isDirectory: true)
        try fileManager.createDirectory(at: tempRoot, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let folderName = "\(monthPacket.monthLabel.replacingOccurrences(of: " ", with: "-"))-\(formatter.string(from: Date()))"

        let exportFolderURL = tempRoot.appendingPathComponent(folderName, isDirectory: true)
        try fileManager.createDirectory(at: exportFolderURL, withIntermediateDirectories: true)

        for category in DocumentCategory.allCases {
            let categoryDocuments = monthPacket.documents(for: category)
            guard !categoryDocuments.isEmpty else { continue }

            let categoryFolder = exportFolderURL.appendingPathComponent(category.title, isDirectory: true)
            try fileManager.createDirectory(at: categoryFolder, withIntermediateDirectories: true)

            for (index, document) in categoryDocuments.enumerated() {
                guard let sourceURL = DocumentStorageService.absoluteURL(for: document) else { continue }

                let baseName = (document.originalFileName as NSString).deletingPathExtension
                let ext = (document.originalFileName as NSString).pathExtension
                let cleanName = baseName.isEmpty ? "Document-\(index + 1)" : baseName
                let outputName = ext.isEmpty ? "\(cleanName)-\(index + 1)" : "\(cleanName)-\(index + 1).\(ext)"
                let destinationURL = categoryFolder.appendingPathComponent(outputName)

                do {
                    try fileManager.copyItem(at: sourceURL, to: destinationURL)
                } catch {
                    throw ServiceError.fileCopyFailed
                }
            }
        }

        let summaryURL = exportFolderURL.appendingPathComponent("Checklist-Summary.txt")
        let summaryText = emailDraft(for: monthPacket)
        try summaryText.write(to: summaryURL, atomically: true, encoding: .utf8)

        return exportFolderURL
    }

    static func emailDraft(for monthPacket: MonthPacket) -> String {
        let month = monthPacket.monthLabel

        return """
        Subject: Datum isplate plače i dokumenti \(month)

        Pozdrav,

        U privitku dostavljam dokumente za \(month):
        - Računi
        - Troškovi firme
        - Izvadak iz banke

        LP,
        Marko Uremović
        Rinade d.o.o.
        """
    }
}
