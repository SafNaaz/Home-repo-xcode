import Foundation
import SwiftUI

// MARK: - Inventory Categories
enum InventoryCategory: String, CaseIterable, Identifiable {
    case fridge = "Fridge"
    case grocery = "Grocery"
    case hygiene = "Hygiene"
    case personalCare = "Personal Care"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .fridge: return "refrigerator.fill"
        case .grocery: return "basket.fill"
        case .hygiene: return "bubbles.and.sparkles.fill"
        case .personalCare: return "figure.and.child.holdinghands"
        }
    }
    
    var color: Color {
        switch self {
        case .fridge: return .blue
        case .grocery: return .green
        case .hygiene: return .cyan
        case .personalCare: return .pink
        }
    }
    
    var subcategories: [InventorySubcategory] {
        switch self {
        case .fridge:
            return [.doorBottles, .tray, .main, .vegetable, .freezer, .miniCooler]
        case .grocery:
            return [.rice, .pulses, .cereals, .condiments, .oils]
        case .hygiene:
            return [.washing, .dishwashing, .toiletCleaning, .kids, .generalCleaning]
        case .personalCare:
            return [.face, .body, .head]
        }
    }
}

// MARK: - Inventory Subcategories
enum InventorySubcategory: String, CaseIterable, Identifiable {
    // Fridge subcategories
    case doorBottles = "Door Bottles"
    case tray = "Tray Section"
    case main = "Main Section"
    case vegetable = "Vegetable Section"
    case freezer = "Freezer"
    case miniCooler = "Mini Cooler"
    
    // Grocery subcategories
    case rice = "Rice Items"
    case pulses = "Pulses"
    case cereals = "Cereals"
    case condiments = "Condiments"
    case oils = "Oils"
    
    // Hygiene subcategories
    case washing = "Washing"
    case dishwashing = "Dishwashing"
    case toiletCleaning = "Toilet Cleaning"
    case kids = "Kids"
    case generalCleaning = "General Cleaning"
    
    // Personal Care subcategories
    case face = "Face"
    case body = "Body"
    case head = "Head"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        // Fridge icons
        case .doorBottles: return "waterbottle.fill"
        case .tray: return "tray.fill"
        case .main: return "refrigerator.fill"
        case .vegetable: return "carrot.fill"
        case .freezer: return "snowflake"
        case .miniCooler: return "cube.fill"
        
        // Grocery icons
        case .rice: return "leaf.fill"
        case .pulses: return "circle.fill"
        case .cereals: return "oval.fill"
        case .condiments: return "drop.fill"
        case .oils: return "drop.triangle.fill"
        
        // Hygiene icons
        case .washing: return "tshirt.fill"
        case .dishwashing: return "fork.knife"
        case .toiletCleaning: return "toilet.fill"
        case .kids: return "figure.child"
        case .generalCleaning: return "sparkles"
        
        // Personal Care icons
        case .face: return "face.smiling.fill"
        case .body: return "figure.arms.open"
        case .head: return "head.profile.arrow.forward.and.visionpro"
        }
    }
    
    var color: Color {
        switch self {
        // Fridge colors
        case .doorBottles: return .blue
        case .tray: return .orange
        case .main: return .green
        case .vegetable: return .mint
        case .freezer: return .cyan
        case .miniCooler: return .purple
        
        // Grocery colors
        case .rice: return .brown
        case .pulses: return .yellow
        case .cereals: return .orange
        case .condiments: return .red
        case .oils: return .yellow
        
        // Hygiene colors
        case .washing: return .blue
        case .dishwashing: return .green
        case .toiletCleaning: return .cyan
        case .kids: return .pink
        case .generalCleaning: return .purple
        
        // Personal Care colors
        case .face: return .pink
        case .body: return .mint
        case .head: return .indigo
        }
    }
    
    var category: InventoryCategory {
        switch self {
        case .doorBottles, .tray, .main, .vegetable, .freezer, .miniCooler:
            return .fridge
        case .rice, .pulses, .cereals, .condiments, .oils:
            return .grocery
        case .washing, .dishwashing, .toiletCleaning, .kids, .generalCleaning:
            return .hygiene
        case .face, .body, .head:
            return .personalCare
        }
    }
    
    var sampleItems: [String] {
        switch self {
        // Fridge sample items
        case .doorBottles: return ["Water Bottles", "Juice", "Milk", "Soft Drinks"]
        case .tray: return ["Eggs", "Butter", "Cheese", "Yogurt"]
        case .main: return ["Leftovers", "Cooked Food", "Fruits", "Vegetables"]
        case .vegetable: return ["Onions", "Tomatoes", "Potatoes", "Leafy Greens"]
        case .freezer: return ["Ice Cream", "Frozen Vegetables", "Meat", "Ice Cubes"]
        case .miniCooler: return ["Cold Drinks", "Snacks", "Chocolates"]
        
        // Grocery sample items
        case .rice: return ["Basmati Rice", "Brown Rice", "Jasmine Rice", "Wild Rice"]
        case .pulses: return ["Lentils", "Chickpeas", "Black Beans", "Kidney Beans"]
        case .cereals: return ["Oats", "Cornflakes", "Wheat Flakes", "Muesli"]
        case .condiments: return ["Salt", "Sugar", "Spices", "Sauces"]
        case .oils: return ["Cooking Oil", "Olive Oil", "Coconut Oil", "Ghee"]
        
        // Hygiene sample items
        case .washing: return ["Detergent", "Fabric Softener", "Stain Remover"]
        case .dishwashing: return ["Dish Soap", "Dishwasher Tablets", "Sponges"]
        case .toiletCleaning: return ["Toilet Cleaner", "Toilet Paper", "Air Freshener"]
        case .kids: return ["Diapers", "Baby Wipes", "Baby Shampoo"]
        case .generalCleaning: return ["All-Purpose Cleaner", "Floor Cleaner", "Glass Cleaner"]
        
        // Personal Care sample items
        case .face: return ["CC Cream", "Powder", "Face Wash", "Moisturizer"]
        case .body: return ["Lotion", "Deodorant", "Bathing Soap", "Body Wash"]
        case .head: return ["Shampoo", "Conditioner", "Hair Oil", "Hair Gel"]
        }
    }
}

// MARK: - Inventory Item Model
class InventoryItem: ObservableObject, Identifiable {
    @Published var id = UUID()
    @Published var name: String
    @Published var quantity: Double // 0.0 to 1.0 (0% to 100%)
    @Published var subcategory: InventorySubcategory
    @Published var isCustom: Bool
    @Published var purchaseHistory: [Date]
    @Published var lastUpdated: Date
    
    init(name: String, quantity: Double = 1.0, subcategory: InventorySubcategory, isCustom: Bool = false) {
        self.name = name
        self.quantity = max(0.0, min(1.0, quantity))
        self.subcategory = subcategory
        self.isCustom = isCustom
        self.purchaseHistory = []
        self.lastUpdated = Date()
    }
    
    var category: InventoryCategory {
        return subcategory.category
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
    @Published var inventoryItem: InventoryItem? // Reference to inventory item if not temporary
    
    init(name: String, isTemporary: Bool = false, inventoryItem: InventoryItem? = nil) {
        self.name = name
        self.isChecked = false
        self.isTemporary = isTemporary
        self.inventoryItem = inventoryItem
    }
    
    var category: InventoryCategory? {
        return inventoryItem?.category
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
            item.inventoryItem?.restockToFull()
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

// MARK: - Default Items Helper
struct DefaultItemsHelper {
    static func createSampleItems() -> [InventoryItem] {
        var items: [InventoryItem] = []
        
        for subcategory in InventorySubcategory.allCases {
            for sampleItemName in subcategory.sampleItems {
                let item = InventoryItem(
                    name: sampleItemName,
                    quantity: Double.random(in: 0.2...1.0),
                    subcategory: subcategory,
                    isCustom: false
                )
                items.append(item)
            }
        }
        
        return items
    }
}