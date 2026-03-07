import Foundation
import SwiftData

enum DocumentCategory: String, Codable, CaseIterable, Identifiable {
    case invoices
    case receipts
    case bankReport

    var id: String { rawValue }

    static let legacyInvoiceRawValues: Set<String> = ["invoice1", "invoice2"]

    static func normalizedRawValue(_ rawValue: String) -> String {
        if legacyInvoiceRawValues.contains(rawValue) {
            return invoices.rawValue
        }
        return rawValue
    }

    static func fromStoredRawValue(_ rawValue: String) -> DocumentCategory {
        DocumentCategory(rawValue: normalizedRawValue(rawValue)) ?? .receipts
    }

    var title: String {
        switch self {
        case .invoices:
            return "Invoices"
        case .receipts:
            return "Receipts"
        case .bankReport:
            return "Bank Report"
        }
    }

    var expectedHint: String {
        switch self {
        case .invoices:
            return "Upload one or more invoice files"
        case .receipts:
            return "Multiple receipt files allowed"
        case .bankReport:
            return "Expected: monthly bank report"
        }
    }
}

enum MonthPacketStatus: String {
    case inProgress = "In Progress"
    case ready = "Ready"
}

struct ChecklistItem: Identifiable {
    var id: String { "checklist-\(category.rawValue)" }
    let category: DocumentCategory
    let isComplete: Bool
    let isRequired: Bool
}

@Model
final class MonthPacket {
    @Attribute(.unique) var id: UUID
    var monthLabel: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var isInvoicesRequired: Bool = true
    var isReceiptsRequired: Bool = true
    var isBankReportRequired: Bool = true
    @Relationship(deleteRule: .cascade, inverse: \StoredDocument.monthPacket) var documents: [StoredDocument]

    init(
        id: UUID = UUID(),
        monthLabel: String,
        notes: String = "",
        isInvoicesRequired: Bool = true,
        isReceiptsRequired: Bool = true,
        isBankReportRequired: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.monthLabel = monthLabel
        self.notes = notes
        self.isInvoicesRequired = isInvoicesRequired
        self.isReceiptsRequired = isReceiptsRequired
        self.isBankReportRequired = isBankReportRequired
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.documents = []
    }

    var status: MonthPacketStatus {
        for category in requiredCategories {
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

    var requiredCategories: [DocumentCategory] {
        DocumentCategory.allCases.filter(isCategoryRequired(_:))
    }

    var requiredCategoryCount: Int {
        requiredCategories.count
    }

    var completedRequiredCategoryCount: Int {
        requiredCategories.filter { documents(for: $0).isEmpty == false }.count
    }

    func isCategoryRequired(_ category: DocumentCategory) -> Bool {
        switch category {
        case .invoices:
            return isInvoicesRequired
        case .receipts:
            return isReceiptsRequired
        case .bankReport:
            return isBankReportRequired
        }
    }

    func setCategoryRequired(_ required: Bool, for category: DocumentCategory) {
        switch category {
        case .invoices:
            isInvoicesRequired = required
        case .receipts:
            isReceiptsRequired = required
        case .bankReport:
            isBankReportRequired = required
        }
    }

    var requiredChecklistItems: [ChecklistItem] {
        DocumentCategory.allCases
            .map { category in
                ChecklistItem(
                    category: category,
                    isComplete: documents(for: category).isEmpty == false,
                    isRequired: isCategoryRequired(category)
                )
            }
    }

    var missingRequiredCategories: [DocumentCategory] {
        requiredChecklistItems
            .filter { $0.isRequired && !$0.isComplete }
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
        get { DocumentCategory.fromStoredRawValue(categoryRawValue) }
        set { categoryRawValue = newValue.rawValue }
    }

    var displayName: String {
        originalFileName
    }
}
