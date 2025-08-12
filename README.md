
# Home inventory

This is a SwiftUI-based iOS/macOS app designed to help users manage their home inventory, shopping lists, notes, and gain insights into their household item usage. The app leverages Core Data for persistence and provides a modern, intuitive interface for tracking and organizing all types of home items.


## Features

- **Inventory Management:** Add, edit, and remove items from your home inventory (not limited to the fridge).
- **Shopping List:** Create and manage shopping lists for household needs.
- **Notes:** Keep notes related to your home or inventory items.
- **Insights & Stats:** View statistics and insights about your household item usage and waste.
- **Settings:** Customize app preferences.
- **Persistence:** Data is stored locally using Core Data.

## Project Structure

- `ContentView.swift` - Main entry point for the app's UI.
- `FridgeApp.swift` - App lifecycle and main configuration.
- `FridgeManager.swift` - Logic for managing fridge items.
- `ShoppingListView.swift` - UI for shopping list management.
- `NotesView.swift` - UI for notes.
- `InsightsView.swift` - UI for insights and statistics.
- `StatsView.swift` - Additional statistics and analytics.
- `SettingsView.swift` - UI for app settings.
- `SettingsManager.swift` - Logic for managing settings.
- `Models.swift` - Data models for the app.
- `PersistenceController.swift` - Core Data stack and persistence logic.
- `Assets.xcassets` - App icons and color assets.
- `Fridge.xcdatamodeld` - Core Data model.

## Getting Started

1. Open `Fridge.xcodeproj` in Xcode.
2. Build and run the app on a simulator or device.
3. Explore the features to manage your home inventory efficiently!

## Requirements

- Xcode 13 or later
- iOS 15.0+ or macOS 12.0+
- Swift 5.5+

## License

This project is licensed under the MIT License.
