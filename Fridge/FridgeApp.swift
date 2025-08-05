import SwiftUI

@main
struct FridgeApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var fridgeManager = FridgeManager()
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(fridgeManager)
                .environmentObject(settingsManager)
                .preferredColorScheme(settingsManager.isDarkMode ? .dark : .light)
        }
    }
}