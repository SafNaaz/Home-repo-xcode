import SwiftUI

@main
struct FridgeApp: App {
    @StateObject private var fridgeManager = FridgeManager()
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fridgeManager)
                .environmentObject(settingsManager)
                .preferredColorScheme(settingsManager.isDarkMode ? .dark : .light)
        }
    }
}