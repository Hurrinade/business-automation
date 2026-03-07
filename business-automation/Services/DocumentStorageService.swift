import Foundation

struct DocumentStorageService {
    enum StorageError: Error {
        case appSupportUnavailable
    }

    private static let rootFolderName = "MonthPackets"

    static func copyImportedFile(from sourceURL: URL, monthID: UUID, category: DocumentCategory) throws -> (storedFileName: String, storedRelativePath: String) {
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw StorageError.appSupportUnavailable
        }

        let folderURL = appSupportURL
            .appendingPathComponent(rootFolderName, isDirectory: true)
            .appendingPathComponent(monthID.uuidString, isDirectory: true)
            .appendingPathComponent(category.rawValue, isDirectory: true)

        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

        let fileExtension = sourceURL.pathExtension
        let storedFileName = fileExtension.isEmpty ? UUID().uuidString : "\(UUID().uuidString).\(fileExtension)"
        let destinationURL = folderURL.appendingPathComponent(storedFileName)

        if sourceURL.startAccessingSecurityScopedResource() {
            defer { sourceURL.stopAccessingSecurityScopedResource() }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        } else {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        }

        let storedRelativePath = "\(rootFolderName)/\(monthID.uuidString)/\(category.rawValue)/\(storedFileName)"
        return (storedFileName, storedRelativePath)
    }

    static func absoluteURL(for document: StoredDocument) -> URL? {
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        return appSupportURL.appendingPathComponent(document.storedRelativePath)
    }

    static func deleteStoredFile(for document: StoredDocument) {
        guard let fileURL = absoluteURL(for: document) else {
            return
        }

        try? FileManager.default.removeItem(at: fileURL)
    }
}
