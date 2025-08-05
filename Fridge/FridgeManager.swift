import Foundation
import SwiftUI

class FridgeManager: ObservableObject {
    @Published var fridgeItems: [FridgeItem] = []
    @Published var shoppingList = ShoppingList()
    
    init() {
        loadData()
    }
    
    // MARK: - Data Management
    private func loadData() {
        // For now, we'll use in-memory storage with default items
        // In a real app, this would load from Core Data or UserDefaults
        if fridgeItems.isEmpty {
            fridgeItems = DefaultItems.createDefaultFridgeItems()
            saveData()
        }
    }
    
    private func saveData() {
        // In a real app, this would save to Core Data or UserDefaults
        // For now, we'll keep it in memory
    }
    
    // MARK: - Fridge Items Management
    func itemsForSection(_ section: FridgeSection) -> [FridgeItem] {
        return fridgeItems.filter { $0.section == section }
    }
    
    func addCustomItem(name: String, section: FridgeSection) {
        let newItem = FridgeItem(name: name, quantity: 1.0, section: section, isCustom: true)
        fridgeItems.append(newItem)
        saveData()
    }
    
    func removeItem(_ item: FridgeItem) {
        fridgeItems.removeAll { $0.id == item.id }
        saveData()
    }
    
    func updateItemQuantity(_ item: FridgeItem, quantity: Double) {
        item.updateQuantity(quantity)
        saveData()
    }
    
    // MARK: - Shopping List Management
    func generateShoppingList() {
        print("🛒 Generating shopping list...")
        print("📦 Total fridge items: \(fridgeItems.count)")
        
        shoppingList.items.removeAll()
        
        // Add items that need restocking (≤25%)
        let lowStockItems = fridgeItems.filter { $0.needsRestocking }
        print("📉 Low stock items found: \(lowStockItems.count)")
        
        for item in lowStockItems {
            let shoppingItem = ShoppingListItem(name: item.name, fridgeItem: item)
            shoppingList.addItem(shoppingItem)
            print("➕ Added low stock item: \(item.name) (\(item.quantityPercentage)%)")
        }
        
        // Add history-based suggestions (items purchased frequently)
        let frequentItems = getFrequentlyPurchasedItems()
        print("🔄 Frequent items found: \(frequentItems.count)")
        
        for item in frequentItems {
            // Only add if not already in the list
            if !shoppingList.items.contains(where: { $0.fridgeItem?.id == item.id }) {
                let shoppingItem = ShoppingListItem(name: item.name, fridgeItem: item)
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
        let tempItem = ShoppingListItem(name: name, isTemporary: true)
        shoppingList.addItem(tempItem)
    }
    
    func completeShoppingTrip() {
        shoppingList.completeShoppingAndUpdateInventory()
        saveData()
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
        fridgeItems.removeAll()
        shoppingList.items.removeAll()
        saveData()
    }
    
    func resetToDefaults() {
        fridgeItems.removeAll()
        shoppingList.items.removeAll()
        fridgeItems = DefaultItems.createDefaultFridgeItems()
        saveData()
    }
}