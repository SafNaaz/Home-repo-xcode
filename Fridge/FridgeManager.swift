import Foundation
import SwiftUI
import CoreData

class FridgeManager: ObservableObject {
    @Published var fridgeItems: [FridgeItem] = []
    @Published var shoppingList = ShoppingList()
    @Published var shoppingState: ShoppingState = .empty
    
    private let persistenceController = PersistenceController.shared
    
    init() {
        loadData()
    }
    
    // MARK: - Data Management
    private func loadData() {
        print("📂 Loading data from Core Data...")
        let entities = persistenceController.fetchFridgeItems()
        print("📦 Found \(entities.count) items in Core Data")
        
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
            print("📦 Loaded item: \(item.name) with \(item.quantityPercentage)% stock")
            return item
        }
        
        loadShoppingList()
    }
    
    func refreshData() {
        loadData()
        objectWillChange.send()
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
        print("🗑️ Removing item: \(item.name)")
        
        // Use DispatchQueue to ensure proper UI updates
        DispatchQueue.main.async {
            // Find and delete the Core Data entity
            let entities = self.persistenceController.fetchFridgeItems()
            if let entity = entities.first(where: { $0.id == item.id }) {
                self.persistenceController.deleteFridgeItem(entity)
                print("✅ Core Data entity deleted for: \(item.name)")
            } else {
                print("❌ Core Data entity not found for: \(item.name)")
            }
            
            // Remove from local array on main thread
            self.fridgeItems.removeAll { $0.id == item.id }
            print("✅ Local item removed: \(item.name)")
        }
    }
    
    func updateItemQuantity(_ item: FridgeItem, quantity: Double) {
        print("🔄 Updating item quantity: \(item.name) to \(Int(quantity * 100))%")
        
        // Update Core Data entity
        let entities = persistenceController.fetchFridgeItems()
        if let entity = entities.first(where: { $0.id == item.id }) {
            persistenceController.updateFridgeItem(entity, quantity: quantity)
            print("✅ Core Data updated for: \(item.name)")
        } else {
            print("❌ Core Data entity not found for: \(item.name)")
        }
        
        // Update local item
        item.updateQuantity(quantity)
        print("✅ Local item updated for: \(item.name)")
        
        // Force UI update to reflect changes
        objectWillChange.send()
    }
    
    // MARK: - Shopping List Management
    func startGeneratingShoppingList() {
        print("🛒 Starting shopping list generation...")
        
        // Clear existing shopping list in Core Data
        persistenceController.clearAllShoppingItems()
        shoppingList.items.removeAll()
        
        // Add items that need attention (≤25%) - sorted by urgency
        let attentionItems = fridgeItems.filter { $0.needsRestocking }.sorted { $0.quantity < $1.quantity }
        print("⚠️ Attention items found: \(attentionItems.count)")
        
        for item in attentionItems {
            let entity = persistenceController.createShoppingItem(name: item.name, fridgeItemId: item.id, isTemporary: false)
            let shoppingItem = ShoppingListItem(name: item.name, fridgeItem: item)
            shoppingItem.id = entity.id ?? UUID()
            shoppingList.addItem(shoppingItem)
            print("➕ Added attention item: \(item.name) (\(item.quantityPercentage)%)")
        }
        
        // Set state to generating
        shoppingState = .generating
        print("✅ Shopping list generation started with \(shoppingList.items.count) items")
    }
    
    func finalizeShoppingList() {
        print("📋 Finalizing shopping list...")
        shoppingState = .listReady
        print("✅ Shopping list finalized - now read-only")
    }
    
    func startShopping() {
        print("🛍️ Starting shopping trip...")
        shoppingState = .shopping
        print("✅ Shopping started - checklist unlocked")
    }
    
    func completeAndRestoreShopping() {
        print("✅ Completing shopping trip and restoring items...")
        
        // Update fridge items that were purchased
        for item in shoppingList.items where item.isChecked && !item.isTemporary {
            if let fridgeItem = item.fridgeItem {
                let entities = persistenceController.fetchFridgeItems()
                if let entity = entities.first(where: { $0.id == fridgeItem.id }) {
                    persistenceController.restockFridgeItem(entity)
                }
                fridgeItem.restockToFull()
                print("🔄 Restored \(fridgeItem.name) to 100%")
            }
        }
        
        // Clear shopping list and reset state
        persistenceController.clearAllShoppingItems()
        shoppingList.items.removeAll()
        shoppingState = .empty
        
        print("✅ Shopping completed and inventory restored")
    }
    
    func cancelShopping() {
        print("❌ Cancelling shopping...")
        persistenceController.clearAllShoppingItems()
        shoppingList.items.removeAll()
        shoppingState = .empty
        print("✅ Shopping cancelled")
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
        guard shoppingState == .generating else { return }
        
        let entity = persistenceController.createShoppingItem(name: name, isTemporary: true)
        let tempItem = ShoppingListItem(name: name, isTemporary: true)
        tempItem.id = entity.id ?? UUID()
        shoppingList.addItem(tempItem)
        print("➕ Added temporary item: \(name)")
    }
    
    func removeItemFromShoppingList(_ item: ShoppingListItem) {
        guard shoppingState == .generating else { return }
        
        // Delete from Core Data
        let entities = persistenceController.fetchShoppingItems()
        if let entity = entities.first(where: { $0.id == item.id }) {
            persistenceController.deleteShoppingItem(entity)
        }
        // Remove from local list
        shoppingList.removeItem(item)
        print("➖ Removed item from shopping list: \(item.name)")
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