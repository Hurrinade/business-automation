import Foundation
import SwiftData

enum DocumentCategory: String, Codable, CaseIterable, Identifiable {
    case invoice1
    case invoice2
    case receipts
    case bankReport

    var id: String { rawValue }

    var title: String {
        switch self {
        case .invoice1:
            return "Invoice 1"
        case .invoice2:
            return "Invoice 2"
        case .receipts:
            return "Receipts"
        case .bankReport:
            return "Bank Report"
        }
    }

    var expectedHint: String {
        switch self {
        case .invoice1, .invoice2:
            return "Expected: invoice file"
        case .receipts:
            return "Multiple receipt files allowed"
        case .bankReport:
            return "Expected: monthly bank report"
        }
    }

    var isRequiredForReady: Bool {
        switch self {
        case .invoice1, .invoice2, .bankReport:
            return true
        case .receipts:
            return false
        }
    }
}

enum MonthPacketStatus: String {
    case inProgress = "In Progress"
    case ready = "Ready"
}

struct ChecklistItem: Identifiable {
    var id: String { category.rawValue }
    let category: DocumentCategory
    let isComplete: Bool
}

@Model
final class MonthPacket {
    @Attribute(.unique) var id: UUID
    var monthLabel: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \StoredDocument.monthPacket) var documents: [StoredDocument]

    init(
        id: UUID = UUID(),
        monthLabel: String,
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.monthLabel = monthLabel
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.documents = []
    }

    var status: MonthPacketStatus {
        for category in DocumentCategory.allCases where category.isRequiredForReady {
            if documents.first(where: { $0.category == category }) == nil {
                return .inProgress
            }
        }
        return .ready
    }

    func documents(for category: DocumentCategory) -> [StoredDocument] {
        documents
            .filter { $0.category == category }
            .sorted(by: { $0.addedAt > $1.addedAt })
    }

    func documentCount(for category: DocumentCategory) -> Int {
        documents(for: category).count
    }

    func markUpdated() {
        updatedAt = Date()
    }

    var requiredChecklistItems: [ChecklistItem] {
        DocumentCategory.allCases
            .filter(\.isRequiredForReady)
            .map { category in
                ChecklistItem(
                    category: category,
                    isComplete: documents(for: category).isEmpty == false
                )
            }
    }

    var missingRequiredCategories: [DocumentCategory] {
        requiredChecklistItems
            .filter { !$0.isComplete }
            .map(\.category)
    }
}

@Model
final class StoredDocument {
    @Attribute(.unique) var id: UUID
    var categoryRawValue: String
    var originalFileName: String
    var storedFileName: String
    var storedRelativePath: String
    var addedAt: Date
    var monthPacket: MonthPacket?

    init(
        id: UUID = UUID(),
        category: DocumentCategory,
        originalFileName: String,
        storedFileName: String,
        storedRelativePath: String,
        addedAt: Date = Date(),
        monthPacket: MonthPacket? = nil
    ) {
        self.id = id
        self.categoryRawValue = category.rawValue
        self.originalFileName = originalFileName
        self.storedFileName = storedFileName
        self.storedRelativePath = storedRelativePath
        self.addedAt = addedAt
        self.monthPacket = monthPacket
    }

    var category: DocumentCategory {
        get { DocumentCategory(rawValue: categoryRawValue) ?? .receipts }
        set { categoryRawValue = newValue.rawValue }
    }

    var displayName: String {
        originalFileName
    }
}
