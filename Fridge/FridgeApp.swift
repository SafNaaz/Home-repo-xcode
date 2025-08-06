import SwiftUI

@main
struct FridgeApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var inventoryManager = InventoryManager()
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var notesManager = NotesManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(inventoryManager)
                .environmentObject(settingsManager)
                .environmentObject(notesManager)
                .preferredColorScheme(settingsManager.isDarkMode ? .dark : .light)
        }
    }
}