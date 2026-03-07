import SwiftUI
import SwiftData
import Foundation

@main
struct business_automationApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MonthPacket.self,
            StoredDocument.self,
        ])
        let storeURL = Self.persistentStoreURL()
        let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            Self.nukeStore(at: storeURL)
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
#if os(macOS)
        .windowStyle(.hiddenTitleBar)
#endif
    }

    private static func persistentStoreURL() -> URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let folderURL = appSupport.appendingPathComponent("business-automation", isDirectory: true)
        try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        return folderURL.appendingPathComponent("Bookkeeping.store")
    }

    private static func nukeStore(at storeURL: URL) {
        let fileManager = FileManager.default
        let walURL = URL(fileURLWithPath: storeURL.path + "-wal")
        let shmURL = URL(fileURLWithPath: storeURL.path + "-shm")
        let journalURL = URL(fileURLWithPath: storeURL.path + "-journal")

        for url in [storeURL, walURL, shmURL, journalURL] {
            if fileManager.fileExists(atPath: url.path) {
                try? fileManager.removeItem(at: url)
            }
        }
    }
}
