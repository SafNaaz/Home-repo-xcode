import CoreData
import Foundation

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Fridge")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
    
    // MARK: - Fridge Items
    func fetchFridgeItems() -> [FridgeItemEntity] {
        let request: NSFetchRequest<FridgeItemEntity> = FridgeItemEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FridgeItemEntity.name, ascending: true)]
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }
    
    func createFridgeItem(name: String, section: FridgeSection, quantity: Double = 1.0, isCustom: Bool = true) -> FridgeItemEntity {
        let context = container.viewContext
        let item = FridgeItemEntity(context: context)
        
        item.id = UUID()
        item.name = name
        item.section = section.rawValue
        item.quantity = quantity
        item.isCustom = isCustom
        item.lastUpdated = Date()
        item.purchaseHistory = []
        
        save()
        return item
    }
    
    func deleteFridgeItem(_ item: FridgeItemEntity) {
        container.viewContext.delete(item)
        save()
    }
    
    func updateFridgeItem(_ item: FridgeItemEntity, quantity: Double) {
        item.quantity = max(0.0, min(1.0, quantity))
        item.lastUpdated = Date()
        save()
    }
    
    func restockFridgeItem(_ item: FridgeItemEntity) {
        item.quantity = 1.0
        var history = item.purchaseHistory ?? []
        history.append(Date())
        item.purchaseHistory = history
        item.lastUpdated = Date()
        save()
    }
    
    // MARK: - Shopping Items
    func fetchShoppingItems() -> [ShoppingItemEntity] {
        let request: NSFetchRequest<ShoppingItemEntity> = ShoppingItemEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ShoppingItemEntity.name, ascending: true)]
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }
    
    func createShoppingItem(name: String, fridgeItemId: UUID? = nil, isTemporary: Bool = false) -> ShoppingItemEntity {
        let context = container.viewContext
        let item = ShoppingItemEntity(context: context)
        
        item.id = UUID()
        item.name = name
        item.fridgeItemId = fridgeItemId
        item.isTemporary = isTemporary
        item.isChecked = false
        
        save()
        return item
    }
    
    func deleteShoppingItem(_ item: ShoppingItemEntity) {
        container.viewContext.delete(item)
        save()
    }
    
    func toggleShoppingItem(_ item: ShoppingItemEntity) {
        item.isChecked.toggle()
        save()
    }
    
    func clearAllShoppingItems() {
        let request: NSFetchRequest<NSFetchRequestResult> = ShoppingItemEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try container.viewContext.execute(deleteRequest)
            save()
        } catch {
            print("Delete error: \(error)")
        }
    }
    
    // MARK: - Data Management
    func clearAllData() {
        // Clear fridge items
        let fridgeRequest: NSFetchRequest<NSFetchRequestResult> = FridgeItemEntity.fetchRequest()
        let deleteFridgeRequest = NSBatchDeleteRequest(fetchRequest: fridgeRequest)
        
        // Clear shopping items
        let shoppingRequest: NSFetchRequest<NSFetchRequestResult> = ShoppingItemEntity.fetchRequest()
        let deleteShoppingRequest = NSBatchDeleteRequest(fetchRequest: shoppingRequest)
        
        do {
            try container.viewContext.execute(deleteFridgeRequest)
            try container.viewContext.execute(deleteShoppingRequest)
            save()
        } catch {
            print("Clear all data error: \(error)")
        }
    }
}