import Foundation
import SwiftUI
import CoreData

class FridgeManager: ObservableObject {
    @Published var fridgeItems: [FridgeItem] = []
    @Published var shoppingList = ShoppingList()
    
    private let persistenceController = PersistenceController.shared
    
    init() {
        loadData()
    }
    
    // MARK: - Data Management
    private func loadData() {
        let entities = persistenceController.fetchFridgeItems()
        fridgeItems = entities.map { entity in
            let item = FridgeItem(
                name: entity.name ?? "",
                quantity: entity.quantity,
                section: FridgeSection(rawValue: entity.section ?? "") ?? .main,
                isCustom: entity.isCustom
            )
            item.id = entity.id ?? UUID()
            item.purchaseHistory = entity.purchaseHistory ?? []
            item.lastUpdated = entity.lastUpdated ?? Date()
            return item
        }
        
        loadShoppingList()
    }
    
    private func loadShoppingList() {
        let entities = persistenceController.fetchShoppingItems()
        shoppingList.items = entities.map { entity in
            let item = ShoppingListItem(
                name: entity.name ?? "",
                isTemporary: entity.isTemporary,
                fridgeItem: fridgeItems.first { $0.id == entity.fridgeItemId }
            )
            item.id = entity.id ?? UUID()
            item.isChecked = entity.isChecked
            return item
        }
    }
    
    private func saveData() {
        // Core Data saves automatically through PersistenceController
    }
    
    // MARK: - Fridge Items Management
    func itemsForSection(_ section: FridgeSection) -> [FridgeItem] {
        return fridgeItems.filter { $0.section == section }
    }
    
    func addCustomItem(name: String, section: FridgeSection) {
        let entity = persistenceController.createFridgeItem(name: name, section: section, quantity: 1.0, isCustom: true)
        let newItem = FridgeItem(name: name, quantity: 1.0, section: section, isCustom: true)
        newItem.id = entity.id ?? UUID()
        fridgeItems.append(newItem)
    }
    
    func removeItem(_ item: FridgeItem) {
        // Find and delete the Core Data entity
        let entities = persistenceController.fetchFridgeItems()
        if let entity = entities.first(where: { $0.id == item.id }) {
            persistenceController.deleteFridgeItem(entity)
        }
        
        // Remove from local array
        fridgeItems.removeAll { $0.id == item.id }
    }
    
    func updateItemQuantity(_ item: FridgeItem, quantity: Double) {
        // Update Core Data entity
        let entities = persistenceController.fetchFridgeItems()
        if let entity = entities.first(where: { $0.id == item.id }) {
            persistenceController.updateFridgeItem(entity, quantity: quantity)
        }
        
        // Update local item
        item.updateQuantity(quantity)
    }
    
    // MARK: - Shopping List Management
    func generateShoppingList() {
        print("🛒 Generating shopping list...")
        print("📦 Total fridge items: \(fridgeItems.count)")
        
        // Clear existing shopping list in Core Data
        persistenceController.clearAllShoppingItems()
        shoppingList.items.removeAll()
        
        // Add items that need restocking (≤25%)
        let lowStockItems = fridgeItems.filter { $0.needsRestocking }
        print("📉 Low stock items found: \(lowStockItems.count)")
        
        for item in lowStockItems {
            let entity = persistenceController.createShoppingItem(name: item.name, fridgeItemId: item.id, isTemporary: false)
            let shoppingItem = ShoppingListItem(name: item.name, fridgeItem: item)
            shoppingItem.id = entity.id ?? UUID()
            shoppingList.addItem(shoppingItem)
            print("➕ Added low stock item: \(item.name) (\(item.quantityPercentage)%)")
        }
        
        // Add history-based suggestions (items purchased frequently)
        let frequentItems = getFrequentlyPurchasedItems()
        print("🔄 Frequent items found: \(frequentItems.count)")
        
        for item in frequentItems {
            // Only add if not already in the list
            if !shoppingList.items.contains(where: { $0.fridgeItem?.id == item.id }) {
                let entity = persistenceController.createShoppingItem(name: item.name, fridgeItemId: item.id, isTemporary: false)
                let shoppingItem = ShoppingListItem(name: item.name, fridgeItem: item)
                shoppingItem.id = entity.id ?? UUID()
                shoppingList.addItem(shoppingItem)
                print("➕ Added frequent item: \(item.name)")
            }
        }
        
        print("✅ Shopping list generated with \(shoppingList.items.count) items")
        
        // Force UI update
        objectWillChange.send()
    }
    
    private func getFrequentlyPurchasedItems() -> [FridgeItem] {
        // Sort items by purchase frequency (number of times purchased)
        let sortedItems = fridgeItems.sorted { item1, item2 in
            item1.purchaseHistory.count > item2.purchaseHistory.count
        }
        
        // Return top 5 frequently purchased items that aren't already low stock
        return Array(sortedItems.filter { !$0.needsRestocking }.prefix(5))
    }
    
    func addTemporaryItemToShoppingList(name: String) {
        let entity = persistenceController.createShoppingItem(name: name, isTemporary: true)
        let tempItem = ShoppingListItem(name: name, isTemporary: true)
        tempItem.id = entity.id ?? UUID()
        shoppingList.addItem(tempItem)
    }
    
    func completeShoppingTrip() {
        // Update fridge items that were purchased
        for item in shoppingList.items where item.isChecked && !item.isTemporary {
            if let fridgeItem = item.fridgeItem {
                let entities = persistenceController.fetchFridgeItems()
                if let entity = entities.first(where: { $0.id == fridgeItem.id }) {
                    persistenceController.restockFridgeItem(entity)
                }
                fridgeItem.restockToFull()
            }
        }
        
        // Clear shopping list
        persistenceController.clearAllShoppingItems()
        shoppingList.items.removeAll()
    }
    
    // MARK: - Statistics
    var totalItems: Int {
        fridgeItems.count
    }
    
    var lowStockItemsCount: Int {
        fridgeItems.filter { $0.needsRestocking }.count
    }
    
    var averageStockLevel: Double {
        guard !fridgeItems.isEmpty else { return 0 }
        let totalStock = fridgeItems.reduce(0) { $0 + $1.quantity }
        return totalStock / Double(fridgeItems.count)
    }
    
    func itemsNeedingAttention() -> [FridgeItem] {
        return fridgeItems.filter { $0.needsRestocking }.sorted { $0.quantity < $1.quantity }
    }
    
    // MARK: - Data Management
    func clearAllData() {
        persistenceController.clearAllData()
        fridgeItems.removeAll()
        shoppingList.items.removeAll()
    }
    
    func resetToDefaults() {
        // Just clear all data - no more pre-populated items
        clearAllData()
    }
}