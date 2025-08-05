import Foundation
import SwiftUI

// MARK: - Fridge Section Types
enum FridgeSection: String, CaseIterable, Identifiable {
    case doorBottles = "Door Bottles"
    case tray = "Tray Section"
    case main = "Main Section"
    case vegetable = "Vegetable Section"
    case freezer = "Freezer"
    case miniCooler = "Mini Cooler"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .doorBottles: return "waterbottle.fill"
        case .tray: return "tray.fill"
        case .main: return "refrigerator.fill"
        case .vegetable: return "carrot.fill"
        case .freezer: return "snowflake"
        case .miniCooler: return "cube.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .doorBottles: return .blue
        case .tray: return .orange
        case .main: return .green
        case .vegetable: return .mint
        case .freezer: return .cyan
        case .miniCooler: return .purple
        }
    }
}

// MARK: - Fridge Item Model
class FridgeItem: ObservableObject, Identifiable {
    @Published var id = UUID()
    @Published var name: String
    @Published var quantity: Double // 0.0 to 1.0 (0% to 100%)
    @Published var section: FridgeSection
    @Published var isCustom: Bool
    @Published var purchaseHistory: [Date]
    @Published var lastUpdated: Date
    
    init(name: String, quantity: Double = 1.0, section: FridgeSection, isCustom: Bool = false) {
        self.name = name
        self.quantity = max(0.0, min(1.0, quantity))
        self.section = section
        self.isCustom = isCustom
        self.purchaseHistory = []
        self.lastUpdated = Date()
    }
    
    var quantityPercentage: Int {
        Int(quantity * 100)
    }
    
    var needsRestocking: Bool {
        quantity <= 0.25
    }
    
    func updateQuantity(_ newQuantity: Double) {
        let oldNeedsRestocking = needsRestocking
        quantity = max(0.0, min(1.0, newQuantity))
        lastUpdated = Date()
        
        // Force UI update if restocking status changed
        if oldNeedsRestocking != needsRestocking {
            objectWillChange.send()
        }
    }
    
    func restockToFull() {
        quantity = 1.0
        purchaseHistory.append(Date())
        lastUpdated = Date()
    }
}

// MARK: - Shopping List Item
class ShoppingListItem: ObservableObject, Identifiable {
    @Published var id = UUID()
    @Published var name: String
    @Published var isChecked: Bool
    @Published var isTemporary: Bool // For misc items that don't update inventory
    @Published var fridgeItem: FridgeItem? // Reference to fridge item if not temporary
    
    init(name: String, isTemporary: Bool = false, fridgeItem: FridgeItem? = nil) {
        self.name = name
        self.isChecked = false
        self.isTemporary = isTemporary
        self.fridgeItem = fridgeItem
    }
}

// MARK: - Shopping List Model
class ShoppingList: ObservableObject {
    @Published var items: [ShoppingListItem] = []
    @Published var createdDate: Date = Date()
    
    func addItem(_ item: ShoppingListItem) {
        items.append(item)
    }
    
    func removeItem(_ item: ShoppingListItem) {
        items.removeAll { $0.id == item.id }
    }
    
    func toggleItem(_ item: ShoppingListItem) {
        let oldState = item.isChecked
        item.isChecked.toggle()
        let newState = item.isChecked
        print("🔄 ShoppingList.toggleItem: \(item.name) changed from \(oldState) to \(newState)")
        
        // Trigger UI update for observers of ShoppingList
        objectWillChange.send()
        print("📱 UI update triggered for ShoppingList")
    }
    
    func completeShoppingAndUpdateInventory() {
        for item in items where item.isChecked && !item.isTemporary {
            item.fridgeItem?.restockToFull()
        }
        items.removeAll()
    }
    
    var checkedItems: [ShoppingListItem] {
        items.filter { $0.isChecked }
    }
    
    var uncheckedItems: [ShoppingListItem] {
        items.filter { !$0.isChecked }
    }
}

// MARK: - Shopping Workflow States
enum ShoppingState {
    case empty           // No shopping list
    case generating      // Generating/editing list
    case listReady       // List created, not editable
    case shopping        // Shopping in progress, checklist unlocked
}

// MARK: - Default Items (Removed - User will add their own items)
// The app now starts with an empty database for users to populate with their own items