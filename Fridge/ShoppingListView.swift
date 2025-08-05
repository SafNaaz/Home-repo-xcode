import SwiftUI

struct ShoppingListView: View {
    @EnvironmentObject var fridgeManager: FridgeManager
    
    var body: some View {
        NavigationView {
            VStack {
                switch fridgeManager.shoppingState {
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
    @EnvironmentObject var fridgeManager: FridgeManager
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "cart")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("Ready to Shop?")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Generate a shopping list based on items that need attention in your fridge.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                Button(action: {
                    fridgeManager.startGeneratingShoppingList()
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
                
                if fridgeManager.lowStockItemsCount > 0 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("\(fridgeManager.lowStockItemsCount) items need attention")
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
    @EnvironmentObject var fridgeManager: FridgeManager
    @State private var showingAddMiscItem = false
    @State private var miscItemName = ""
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background that extends to top
            Color(.systemGray6)
                .ignoresSafeArea(.all, edges: .top)
                .frame(height: 200) // Adjust height as needed
            
            VStack(spacing: 0) {
                // Header content with proper spacing
                VStack(spacing: 12) {
                    Text("Review Your Shopping List")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Items needing attention are listed below. Remove items you don't need or add misc items.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .padding(.top, 10) // Minimal top padding
                
                // Shopping List Items
                List {
                    if !fridgeManager.shoppingList.items.isEmpty {
                        Section("Items to Buy") {
                            ForEach(fridgeManager.shoppingList.items) { item in
                                GeneratingItemRow(item: item)
                            }
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showingAddMiscItem = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Misc Item")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        fridgeManager.finalizeShoppingList()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Next - Create Checklist")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(fridgeManager.shoppingList.items.isEmpty)
                }
                .padding()
            }
        }
        .navigationBarItems(leading: Button("Cancel") {
            fridgeManager.cancelShopping()
        }
        .foregroundColor(.red))
        .sheet(isPresented: $showingAddMiscItem) {
            AddMiscItemView(itemName: $miscItemName) {
                if !miscItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    fridgeManager.addTemporaryItemToShoppingList(name: miscItemName.trimmingCharacters(in: .whitespacesAndNewlines))
                    miscItemName = ""
                }
                showingAddMiscItem = false
            }
        }
    }
}

// MARK: - Ready State (Non-editable Checklist)
struct ReadyShoppingView: View {
    @EnvironmentObject var fridgeManager: FridgeManager
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background that extends to top
            Color(.systemGray6)
                .ignoresSafeArea(.all, edges: .top)
                .frame(height: 200) // Adjust height as needed
            
            VStack(spacing: 0) {
                // Header content with proper spacing
                VStack(spacing: 12) {
                    Text("Shopping Checklist Ready")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Your shopping list is ready. Start shopping to unlock the checklist.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .padding(.top, 10) // Minimal top padding
                
                // Read-only Checklist
                List {
                    Section("Shopping List (\(fridgeManager.shoppingList.items.count) items)") {
                        ForEach(fridgeManager.shoppingList.items) { item in
                            ReadOnlyItemRow(item: item)
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        fridgeManager.startShopping()
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
                    
                    Button(action: {
                        fridgeManager.cancelShopping()
                    }) {
                        Text("Cancel Shopping")
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Active Shopping State
struct ActiveShoppingView: View {
    @EnvironmentObject var fridgeManager: FridgeManager
    @State private var showingCompleteAlert = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background that extends to top
            Color(.systemGray6)
                .ignoresSafeArea(.all, edges: .top)
                .frame(height: 200) // Adjust height as needed
            
            VStack(spacing: 0) {
                // Header content with proper spacing
                VStack(spacing: 12) {
                    Text("Shopping in Progress")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Check off items as you shop. Complete when done.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .padding(.top, 10) // Minimal top padding
                
                // Active Checklist
                List {
                    Section("Shopping Checklist") {
                        ForEach(fridgeManager.shoppingList.items) { item in
                            ActiveItemRow(item: item)
                        }
                    }
                }
                
                // Completion Button
                VStack(spacing: 12) {
                    let checkedCount = fridgeManager.shoppingList.checkedItems.count
                    
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
                    
                    if checkedCount > 0 {
                        Text("\(checkedCount) items will be restored to 100%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                Text("Tap items to check them off as you shop")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text("Checked items will be automatically restocked to 100%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding()
            }
        }
        .alert("Complete Shopping Trip", isPresented: $showingCompleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Complete & Restore") {
                fridgeManager.completeAndRestoreShopping()
            }
        } message: {
            let checkedCount = fridgeManager.shoppingList.checkedItems.count
            Text("This will restore \(checkedCount) checked items to 100% stock and clear the shopping list.")
        }
    }
}

// MARK: - Item Row Views
struct GeneratingItemRow: View {
    @ObservedObject var item: ShoppingListItem
    @EnvironmentObject var fridgeManager: FridgeManager
    
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
                    } else if let fridgeItem = item.fridgeItem {
                        Label(fridgeItem.section.rawValue, systemImage: fridgeItem.section.icon)
                            .font(.caption)
                            .foregroundColor(fridgeItem.section.color)
                        
                        Text("• \(fridgeItem.quantityPercentage)% left")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                fridgeManager.removeItemFromShoppingList(item)
            }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
            }
        }
        .padding(.vertical, 4)
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
                    } else if let fridgeItem = item.fridgeItem {
                        Label(fridgeItem.section.rawValue, systemImage: fridgeItem.section.icon)
                            .font(.caption)
                            .foregroundColor(fridgeItem.section.color)
                        
                        Text("• \(fridgeItem.quantityPercentage)% left")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ActiveItemRow: View {
    @ObservedObject var item: ShoppingListItem
    @EnvironmentObject var fridgeManager: FridgeManager
    
    var body: some View {
        HStack {
            Button(action: {
                // Update Core Data
                let entities = PersistenceController.shared.fetchShoppingItems()
                if let entity = entities.first(where: { $0.id == item.id }) {
                    PersistenceController.shared.toggleShoppingItem(entity)
                }
                // Update local item
                fridgeManager.shoppingList.toggleItem(item)
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
                    } else if let fridgeItem = item.fridgeItem {
                        Label(fridgeItem.section.rawValue, systemImage: fridgeItem.section.icon)
                            .font(.caption)
                            .foregroundColor(fridgeItem.section.color)
                        
                        Text("• \(fridgeItem.quantityPercentage)% left")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
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
                    
                    Text("Add items that aren't tracked in your fridge inventory.")
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

#Preview {
    ShoppingListView()
        .environmentObject(FridgeManager())
}