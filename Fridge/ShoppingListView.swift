import SwiftUI

struct ShoppingListView: View {
    @EnvironmentObject var fridgeManager: FridgeManager
    @State private var showingAddTempItem = false
    @State private var tempItemName = ""
    @State private var showingCompletionAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                if fridgeManager.shoppingList.items.isEmpty {
                    EmptyShoppingListView()
                } else {
                    List {
                        // Unchecked Items Section
                        if !fridgeManager.shoppingList.uncheckedItems.isEmpty {
                            Section("To Buy") {
                                ForEach(fridgeManager.shoppingList.uncheckedItems) { item in
                                    ShoppingItemRow(item: item)
                                }
                                .onDelete(perform: deleteUncheckedItems)
                            }
                        }
                        
                        // Checked Items Section
                        if !fridgeManager.shoppingList.checkedItems.isEmpty {
                            Section("Purchased") {
                                ForEach(fridgeManager.shoppingList.checkedItems) { item in
                                    ShoppingItemRow(item: item)
                                }
                                .onDelete(perform: deleteCheckedItems)
                            }
                        }
                    }
                    
                    // Complete Shopping Button
                    if !fridgeManager.shoppingList.checkedItems.isEmpty {
                        Button(action: {
                            showingCompletionAlert = true
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Complete Shopping Trip")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Add Misc") {
                        showingAddTempItem = true
                    }
                    
                    if fridgeManager.shoppingList.items.isEmpty {
                        Button("Generate") {
                            print("🔄 Toolbar Generate button tapped")
                            fridgeManager.generateShoppingList()
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddTempItem) {
                AddTempItemView(tempItemName: $tempItemName) {
                    if !tempItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        fridgeManager.addTemporaryItemToShoppingList(name: tempItemName.trimmingCharacters(in: .whitespacesAndNewlines))
                        tempItemName = ""
                    }
                    showingAddTempItem = false
                }
            }
            .alert("Complete Shopping Trip", isPresented: $showingCompletionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Complete") {
                    fridgeManager.completeShoppingTrip()
                }
            } message: {
                Text("This will restore all checked items to 100% stock and clear the shopping list.")
            }
        }
    }
    
    private func deleteUncheckedItems(offsets: IndexSet) {
        let uncheckedItems = fridgeManager.shoppingList.uncheckedItems
        for index in offsets {
            fridgeManager.shoppingList.removeItem(uncheckedItems[index])
        }
    }
    
    private func deleteCheckedItems(offsets: IndexSet) {
        let checkedItems = fridgeManager.shoppingList.checkedItems
        for index in offsets {
            fridgeManager.shoppingList.removeItem(checkedItems[index])
        }
    }
}

struct ShoppingItemRow: View {
    @ObservedObject var item: ShoppingListItem
    @EnvironmentObject var fridgeManager: FridgeManager
    
    var body: some View {
        HStack {
            Button(action: {
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
                        
                        if fridgeItem.needsRestocking {
                            Label("Low Stock", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            Spacer()
            
            if !item.isTemporary, let fridgeItem = item.fridgeItem {
                Text("\(fridgeItem.quantityPercentage)%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyShoppingListView: View {
    @EnvironmentObject var fridgeManager: FridgeManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Shopping List is Empty")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Generate a shopping list based on low stock items or add temporary items manually.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button(action: {
                    fridgeManager.generateShoppingList()
                }) {
                    HStack {
                        Image(systemName: "wand.and.rays")
                        Text("Generate Shopping List")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                if fridgeManager.lowStockItemsCount > 0 {
                    Text("\(fridgeManager.lowStockItemsCount) items need restocking")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct AddTempItemView: View {
    @Binding var tempItemName: String
    let onAdd: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add Temporary Item")
                    .font(.headline)
                    .padding()
                
                Text("This item will be added to your shopping list but won't update your fridge inventory.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("Item name (e.g., Cleaning supplies)", text: $tempItemName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Add Misc Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onAdd()
                    }
                    .disabled(tempItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    ShoppingListView()
        .environmentObject(FridgeManager())
}