import SwiftUI

@main
struct FridgeApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var inventoryManager = InventoryManager()
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(inventoryManager)
                .environmentObject(settingsManager)
                .preferredColorScheme(settingsManager.isDarkMode ? .dark : .light)
        }
    }
}