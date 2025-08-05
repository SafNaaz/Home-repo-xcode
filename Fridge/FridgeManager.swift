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
        
        fridgeItems = entities.compactMap { entity in
            guard let name = entity.name,
                  let sectionRaw = entity.section,
                  let section = FridgeSection(rawValue: sectionRaw),
                  let entityId = entity.id else {
                print("❌ Invalid entity data, skipping")
                return nil
            }
            
            let item = FridgeItem(
                name: name,
                quantity: entity.quantity,
                section: section,
                isCustom: entity.isCustom
            )
            item.id = entityId
            item.purchaseHistory = entity.purchaseHistory ?? []
            item.lastUpdated = entity.lastUpdated ?? Date()
            print("📦 Loaded item: \(item.name) with \(item.quantityPercentage)% stock (ID: \(entityId))")
            return item
        }
        
        loadShoppingList()
        
        // Load shopping state from Core Data
        shoppingState = persistenceController.fetchShoppingState()
        print("📱 Restored shopping state: \(shoppingState)")
    }
    
    func refreshData() {
        loadData()
        objectWillChange.send()
    }
    
    private func loadShoppingList() {
        let entities = persistenceController.fetchShoppingItems()
        print("🛒 Loading \(entities.count) shopping items from Core Data")
        
        shoppingList.items = entities.map { entity in
            let item = ShoppingListItem(
                name: entity.name ?? "",
                isTemporary: entity.isTemporary,
                fridgeItem: fridgeItems.first { $0.id == entity.fridgeItemId }
            )
            item.id = entity.id ?? UUID()
            item.isChecked = entity.isChecked
            print("📦 Loaded shopping item: \(item.name), checked: \(item.isChecked), temporary: \(item.isTemporary)")
            return item
        }
        
        print("✅ Shopping list loaded with \(shoppingList.items.count) items, \(shoppingList.checkedItems.count) checked")
    }
    
    private func saveData() {
        // Core Data saves automatically through PersistenceController
    }
    
    // MARK: - Fridge Items Management
    func itemsForSection(_ section: FridgeSection) -> [FridgeItem] {
        return fridgeItems.filter { $0.section == section }
    }
    
    func addCustomItem(name: String, section: FridgeSection) {
        print("➕ Adding custom item: \(name) to \(section.rawValue)")
        
        DispatchQueue.main.async {
            let entity = self.persistenceController.createFridgeItem(name: name, section: section, quantity: 1.0, isCustom: true)
            let newItem = FridgeItem(name: name, quantity: 1.0, section: section, isCustom: true)
            
            // Ensure the IDs match exactly
            if let entityId = entity.id {
                newItem.id = entityId
                print("✅ Created item with ID: \(entityId)")
            } else {
                print("❌ Failed to get entity ID for: \(name)")
            }
            
            self.fridgeItems.append(newItem)
            print("✅ Added \(name) to local array")
        }
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
        // Update local item immediately for instant UI response
        item.updateQuantity(quantity)
        print("🔄 Local item updated immediately: \(item.name) to \(Int(quantity * 100))%")
        
        // Trigger UI updates for computed properties that depend on item quantities
        objectWillChange.send()
    }
    
    func persistItemQuantity(_ item: FridgeItem) {
        print("💾 Persisting item quantity: \(item.name) at \(Int(item.quantity * 100))% (ID: \(item.id))")
        
        // Handle Core Data persistence asynchronously
        DispatchQueue.main.async {
            let entities = self.persistenceController.fetchFridgeItems()
            print("🔍 Searching among \(entities.count) Core Data entities")
            
            if let entity = entities.first(where: { $0.id == item.id }) {
                self.persistenceController.updateFridgeItem(entity, quantity: item.quantity)
                print("✅ Core Data persisted for: \(item.name) (Entity ID: \(entity.id?.uuidString ?? "nil"))")
            } else {
                print("❌ Core Data entity not found for: \(item.name) (Looking for ID: \(item.id))")
                print("📋 Available entity IDs: \(entities.compactMap { $0.id?.uuidString }.joined(separator: ", "))")
                
                // Try to find by name as fallback
                if let entity = entities.first(where: { $0.name == item.name }) {
                    print("🔄 Found entity by name, updating ID mapping")
                    item.id = entity.id ?? item.id
                    self.persistenceController.updateFridgeItem(entity, quantity: item.quantity)
                    print("✅ Core Data persisted using name fallback for: \(item.name)")
                }
            }
        }
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
        
        // Set state to generating and save
        shoppingState = .generating
        persistenceController.saveShoppingState(shoppingState)
        print("✅ Shopping list generation started with \(shoppingList.items.count) items")
    }
    
    func finalizeShoppingList() {
        print("📋 Finalizing shopping list...")
        shoppingState = .listReady
        persistenceController.saveShoppingState(shoppingState)
        print("✅ Shopping list finalized - now read-only")
    }
    
    func startShopping() {
        print("🛍️ Starting shopping trip...")
        shoppingState = .shopping
        persistenceController.saveShoppingState(shoppingState)
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
        persistenceController.saveShoppingState(shoppingState)
        
        print("✅ Shopping completed and inventory restored")
    }
    
    func cancelShopping() {
        print("❌ Cancelling shopping...")
        persistenceController.clearAllShoppingItems()
        shoppingList.items.removeAll()
        shoppingState = .empty
        persistenceController.saveShoppingState(shoppingState)
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
        
        print("➕ Adding temporary item: \(name)")
        
        DispatchQueue.main.async {
            let entity = self.persistenceController.createShoppingItem(name: name, isTemporary: true)
            let tempItem = ShoppingListItem(name: name, isTemporary: true)
            tempItem.id = entity.id ?? UUID()
            self.shoppingList.addItem(tempItem)
            print("✅ Temporary item added: \(name)")
            
            // Force UI update
            self.objectWillChange.send()
        }
    }
    
    func removeItemFromShoppingList(_ item: ShoppingListItem) {
        guard shoppingState == .generating else { return }
        
        print("➖ Removing item from shopping list: \(item.name)")
        
        DispatchQueue.main.async {
            // Delete from Core Data
            let entities = self.persistenceController.fetchShoppingItems()
            if let entity = entities.first(where: { $0.id == item.id }) {
                self.persistenceController.deleteShoppingItem(entity)
                print("✅ Core Data entity deleted for shopping item: \(item.name)")
            }
            
            // Remove from local list
            self.shoppingList.removeItem(item)
            print("✅ Local shopping item removed: \(item.name)")
            
            // Force UI update
            self.objectWillChange.send()
        }
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