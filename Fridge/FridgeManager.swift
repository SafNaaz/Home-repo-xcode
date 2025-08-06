import Foundation
import SwiftUI
import CoreData

class InventoryManager: ObservableObject {
    @Published var inventoryItems: [InventoryItem] = []
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
        
        inventoryItems = entities.compactMap { entity in
            guard let name = entity.name,
                  let sectionRaw = entity.section,
                  let subcategory = InventorySubcategory(rawValue: sectionRaw),
                  let entityId = entity.id else {
                print("❌ Invalid entity data, skipping")
                return nil
            }
            
            let item = InventoryItem(
                name: name,
                quantity: entity.quantity,
                subcategory: subcategory,
                isCustom: entity.isCustom
            )
            item.id = entityId
            item.purchaseHistory = entity.purchaseHistory ?? []
            item.lastUpdated = entity.lastUpdated ?? Date()
            print("📦 Loaded item: \(item.name) with \(item.quantityPercentage)% stock (ID: \(entityId))")
            return item
        }
        
        // If no items exist, create sample items
        if inventoryItems.isEmpty {
            print("📦 No items found, creating sample items...")
            let sampleItems = DefaultItemsHelper.createSampleItems()
            for item in sampleItems {
                let entity = persistenceController.createFridgeItem(
                    name: item.name,
                    section: item.subcategory,
                    quantity: item.quantity,
                    isCustom: item.isCustom
                )
                item.id = entity.id ?? item.id
                inventoryItems.append(item)
            }
            print("✅ Created \(inventoryItems.count) sample items")
        }
        
        loadShoppingList()
        
        // Load shopping state from Core Data
        shoppingState = persistenceController.fetchShoppingState()
        print("📱 Restored shopping state: \(shoppingState)")
    }
    
    func refreshData() {
        print("🔄 Refreshing all data...")
        loadData()
        
        // Force UI refresh for all components
        DispatchQueue.main.async {
            // Refresh individual shopping list items
            for item in self.shoppingList.items {
                item.objectWillChange.send()
            }
            
            // Refresh shopping list and manager
            self.shoppingList.objectWillChange.send()
            self.objectWillChange.send()
        }
    }
    
    private func loadShoppingList() {
        let entities = persistenceController.fetchShoppingItems()
        print("🛒 Loading \(entities.count) shopping items from Core Data")
        
        shoppingList.items = entities.map { entity in
            let item = ShoppingListItem(
                name: entity.name ?? "",
                isTemporary: entity.isTemporary,
                inventoryItem: inventoryItems.first { $0.id == entity.fridgeItemId }
            )
            item.id = entity.id ?? UUID()
            item.isChecked = entity.isChecked
            print("📦 Loaded shopping item: \(item.name), checked: \(item.isChecked), temporary: \(item.isTemporary), ID: \(item.id)")
            
            // Force UI update for each individual item
            DispatchQueue.main.async {
                item.objectWillChange.send()
            }
            
            return item
        }
        
        print("✅ Shopping list loaded with \(shoppingList.items.count) items, \(shoppingList.checkedItems.count) checked")
        
        // Trigger UI refresh to ensure checked states are displayed correctly
        DispatchQueue.main.async {
            self.shoppingList.objectWillChange.send()
            self.objectWillChange.send()
        }
    }
    
    private func saveData() {
        // Core Data saves automatically through PersistenceController
    }
    
    // MARK: - Inventory Items Management
    func itemsForCategory(_ category: InventoryCategory) -> [InventoryItem] {
        return inventoryItems.filter { $0.category == category }
    }
    
    func itemsForSubcategory(_ subcategory: InventorySubcategory) -> [InventoryItem] {
        return inventoryItems.filter { $0.subcategory == subcategory }
    }
    
    func addCustomItem(name: String, subcategory: InventorySubcategory) {
        print("➕ Adding custom item: \(name) to \(subcategory.rawValue)")
        
        DispatchQueue.main.async {
            let entity = self.persistenceController.createFridgeItem(name: name, section: subcategory, quantity: 0.0, isCustom: true)
            let newItem = InventoryItem(name: name, quantity: 0.0, subcategory: subcategory, isCustom: true)
            
            // Ensure the IDs match exactly
            if let entityId = entity.id {
                newItem.id = entityId
                print("✅ Created item with ID: \(entityId)")
            } else {
                print("❌ Failed to get entity ID for: \(name)")
            }
            
            self.inventoryItems.append(newItem)
            print("✅ Added \(name) to local array")
        }
    }
    
    func removeItem(_ item: InventoryItem) {
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
            self.inventoryItems.removeAll { $0.id == item.id }
            print("✅ Local item removed: \(item.name)")
            
            // Also remove any shopping list items that reference this inventory item
            self.removeFromShoppingListIfExists(item)
        }
    }
    
    private func removeFromShoppingListIfExists(_ inventoryItem: InventoryItem) {
        // Find shopping list items that reference this inventory item
        let itemsToRemove = shoppingList.items.filter { shoppingItem in
            shoppingItem.inventoryItem?.id == inventoryItem.id
        }
        
        if !itemsToRemove.isEmpty {
            print("🛒 Found \(itemsToRemove.count) shopping list items to remove for: \(inventoryItem.name)")
            
            for shoppingItem in itemsToRemove {
                // Delete from Core Data
                let entities = persistenceController.fetchShoppingItems()
                if let entity = entities.first(where: { $0.id == shoppingItem.id }) {
                    persistenceController.deleteShoppingItem(entity)
                    print("✅ Core Data shopping entity deleted for: \(shoppingItem.name)")
                }
                
                // Remove from local shopping list
                shoppingList.removeItem(shoppingItem)
                print("✅ Shopping list item removed: \(shoppingItem.name)")
            }
            
            // Check if shopping list is now empty and stop shopping flow if needed
            if shoppingList.items.isEmpty {
                print("🛑 Shopping list is now empty, stopping shopping flow")
                shoppingState = .empty
                persistenceController.saveShoppingState(shoppingState)
                print("✅ Shopping flow stopped due to empty list")
            }
            
            // Force UI update for shopping list
            shoppingList.objectWillChange.send()
            objectWillChange.send()
        }
    }
    
    func updateItemQuantity(_ item: InventoryItem, quantity: Double) {
        // Update local item immediately for instant UI response
        item.updateQuantity(quantity)
        print("🔄 Local item updated immediately: \(item.name) to \(Int(quantity * 100))%")
        
        // Trigger UI updates for computed properties that depend on item quantities
        objectWillChange.send()
    }
    
    func persistItemQuantity(_ item: InventoryItem) {
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
        let attentionItems = inventoryItems.filter { $0.needsRestocking }.sorted { $0.quantity < $1.quantity }
        print("⚠️ Attention items found: \(attentionItems.count)")
        
        for item in attentionItems {
            let entity = persistenceController.createShoppingItem(name: item.name, fridgeItemId: item.id, isTemporary: false)
            let shoppingItem = ShoppingListItem(name: item.name, inventoryItem: item)
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
        
        // Update inventory items that were purchased
        for item in shoppingList.items where item.isChecked && !item.isTemporary {
            if let inventoryItem = item.inventoryItem {
                let entities = persistenceController.fetchFridgeItems()
                if let entity = entities.first(where: { $0.id == inventoryItem.id }) {
                    persistenceController.restockFridgeItem(entity)
                }
                inventoryItem.restockToFull()
                print("🔄 Restored \(inventoryItem.name) to 100%")
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
    
    private func getFrequentlyPurchasedItems() -> [InventoryItem] {
        // Sort items by purchase frequency (number of times purchased)
        let sortedItems = inventoryItems.sorted { item1, item2 in
            item1.purchaseHistory.count > item2.purchaseHistory.count
        }
        
        // Return top 5 frequently purchased items that aren't already low stock
        return Array(sortedItems.filter { !$0.needsRestocking }.prefix(5))
    }
    
    func addTemporaryItemToShoppingList(name: String, settingsManager: SettingsManager) {
        guard shoppingState == .generating else { return }
        
        print("➕ Adding temporary item: \(name)")
        
        DispatchQueue.main.async {
            let entity = self.persistenceController.createShoppingItem(name: name, isTemporary: true)
            let tempItem = ShoppingListItem(name: name, isTemporary: true)
            tempItem.id = entity.id ?? UUID()
            self.shoppingList.addItem(tempItem)
            
            // Add to misc item history
            settingsManager.addMiscItemToHistory(name)
            
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
        inventoryItems.count
    }
    
    var lowStockItemsCount: Int {
        inventoryItems.filter { $0.needsRestocking }.count
    }
    
    var averageStockLevel: Double {
        guard !inventoryItems.isEmpty else { return 0 }
        let totalStock = inventoryItems.reduce(0) { $0 + $1.quantity }
        return totalStock / Double(inventoryItems.count)
    }
    
    func itemsNeedingAttention() -> [InventoryItem] {
        return inventoryItems.filter { $0.needsRestocking }.sorted { $0.quantity < $1.quantity }
    }
    
    // MARK: - Data Management
    func clearAllData() {
        persistenceController.clearAllData()
        inventoryItems.removeAll()
        shoppingList.items.removeAll()
    }
    
    func resetToDefaults() {
        // Clear all data and recreate sample items
        clearAllData()
        let sampleItems = DefaultItemsHelper.createSampleItems()
        for item in sampleItems {
            let entity = persistenceController.createFridgeItem(
                name: item.name,
                section: item.subcategory,
                quantity: item.quantity,
                isCustom: item.isCustom
            )
            item.id = entity.id ?? item.id
            inventoryItems.append(item)
        }
    }
}