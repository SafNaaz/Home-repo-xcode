import SwiftUI

struct ShoppingListView: View {
    @EnvironmentObject var inventoryManager: InventoryManager
    
    var body: some View {
        NavigationView {
            VStack {
                switch inventoryManager.shoppingState {
                case .empty:
                    EmptyShoppingView()
                case .generating:
                    GeneratingShoppingView()
                case .listReady:
                    ReadyShoppingView()
                case .shopping:
                    ActiveShoppingView()
                }
            }
            .navigationTitle("Shopping")
        }
    }
}

// MARK: - Empty State
struct EmptyShoppingView: View {
    @EnvironmentObject var inventoryManager: InventoryManager
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "cart")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("Ready to Shop?")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Generate a shopping list based on items that need attention in your household inventory.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                Button(action: {
                    inventoryManager.startGeneratingShoppingList()
                }) {
                    HStack {
                        Image(systemName: "wand.and.rays")
                        Text("Generate Shopping List")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                if inventoryManager.lowStockItemsCount > 0 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("\(inventoryManager.lowStockItemsCount) items need attention")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Generating State
struct GeneratingShoppingView: View {
    @EnvironmentObject var inventoryManager: InventoryManager
    @State private var showingAddMiscItem = false
    @State private var miscItemName = ""
    @State private var showingItemsInfo = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact Header - Centered
            VStack(spacing: 8) {
                HStack {
                    Spacer()
                    
                    Text("Review Your Shopping List")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Button(action: {
                        showingItemsInfo = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            // Shopping List Items with Category Sections
            List {
                if !inventoryManager.shoppingList.items.isEmpty {
                    ForEach(InventoryCategory.allCases) { category in
                        let categoryItems = inventoryManager.shoppingList.items.filter { item in
                            item.category == category || (item.isTemporary && category == .grocery)
                        }
                        
                        if !categoryItems.isEmpty {
                            Section(header: CategorySectionHeader(category: category)) {
                                ForEach(categoryItems) { item in
                                    GeneratingItemRow(item: item)
                                }
                            }
                        }
                    }
                }
            }
            
            // Action Buttons - Side by Side
            HStack(spacing: 12) {
                Button(action: {
                    showingAddMiscItem = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add Misc")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    inventoryManager.finalizeShoppingList()
                }) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Continue")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(inventoryManager.shoppingList.items.isEmpty)
            }
            .padding()
        }
        .navigationBarItems(leading: Button("Cancel") {
            inventoryManager.cancelShopping()
        }
        .foregroundColor(.red))
        .sheet(isPresented: $showingAddMiscItem) {
            AddMiscItemView(itemName: $miscItemName) {
                if !miscItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    inventoryManager.addTemporaryItemToShoppingList(name: miscItemName.trimmingCharacters(in: .whitespacesAndNewlines))
                    miscItemName = ""
                }
                showingAddMiscItem = false
            }
        }
        .alert("Items Needing Attention", isPresented: $showingItemsInfo) {
            Button("OK") { }
        } message: {
            Text("Items with 25% or less stock are automatically added to your shopping list. You can remove items you don't need or add additional misc items.")
        }
    }
}

// MARK: - Ready State (Non-editable Checklist)
struct ReadyShoppingView: View {
    @EnvironmentObject var inventoryManager: InventoryManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact Header - Centered
            VStack(spacing: 8) {
                Text("Shopping Checklist Ready")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            
            // Read-only Checklist with Category Sections
            List {
                ForEach(InventoryCategory.allCases) { category in
                    let categoryItems = inventoryManager.shoppingList.items.filter { item in
                        item.category == category || (item.isTemporary && category == .grocery)
                    }
                    
                    if !categoryItems.isEmpty {
                        Section(header: CategorySectionHeader(category: category)) {
                            ForEach(categoryItems) { item in
                                ReadOnlyItemRow(item: item)
                            }
                        }
                    }
                }
            }
            
            // Action Buttons - Side by Side
            HStack(spacing: 12) {
                Button(action: {
                    inventoryManager.cancelShopping()
                }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    inventoryManager.startShopping()
                }) {
                    HStack {
                        Image(systemName: "cart.fill")
                        Text("Start Shopping")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
    }
}

// MARK: - Active Shopping State
struct ActiveShoppingView: View {
    @EnvironmentObject var inventoryManager: InventoryManager
    @State private var showingCompleteAlert = false
    @State private var refreshTrigger = UUID()
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact Header with Progress - Centered
            VStack(spacing: 8) {
                HStack {
                    // Progress indicator
                    let checkedCount = inventoryManager.shoppingList.checkedItems.count
                    let totalCount = inventoryManager.shoppingList.items.count
                    
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("\(checkedCount)/\(totalCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    Text("Shopping in Progress")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Invisible spacer to balance the layout
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.clear)
                            .font(.caption)
                        Text("0/0")
                            .font(.caption)
                            .foregroundColor(.clear)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .id(refreshTrigger)
            .onReceive(inventoryManager.shoppingList.objectWillChange) { _ in
                refreshTrigger = UUID()
            }
            
            // Active Checklist with Category Sections
            List {
                ForEach(InventoryCategory.allCases) { category in
                    let categoryItems = inventoryManager.shoppingList.items.filter { item in
                        item.category == category || (item.isTemporary && category == .grocery)
                    }
                    
                    if !categoryItems.isEmpty {
                        Section(header: CategorySectionHeader(category: category)) {
                            ForEach(categoryItems) { item in
                                SimpleActiveItemRow(item: item)
                            }
                        }
                    }
                }
            }
            
            // Completion Button
            Button(action: {
                showingCompleteAlert = true
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Complete Shopping")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
        .alert("Complete Shopping Trip", isPresented: $showingCompleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Complete & Restore") {
                inventoryManager.completeAndRestoreShopping()
            }
        } message: {
            let checkedCount = inventoryManager.shoppingList.checkedItems.count
            let restorableCount = inventoryManager.shoppingList.checkedItems.filter { !$0.isTemporary }.count
            
            if restorableCount > 0 && checkedCount > restorableCount {
                Text("This will restore \(restorableCount) checked inventory items to 100% stock. Misc items will be cleared from the list.")
            } else if restorableCount > 0 {
                Text("This will restore \(restorableCount) checked items to 100% stock and clear the shopping list.")
            } else if checkedCount > 0 {
                Text("This will clear the checked misc items from the shopping list. No inventory will be restored.")
            } else {
                Text("This will clear the shopping list. No items will be restored to inventory.")
            }
        }
    }
}

// MARK: - Category Section Header
struct CategorySectionHeader: View {
    let category: InventoryCategory
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(category.color)
            Text(category.rawValue)
                .font(.headline)
                .foregroundColor(category.color)
        }
    }
}

// MARK: - Item Row Views
struct GeneratingItemRow: View {
    @ObservedObject var item: ShoppingListItem
    @EnvironmentObject var inventoryManager: InventoryManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                HStack {
                    if item.isTemporary {
                        Label("Misc Item", systemImage: "tag.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else if let inventoryItem = item.inventoryItem {
                        Label(inventoryItem.subcategory.rawValue, systemImage: inventoryItem.subcategory.icon)
                            .font(.caption)
                            .foregroundColor(inventoryItem.subcategory.color)
                        
                        Text("• \(inventoryItem.quantityPercentage)% left")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                inventoryManager.removeItemFromShoppingList(item)
            }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
            }
        }
        .padding(.vertical, 2)
    }
}

struct ReadOnlyItemRow: View {
    @ObservedObject var item: ShoppingListItem
    
    var body: some View {
        HStack {
            // No checkbox icon for read-only state
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                HStack {
                    if item.isTemporary {
                        Label("Misc Item", systemImage: "tag.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else if let inventoryItem = item.inventoryItem {
                        Label(inventoryItem.subcategory.rawValue, systemImage: inventoryItem.subcategory.icon)
                            .font(.caption)
                            .foregroundColor(inventoryItem.subcategory.color)
                        
                        Text("• \(inventoryItem.quantityPercentage)% left")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct ActiveItemRow: View {
    @ObservedObject var item: ShoppingListItem
    @EnvironmentObject var inventoryManager: InventoryManager
    
    var body: some View {
        HStack {
            Button(action: {
                print("🛒 User tapped checkbox for item: \(item.name), current state: \(item.isChecked), ID: \(item.id)")
                
                // Update Core Data
                let entities = PersistenceController.shared.fetchShoppingItems()
                print("🔍 Searching among \(entities.count) Core Data entities for ID: \(item.id)")
                
                if let entity = entities.first(where: { $0.id == item.id }) {
                    print("📦 Found Core Data entity for: \(item.name), persisting toggle...")
                    PersistenceController.shared.toggleShoppingItem(entity)
                } else {
                    print("❌ Core Data entity not found for: \(item.name) (ID: \(item.id))")
                    print("📋 Available entity IDs:")
                    for entity in entities {
                        print("   - \(entity.name ?? "Unknown"): \(entity.id?.uuidString ?? "nil")")
                    }
                    
                    // Try to find by name as fallback
                    if let entity = entities.first(where: { $0.name == item.name }) {
                        print("🔄 Found entity by name, updating ID mapping and persisting...")
                        item.id = entity.id ?? item.id
                        PersistenceController.shared.toggleShoppingItem(entity)
                    } else {
                        print("❌ No entity found by name either for: \(item.name)")
                    }
                }
                
                // Update local item
                print("🔄 Updating local item state for: \(item.name)")
                inventoryManager.shoppingList.toggleItem(item)
                print("✅ Local item updated: \(item.name), new state: \(item.isChecked)")
            }) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isChecked ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .strikethrough(item.isChecked)
                    .foregroundColor(item.isChecked ? .secondary : .primary)
                
                HStack {
                    if item.isTemporary {
                        Label("Misc Item", systemImage: "tag.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else if let inventoryItem = item.inventoryItem {
                        Label(inventoryItem.subcategory.rawValue, systemImage: inventoryItem.subcategory.icon)
                            .font(.caption)
                            .foregroundColor(inventoryItem.subcategory.color)
                        
                        Text("• \(inventoryItem.quantityPercentage)% left")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Add Misc Item View
struct AddMiscItemView: View {
    @Binding var itemName: String
    let onAdd: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with consistent grey background
                VStack(spacing: 12) {
                    Text("Add Misc Item")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Add items that aren't tracked in your household inventory.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Content area
                VStack(spacing: 20) {
                    TextField("Item name (e.g., Cleaning supplies)", text: $itemName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Add Misc Item")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    onAdd()
                }
                .disabled(itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
}

// MARK: - Simplified Active Item Row (for final checklist)
struct SimpleActiveItemRow: View {
    @ObservedObject var item: ShoppingListItem
    @EnvironmentObject var inventoryManager: InventoryManager
    
    var body: some View {
        HStack {
            Button(action: {
                // Update Core Data
                let entities = PersistenceController.shared.fetchShoppingItems()
                
                if let entity = entities.first(where: { $0.id == item.id }) {
                    PersistenceController.shared.toggleShoppingItem(entity)
                } else {
                    // Try to find by name as fallback
                    if let entity = entities.first(where: { $0.name == item.name }) {
                        item.id = entity.id ?? item.id
                        PersistenceController.shared.toggleShoppingItem(entity)
                    }
                }
                
                // Update local item
                inventoryManager.shoppingList.toggleItem(item)
            }) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isChecked ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(item.name)
                .font(.body)
                .strikethrough(item.isChecked)
                .foregroundColor(item.isChecked ? .secondary : .primary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ShoppingListView()
        .environmentObject(InventoryManager())
}