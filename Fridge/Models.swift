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
        case .doorBottles: return "bottle.fill"
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
    let id = UUID()
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
        quantity = max(0.0, min(1.0, newQuantity))
        lastUpdated = Date()
    }
    
    func restockToFull() {
        quantity = 1.0
        purchaseHistory.append(Date())
        lastUpdated = Date()
    }
}

// MARK: - Shopping List Item
class ShoppingListItem: ObservableObject, Identifiable {
    let id = UUID()
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
        item.isChecked.toggle()
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

// MARK: - Pre-populated Indian Household Items
struct DefaultItems {
    static let items: [String: FridgeSection] = [
        // Door Bottles
        "Coca Cola": .doorBottles,
        "Pepsi": .doorBottles,
        "Sprite": .doorBottles,
        "Fanta": .doorBottles,
        "Thumbs Up": .doorBottles,
        "Limca": .doorBottles,
        "Maaza": .doorBottles,
        "Frooti": .doorBottles,
        "Real Juice": .doorBottles,
        "Water Bottles": .doorBottles,
        
        // Tray Section
        "Milk": .tray,
        "Curd/Yogurt": .tray,
        "Paneer": .tray,
        "Butter": .tray,
        "Cheese": .tray,
        "Eggs": .tray,
        "Bread": .tray,
        
        // Main Section
        "Leftover Dal": .main,
        "Leftover Sabzi": .main,
        "Leftover Rice": .main,
        "Pickles": .main,
        "Ghee": .main,
        "Coconut Oil": .main,
        "Mustard Oil": .main,
        
        // Vegetable Section
        "Onions": .vegetable,
        "Potatoes": .vegetable,
        "Tomatoes": .vegetable,
        "Ginger": .vegetable,
        "Garlic": .vegetable,
        "Green Chilies": .vegetable,
        "Coriander Leaves": .vegetable,
        "Mint Leaves": .vegetable,
        "Curry Leaves": .vegetable,
        "Lemon": .vegetable,
        "Carrots": .vegetable,
        "Beans": .vegetable,
        "Cauliflower": .vegetable,
        "Cabbage": .vegetable,
        "Spinach": .vegetable,
        "Okra (Bhindi)": .vegetable,
        "Brinjal": .vegetable,
        "Capsicum": .vegetable,
        
        // Freezer
        "Chicken": .freezer,
        "Mutton": .freezer,
        "Fish": .freezer,
        "Prawns": .freezer,
        "Ice Cream": .freezer,
        "Frozen Peas": .freezer,
        "Frozen Corn": .freezer,
        
        // Mini Cooler
        "Rice Batter": .miniCooler,
        "Idli Batter": .miniCooler,
        "Dosa Batter": .miniCooler,
        "Coconut Chutney": .miniCooler,
        "Sambar": .miniCooler
    ]
    
    static func createDefaultFridgeItems() -> [FridgeItem] {
        return items.enumerated().map { index, item in
            let (name, section) = item
            // Make some items have low stock (25% or below) to demonstrate shopping list generation
            let quantity: Double
            if index % 3 == 0 { // Every 3rd item will have low stock (more items for better demo)
                quantity = Double.random(in: 0.05...0.25)
            } else if index % 5 == 0 { // Every 5th item will have medium-low stock
                quantity = Double.random(in: 0.20...0.30)
            } else {
                quantity = Double.random(in: 0.4...1.0)
            }
            
            let fridgeItem = FridgeItem(name: name, quantity: quantity, section: section)
            
            // Add some purchase history to frequently bought items
            if index % 4 == 0 { // Every 4th item gets purchase history
                let historyCount = Int.random(in: 2...6)
                for i in 0..<historyCount {
                    fridgeItem.purchaseHistory.append(Date().addingTimeInterval(-Double(i * 86400 * 7))) // Weekly purchases
                }
            }
            
            print("📦 Created item: \(name) with \(Int(quantity * 100))% stock, history: \(fridgeItem.purchaseHistory.count)")
            
            return fridgeItem
        }
    }
}