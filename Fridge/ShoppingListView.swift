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
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingAddMiscItem = false
    @State private var miscItemNames: [String] = [""]
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
                    // Regular category items
                    ForEach(InventoryCategory.allCases) { category in
                        let categoryItems = inventoryManager.shoppingList.items.filter { item in
                            item.category == category && !item.isTemporary
                        }
                        
                        if !categoryItems.isEmpty {
                            Section(header: CategorySectionHeader(category: category, items: categoryItems)) {
                                ForEach(categoryItems) { item in
                                    GeneratingItemRow(item: item)
                                }
                            }
                        }
                    }
                    
                    // Misc items section
                    let miscItems = inventoryManager.shoppingList.items.filter { $0.isTemporary }
                    if !miscItems.isEmpty {
                        Section(header: MiscSectionHeader(items: miscItems)) {
                            ForEach(miscItems) { item in
                                GeneratingItemRow(item: item)
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
            AddMiscItemView(itemNames: $miscItemNames) {
                // Add all non-empty misc items
                for itemName in miscItemNames {
                    let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedName.isEmpty {
                        inventoryManager.addTemporaryItemToShoppingList(name: trimmedName, settingsManager: settingsManager)
                        // Add to history for future suggestions
                        settingsManager.addMiscItemToHistory(trimmedName)
                    }
                }
                // Reset to single empty field
                miscItemNames = [""]
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
                // Regular category items
                ForEach(InventoryCategory.allCases) { category in
                    let categoryItems = inventoryManager.shoppingList.items.filter { item in
                        item.category == category && !item.isTemporary
                    }
                    
                    if !categoryItems.isEmpty {
                        Section(header: CategorySectionHeader(category: category, items: categoryItems)) {
                            ForEach(categoryItems) { item in
                                ReadOnlyItemRow(item: item)
                            }
                        }
                    }
                }
                
                // Misc items section
                let miscItems = inventoryManager.shoppingList.items.filter { $0.isTemporary }
                if !miscItems.isEmpty {
                    Section(header: MiscSectionHeader(items: miscItems)) {
                        ForEach(miscItems) { item in
                            ReadOnlyItemRow(item: item)
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
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingCompleteAlert = false
    @State private var showingPlanChangeOptions = false
    @State private var showingAddMiscItem = false
    @State private var showingInventorySearch = false
    @State private var miscItemNames: [String] = [""]
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
                // Regular category items
                ForEach(InventoryCategory.allCases) { category in
                    let categoryItems = inventoryManager.shoppingList.items.filter { item in
                        item.category == category && !item.isTemporary
                    }
                    
                    if !categoryItems.isEmpty {
                        Section(header: CategorySectionHeader(category: category, items: categoryItems)) {
                            ForEach(categoryItems) { item in
                                SimpleActiveItemRow(item: item)
                            }
                        }
                    }
                }
                
                // Misc items section
                let miscItems = inventoryManager.shoppingList.items.filter { $0.isTemporary }
                if !miscItems.isEmpty {
                    Section(header: MiscSectionHeader(items: miscItems)) {
                        ForEach(miscItems) { item in
                            SimpleActiveItemRow(item: item)
                        }
                    }
                }
            }
            
            // Plan Change and Complete Shopping Buttons (Equal size)
            HStack(spacing: 12) {
                // Plan Change Button (50%)
                Button(action: {
                    showingPlanChangeOptions = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "cart.badge.plus")
                            .font(.title2)
                        Text("Plan Change")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .frame(maxWidth: .infinity)
                
                // Complete Shopping Button (50%)
                Button(action: {
                    showingCompleteAlert = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                        Text("Complete Shopping")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .frame(maxWidth: .infinity)
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
        .actionSheet(isPresented: $showingPlanChangeOptions) {
            ActionSheet(
                title: Text("Plan Change Options"),
                message: Text("Choose how you want to add items to your shopping list"),
                buttons: [
                    .default(Text("Add Misc Items")) {
                        showingAddMiscItem = true
                    },
                    .default(Text("Search Inventory")) {
                        showingInventorySearch = true
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showingAddMiscItem) {
            AddMiscItemView(itemNames: $miscItemNames) {
                // Add all non-empty misc items
                for itemName in miscItemNames {
                    let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedName.isEmpty {
                        inventoryManager.addTemporaryItemToShoppingList(name: trimmedName, settingsManager: settingsManager)
                        // Add to history for future suggestions
                        settingsManager.addMiscItemToHistory(trimmedName)
                    }
                }
                // Reset to single empty field
                miscItemNames = [""]
                showingAddMiscItem = false
            }
        }
        .sheet(isPresented: $showingInventorySearch) {
            InventorySearchView { selectedItems in
                // Add all selected inventory items to shopping list
                for item in selectedItems {
                    inventoryManager.addInventoryItemToShoppingList(item, settingsManager: settingsManager)
                }
                showingInventorySearch = false
            }
        }
    }
}

// MARK: - Category Section Header
struct CategorySectionHeader: View {
    let category: InventoryCategory
    let items: [ShoppingListItem]
    @EnvironmentObject var inventoryManager: InventoryManager
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(category.color)
            Text(category.rawValue)
                .font(.headline)
                .foregroundColor(category.color)
            
            Spacer()
            
            // Show count/total for active shopping
            if inventoryManager.shoppingState == .shopping {
                let checkedCount = items.filter { $0.isChecked }.count
                let totalCount = items.count
                
                Text("\(checkedCount)/\(totalCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Misc Section Header
struct MiscSectionHeader: View {
    let items: [ShoppingListItem]
    @EnvironmentObject var inventoryManager: InventoryManager
    
    var body: some View {
        HStack {
            Image(systemName: "tag.fill")
                .foregroundColor(.orange)
            Text("Misc Items")
                .font(.headline)
                .foregroundColor(.orange)
            
            Spacer()
            
            // Show count/total for active shopping
            if inventoryManager.shoppingState == .shopping {
                let checkedCount = items.filter { $0.isChecked }.count
                let totalCount = items.count
                
                Text("\(checkedCount)/\(totalCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
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
    @Binding var itemNames: [String]
    let onAdd: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var settingsManager: SettingsManager
    @FocusState private var focusedField: Int?
    
    var hasValidItems: Bool {
        itemNames.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    var suggestions: [String] {
        Array(settingsManager.getMiscItemSuggestions().prefix(5))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with full background
                VStack(spacing: 12) {
                    Text("Add Misc Items")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Add items that aren't tracked in your household inventory")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Add up to 5 items at once")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                
                // Content area with full background
                ScrollView {
                    VStack(spacing: 16) {
                        // Suggestions section (if available)
                        if !suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.orange)
                                    Text("Suggestions from your history")
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                }
                                .padding(.horizontal)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 8) {
                                    ForEach(suggestions, id: \.self) { suggestion in
                                        Button(action: {
                                            addSuggestion(suggestion)
                                        }) {
                                            Text(suggestion)
                                                .font(.subheadline)
                                                .lineLimit(1)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 6)
                                                .background(Color.blue.opacity(0.1))
                                                .foregroundColor(.blue)
                                                .cornerRadius(12)
                                                .frame(maxWidth: .infinity)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.bottom, 8)
                        }
                        
                        // Input fields
                        ForEach(0..<itemNames.count, id: \.self) { index in
                            if index < itemNames.count {
                                HStack {
                                    Text("\(index + 1).")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                        .frame(width: 25, alignment: .leading)
                                    
                                    TextField("Enter item name", text: Binding(
                                        get: { index < itemNames.count ? itemNames[index] : "" },
                                        set: { newValue in
                                            if index < itemNames.count {
                                                itemNames[index] = newValue
                                            }
                                        }
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .focused($focusedField, equals: index)
                                    .onSubmit {
                                        // Move to next field or add new one
                                        if index == itemNames.count - 1 && itemNames.count < 5 {
                                            addNewField()
                                        } else if index < itemNames.count - 1 {
                                            focusedField = index + 1
                                        }
                                    }
                                    
                                    if itemNames.count > 1 {
                                        Button(action: {
                                            removeField(at: index)
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Add More button
                        if itemNames.count < 5 {
                            Button(action: addNewField) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add More")
                                }
                                .font(.headline)
                                .foregroundColor(.blue)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
            .navigationTitle("Add Misc Items")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    onAdd()
                }
                .disabled(!hasValidItems)
            )
        }
        .onAppear {
            // Auto-focus on first text field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = 0
            }
        }
    }
    
    private func addNewField() {
        if itemNames.count < 5 {
            itemNames.append("")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = itemNames.count - 1
            }
        }
    }
    
    private func removeField(at index: Int) {
        guard itemNames.count > 1 && index >= 0 && index < itemNames.count else { return }
        
        // Clear focus before removing to prevent issues
        focusedField = nil
        
        // Remove the item
        itemNames.remove(at: index)
        
        // Set focus to a safe index after removal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !self.itemNames.isEmpty {
                let newFocusIndex = min(index, self.itemNames.count - 1)
                self.focusedField = max(0, newFocusIndex)
            }
        }
    }
    
    private func addSuggestion(_ suggestion: String) {
        // Find first empty field or add new field
        if let emptyIndex = itemNames.firstIndex(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            itemNames[emptyIndex] = suggestion
            focusedField = emptyIndex
        } else if itemNames.count < 5 {
            itemNames.append(suggestion)
            focusedField = itemNames.count - 1
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

// MARK: - Add Plan Change Item View
struct AddPlanChangeItemView: View {
    @Binding var itemNames: [String]
    let onAdd: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var settingsManager: SettingsManager
    @FocusState private var focusedField: Int?
    
    var hasValidItems: Bool {
        itemNames.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    var suggestions: [String] {
        Array(settingsManager.getMiscItemSuggestions().prefix(5))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with full background
                VStack(spacing: 12) {
                    Text("Add Plan Change Items")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Add items you decided to buy while reviewing your shopping list")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Add up to 5 items at once")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                
                // Content area with full background
                ScrollView {
                    VStack(spacing: 16) {
                        // Suggestions section (if available)
                        if !suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.orange)
                                    Text("Suggestions from your history")
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                }
                                .padding(.horizontal)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 8) {
                                    ForEach(suggestions, id: \.self) { suggestion in
                                        Button(action: {
                                            addSuggestion(suggestion)
                                        }) {
                                            Text(suggestion)
                                                .font(.subheadline)
                                                .lineLimit(1)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 6)
                                                .background(Color.orange.opacity(0.1))
                                                .foregroundColor(.orange)
                                                .cornerRadius(12)
                                                .frame(maxWidth: .infinity)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.bottom, 8)
                        }
                        
                        // Input fields
                        ForEach(0..<itemNames.count, id: \.self) { index in
                            if index < itemNames.count {
                                HStack {
                                    Text("\(index + 1).")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                        .frame(width: 25, alignment: .leading)
                                    
                                    TextField("Enter item name", text: Binding(
                                        get: { index < itemNames.count ? itemNames[index] : "" },
                                        set: { newValue in
                                            if index < itemNames.count {
                                                itemNames[index] = newValue
                                            }
                                        }
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .focused($focusedField, equals: index)
                                    .onSubmit {
                                        // Move to next field or add new one
                                        if index == itemNames.count - 1 && itemNames.count < 5 {
                                            addNewField()
                                        } else if index < itemNames.count - 1 {
                                            focusedField = index + 1
                                        }
                                    }
                                    
                                    if itemNames.count > 1 {
                                        Button(action: {
                                            removeField(at: index)
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Add More button
                        if itemNames.count < 5 {
                            Button(action: addNewField) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add More")
                                }
                                .font(.headline)
                                .foregroundColor(.orange)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
            .navigationTitle("Plan Change Items")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    onAdd()
                }
                .disabled(!hasValidItems)
            )
        }
        .onAppear {
            // Auto-focus on first text field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = 0
            }
        }
    }
    
    private func addNewField() {
        if itemNames.count < 5 {
            itemNames.append("")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = itemNames.count - 1
            }
        }
    }
    
    private func removeField(at index: Int) {
        guard itemNames.count > 1 && index >= 0 && index < itemNames.count else { return }
        
        // Clear focus before removing to prevent issues
        focusedField = nil
        
        // Remove the item
        itemNames.remove(at: index)
        
        // Set focus to a safe index after removal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !self.itemNames.isEmpty {
                let newFocusIndex = min(index, self.itemNames.count - 1)
                self.focusedField = max(0, newFocusIndex)
            }
        }
    }
    
    private func addSuggestion(_ suggestion: String) {
        // Find first empty field or add new field
        if let emptyIndex = itemNames.firstIndex(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            itemNames[emptyIndex] = suggestion
            focusedField = emptyIndex
        } else if itemNames.count < 5 {
            itemNames.append(suggestion)
            focusedField = itemNames.count - 1
        }
    }
}

// MARK: - Inventory Search View
struct InventorySearchView: View {
    let onItemsSelected: ([InventoryItem]) -> Void
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var inventoryManager: InventoryManager
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var searchText = ""
    @State private var selectedItems: Set<UUID> = []
    
    var filteredItems: [InventoryItem] {
        let allItems = inventoryManager.allItems
        if searchText.isEmpty {
            return allItems
        } else {
            return allItems.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.subcategory.rawValue.localizedCaseInsensitiveContains(searchText) ||
                item.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var selectedItemsArray: [InventoryItem] {
        return filteredItems.filter { selectedItems.contains($0.id) }
    }
    
    private func isItemInShoppingList(_ item: InventoryItem) -> Bool {
        return inventoryManager.shoppingList.items.contains { shoppingItem in
            shoppingItem.inventoryItem?.id == item.id
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search
                VStack(spacing: 12) {
                    Text("Search Inventory")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select items from your household inventory to add to shopping list")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if !selectedItems.isEmpty {
                        Text("\(selectedItems.count) items selected")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                    
                    SearchBar(text: $searchText)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Items list
                List {
                    ForEach(InventoryCategory.allCases) { category in
                        let categoryItems = filteredItems.filter { $0.category == category }
                        
                        if !categoryItems.isEmpty {
                            Section(header: Text(category.rawValue)) {
                                ForEach(categoryItems) { item in
                                    MultiSelectInventoryItemRow(
                                        item: item,
                                        isSelected: selectedItems.contains(item.id),
                                        isInShoppingList: isItemInShoppingList(item)
                                    ) {
                                        if !isItemInShoppingList(item) {
                                            toggleSelection(for: item)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(GroupedListStyle())
            }
            .navigationTitle("Add from Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add (\(selectedItems.count))") {
                    let itemsToAdd = inventoryManager.allItems.filter { selectedItems.contains($0.id) }
                    for item in itemsToAdd {
                        inventoryManager.addInventoryItemToShoppingList(item, settingsManager: settingsManager)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(selectedItems.isEmpty)
            )
        }
    }
    
    private func toggleSelection(for item: InventoryItem) {
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
        } else {
            selectedItems.insert(item.id)
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search items...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Multi-Select Inventory Item Row
struct MultiSelectInventoryItemRow: View {
    let item: InventoryItem
    let isSelected: Bool
    let isInShoppingList: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Selection indicator
                if isInShoppingList {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                } else {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.name)
                            .font(.headline)
                            .foregroundColor(isInShoppingList ? .secondary : .primary)
                        
                        if isInShoppingList {
                            Text("(In List)")
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    HStack {
                        Label(item.subcategory.rawValue, systemImage: item.subcategory.icon)
                            .font(.caption)
                            .foregroundColor(isInShoppingList ? item.subcategory.color.opacity(0.6) : item.subcategory.color)
                        
                        Text("• \(item.quantityPercentage)% left")
                            .font(.caption)
                            .foregroundColor(isInShoppingList ? .secondary : (item.needsRestocking ? .red : .secondary))
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
            .opacity(isInShoppingList ? 0.6 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isInShoppingList)
    }
}

#Preview {
    ShoppingListView()
        .environmentObject(InventoryManager())
}