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
        
        // Start with empty inventory - no automatic sample data creation
        print("📦 Loaded \(inventoryItems.count) items from storage")
        
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
        print("🗑️ Removing item: \(item.name) (ID: \(item.id))")
        
        // Use DispatchQueue to ensure proper UI updates
        DispatchQueue.main.async {
            // Find and delete the Core Data entity first
            let entities = self.persistenceController.fetchFridgeItems()
            print("🔍 Searching among \(entities.count) Core Data entities for deletion")
            
            if let entity = entities.first(where: { $0.id == item.id }) {
                print("✅ Found Core Data entity for deletion: \(entity.name ?? "Unknown") (ID: \(entity.id?.uuidString ?? "nil"))")
                self.persistenceController.deleteFridgeItem(entity)
                print("✅ Core Data entity deleted for: \(item.name)")
            } else {
                print("❌ Core Data entity not found for: \(item.name) (Looking for ID: \(item.id))")
                print("📋 Available entity IDs: \(entities.compactMap { $0.id?.uuidString }.joined(separator: ", "))")
                
                // Try to find by name as fallback
                if let entity = entities.first(where: { $0.name == item.name }) {
                    print("🔄 Found entity by name for deletion, proceeding")
                    self.persistenceController.deleteFridgeItem(entity)
                    print("✅ Core Data entity deleted using name fallback for: \(item.name)")
                }
            }
            
            // Remove from local array on main thread
            let beforeCount = self.inventoryItems.count
            self.inventoryItems.removeAll { $0.id == item.id }
            let afterCount = self.inventoryItems.count
            print("✅ Local item removed: \(item.name) (Items count: \(beforeCount) -> \(afterCount))")
            
            // Also remove any shopping list items that reference this inventory item
            self.removeFromShoppingListIfExists(item)
            
            // Force UI refresh
            self.objectWillChange.send()
            print("📱 UI refresh triggered after item deletion")
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
    
    func updateItemName(_ item: InventoryItem, newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        print("✏️ Updating item name: \(item.name) -> \(trimmedName) (ID: \(item.id))")
        
        DispatchQueue.main.async {
            // Update Core Data first
            let entities = self.persistenceController.fetchFridgeItems()
            print("🔍 Searching among \(entities.count) Core Data entities for name update")
            
            if let entity = entities.first(where: { $0.id == item.id }) {
                print("✅ Found Core Data entity for name update: \(entity.name ?? "Unknown") (ID: \(entity.id?.uuidString ?? "nil"))")
                self.persistenceController.updateFridgeItemName(entity, name: trimmedName)
                print("✅ Core Data updated for item name change: \(trimmedName)")
            } else {
                print("❌ Core Data entity not found for item name update: \(item.name) (Looking for ID: \(item.id))")
                print("📋 Available entity IDs: \(entities.compactMap { $0.id?.uuidString }.joined(separator: ", "))")
                
                // Try to find by name as fallback
                if let entity = entities.first(where: { $0.name == item.name }) {
                    print("🔄 Found entity by name for name update, updating ID mapping")
                    item.id = entity.id ?? item.id
                    self.persistenceController.updateFridgeItemName(entity, name: trimmedName)
                    print("✅ Core Data updated using name fallback for: \(trimmedName)")
                }
            }
            
            // Update local item after Core Data is updated
            item.name = trimmedName
            item.lastUpdated = Date()
            print("✅ Local item name updated: \(trimmedName)")
            
            // Update any shopping list items that reference this inventory item
            for shoppingItem in self.shoppingList.items {
                if shoppingItem.inventoryItem?.id == item.id {
                    shoppingItem.name = trimmedName
                    
                    // Update shopping item in Core Data
                    let shoppingEntities = self.persistenceController.fetchShoppingItems()
                    if let shoppingEntity = shoppingEntities.first(where: { $0.id == shoppingItem.id }) {
                        shoppingEntity.name = trimmedName
                        self.persistenceController.save()
                        print("✅ Shopping list item name updated: \(trimmedName)")
                    }
                }
            }
            
            // Force UI update
            self.objectWillChange.send()
            print("📱 UI refresh triggered after item name update")
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
        guard shoppingState == .generating || shoppingState == .shopping else { return }
        
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
    
    func addInventoryItemToShoppingList(_ item: InventoryItem, settingsManager: SettingsManager) {
        guard shoppingState == .shopping || shoppingState == .generating else { return }
        
        print("➕ Adding inventory item to shopping list: \(item.name)")
        
        DispatchQueue.main.async {
            let entity = self.persistenceController.createShoppingItem(name: item.name, fridgeItemId: item.id, isTemporary: false)
            let shoppingItem = ShoppingListItem(name: item.name, inventoryItem: item)
            shoppingItem.id = entity.id ?? UUID()
            self.shoppingList.addItem(shoppingItem)
            
            print("✅ Inventory item added to shopping list: \(item.name)")
            
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
    
    // MARK: - Computed Properties
    var allItems: [InventoryItem] {
        return inventoryItems
    }
    
    // MARK: - Analytics Properties
    var activeCategoriesCount: Int {
        let activeCategories = Set(inventoryItems.map { $0.category })
        return activeCategories.count
    }
    
    var mostFrequentlyRestockedItem: InventoryItem? {
        return inventoryItems.max { item1, item2 in
            item1.purchaseHistory.count < item2.purchaseHistory.count
        }
    }
    
    var leastUsedItem: InventoryItem? {
        return inventoryItems.min { item1, item2 in
            item1.lastUpdated < item2.lastUpdated
        }
    }
    
    func daysSinceLastUpdate(_ item: InventoryItem) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: item.lastUpdated, to: now)
        return components.day ?? 0
    }
    
    // MARK: - Time-based Alert Methods
    func getExpiryThreshold(for item: InventoryItem) -> Int {
        // Kitchen items: 14 days, Others: 60 days
        return item.category == .fridge ? 14 : 60
    }
    
    func isItemExpired(_ item: InventoryItem) -> Bool {
        let daysSince = daysSinceLastUpdate(item)
        let threshold = getExpiryThreshold(for: item)
        return daysSince >= threshold
    }
    
    func isItemNearExpiry(_ item: InventoryItem) -> Bool {
        let daysSince = daysSinceLastUpdate(item)
        let threshold = getExpiryThreshold(for: item)
        let warningThreshold = Int(Double(threshold) * 0.8) // 80% of threshold
        return daysSince >= warningThreshold && daysSince < threshold
    }
    
    var expiredItems: [InventoryItem] {
        return inventoryItems.filter { isItemExpired($0) }
    }
    
    var nearExpiryItems: [InventoryItem] {
        return inventoryItems.filter { isItemNearExpiry($0) }
    }
    
    var criticalKitchenItems: [InventoryItem] {
        return inventoryItems.filter { item in
            item.category == .fridge && daysSinceLastUpdate(item) >= 14
        }
    }
    
    var staleOtherItems: [InventoryItem] {
        return inventoryItems.filter { item in
            item.category != .fridge && daysSinceLastUpdate(item) >= 60
        }
    }
    
    var urgentAttentionItems: [InventoryItem] {
        return expiredItems + nearExpiryItems
    }
    
    var estimatedShoppingFrequency: String {
        let totalPurchases = inventoryItems.reduce(0) { $0 + $1.purchaseHistory.count }
        guard totalPurchases > 0 else { return "No data yet" }
        
        // Calculate average days between purchases
        let totalDays = inventoryItems.compactMap { item in
            guard item.purchaseHistory.count > 1 else { return nil }
            let sortedHistory = item.purchaseHistory.sorted()
            var totalDaysBetween = 0
            for i in 1..<sortedHistory.count {
                let days = Calendar.current.dateComponents([.day], from: sortedHistory[i-1], to: sortedHistory[i]).day ?? 0
                totalDaysBetween += days
            }
            return totalDaysBetween / (sortedHistory.count - 1)
        }.reduce(0, +)
        
        if totalDays == 0 {
            return "Weekly"
        }
        
        let avgDays = totalDays / inventoryItems.filter { $0.purchaseHistory.count > 1 }.count
        
        if avgDays <= 7 {
            return "Weekly"
        } else if avgDays <= 14 {
            return "Bi-weekly"
        } else if avgDays <= 30 {
            return "Monthly"
        } else {
            return "Rarely"
        }
    }
    
    var estimatedNextShoppingTrip: String {
        let lowStockItems = inventoryItems.filter { $0.needsRestocking }
        let criticalItems = inventoryItems.filter { $0.quantity <= 0.1 }
        
        if criticalItems.count > 0 {
            return "Now (critical items)"
        } else if lowStockItems.count >= 5 {
            return "This week"
        } else if lowStockItems.count > 0 {
            return "Next week"
        } else {
            return "No rush"
        }
    }
    
    var shoppingEfficiencyTip: String {
        let categoryGroups = Dictionary(grouping: inventoryItems.filter { $0.needsRestocking }) { $0.category }
        let maxCategory = categoryGroups.max { $0.value.count < $1.value.count }
        
        if let category = maxCategory?.key, maxCategory?.value.count ?? 0 > 1 {
            return "Focus on \(category.rawValue) section"
        } else {
            return "Spread across categories"
        }
    }
    
    func getSmartRecommendations() -> [SmartRecommendation] {
        var recommendations: [SmartRecommendation] = []
        
        // HIGHEST PRIORITY: Expired Kitchen Items (14+ days)
        let expiredKitchenItems = criticalKitchenItems
        if !expiredKitchenItems.isEmpty {
            recommendations.append(SmartRecommendation(
                title: "🚨 URGENT: Kitchen Items Expired",
                description: "\(expiredKitchenItems.count) kitchen items haven't been updated in 2+ weeks. Check for spoilage immediately!",
                icon: "exclamationmark.octagon.fill",
                color: .red,
                priority: .high
            ))
        }
        
        // HIGH PRIORITY: Expired Other Items (60+ days)
        let expiredOtherItems = staleOtherItems
        if !expiredOtherItems.isEmpty {
            recommendations.append(SmartRecommendation(
                title: "⚠️ Stale Items Alert",
                description: "\(expiredOtherItems.count) items haven't been updated in 2+ months. Time to review and update!",
                icon: "clock.badge.exclamationmark.fill",
                color: .orange,
                priority: .high
            ))
        }
        
        // MEDIUM PRIORITY: Near Expiry Items
        let nearExpiryItems = self.nearExpiryItems
        if !nearExpiryItems.isEmpty {
            recommendations.append(SmartRecommendation(
                title: "Items Need Attention Soon",
                description: "\(nearExpiryItems.count) items are approaching their update deadline. Check them this week.",
                icon: "clock.arrow.circlepath",
                color: .yellow,
                priority: .medium
            ))
        }
        
        // Critical stock recommendation
        let criticalItems = inventoryItems.filter { $0.quantity <= 0.1 }
        if !criticalItems.isEmpty {
            recommendations.append(SmartRecommendation(
                title: "Critical Stock Alert",
                description: "\(criticalItems.count) items are critically low (≤10%). Consider shopping soon.",
                icon: "exclamationmark.triangle.fill",
                color: .red,
                priority: .high
            ))
        }
        
        // Category balance recommendation
        let categoryDistribution = Dictionary(grouping: inventoryItems) { $0.category }
        let imbalancedCategories = categoryDistribution.filter { $0.value.count < 2 }
        if imbalancedCategories.count > 0 {
            recommendations.append(SmartRecommendation(
                title: "Expand Your Inventory",
                description: "Some categories have very few items. Consider adding more items for better tracking.",
                icon: "plus.circle.fill",
                color: .blue,
                priority: .low
            ))
        }
        
        // Shopping efficiency recommendation
        let lowStockByCategory = Dictionary(grouping: inventoryItems.filter { $0.needsRestocking }) { $0.category }
        if lowStockByCategory.count > 2 {
            recommendations.append(SmartRecommendation(
                title: "Optimize Shopping Route",
                description: "You have low stock items across \(lowStockByCategory.count) categories. Plan your store route efficiently.",
                icon: "map.fill",
                color: .green,
                priority: .medium
            ))
        }
        
        // Frequent restocking recommendation
        let frequentItems = inventoryItems.filter { $0.purchaseHistory.count > 5 }
        if !frequentItems.isEmpty {
            recommendations.append(SmartRecommendation(
                title: "Consider Bulk Buying",
                description: "\(frequentItems.count) items are restocked frequently. Consider buying in bulk to save trips.",
                icon: "cart.fill.badge.plus",
                color: .purple,
                priority: .low
            ))
        }
        
        // Default recommendation if no specific insights
        if recommendations.isEmpty {
            recommendations.append(SmartRecommendation(
                title: "Great Job!",
                description: "Your inventory is well-maintained. Keep tracking your items for better insights.",
                icon: "checkmark.seal.fill",
                color: .green,
                priority: .low
            ))
        }
        
        return recommendations.sorted { $0.priority == .high && $1.priority != .high }
    }
}