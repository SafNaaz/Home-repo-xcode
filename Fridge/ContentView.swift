import SwiftUI

struct ContentView: View {
    @EnvironmentObject var inventoryManager: InventoryManager
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var selectedTab = 0
    @State private var showingAuthenticationAlert = false
    
    var body: some View {
        Group {
            if settingsManager.isSecurityEnabled && !settingsManager.isAuthenticated {
                AuthenticationView()
            } else {
                TabView(selection: $selectedTab) {
                    InventoryView(selectedTab: $selectedTab)
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Home")
                        }
                        .tag(0)
                    
                    ShoppingListView()
                        .tabItem {
                            Image(systemName: "cart.fill")
                            Text("Shopping")
                        }
                        .tag(1)
                    
                    SettingsView()
                        .tabItem {
                            Image(systemName: "gearshape.fill")
                            Text("Settings")
                        }
                        .tag(2)
                }
                .accentColor(.blue)
            }
        }
        .onAppear {
            if settingsManager.isSecurityEnabled && !settingsManager.isAuthenticated {
                settingsManager.checkAuthenticationIfNeeded { success in
                    if !success {
                        showingAuthenticationAlert = true
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh data when app comes to foreground to ensure UI reflects persisted state
            inventoryManager.refreshData()
        }
        .alert("Authentication Failed", isPresented: $showingAuthenticationAlert) {
            Button("Try Again") {
                settingsManager.checkAuthenticationIfNeeded { _ in }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please authenticate to access your household inventory data.")
        }
    }
}

struct InventoryView: View {
    @EnvironmentObject var inventoryManager: InventoryManager
    @State private var showingNewShoppingAlert = false
    @State private var refreshTrigger = UUID()
    @State private var navigationPath = NavigationPath()
    @Binding var selectedTab: Int
    
    private func getShoppingStateMessage() -> String {
        switch inventoryManager.shoppingState {
        case .generating:
            return "You're currently creating a shopping list. Would you like to continue with it or start fresh?"
        case .listReady:
            return "You have a shopping list ready to go. Would you like to continue with it or create a new one?"
        case .shopping:
            return "You're currently shopping! Would you like to continue your current trip or start a new shopping list?"
        default:
            return "You have an active shopping session. Continue or start new?"
        }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Quick Stats Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(inventoryManager.totalItems)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Low Stock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(inventoryManager.lowStockItemsCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(inventoryManager.lowStockItemsCount > 0 ? .red : .green)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .id(refreshTrigger)
                .onReceive(inventoryManager.objectWillChange) { _ in
                    refreshTrigger = UUID()
                }
                
                // Category Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        ForEach(InventoryCategory.allCases) { category in
                            NavigationLink(value: category) {
                                CategoryCardView(category: category)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Household Inventory")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    DarkModeToggle()
                }
            }
            .navigationDestination(for: InventoryCategory.self) { category in
                CategoryDetailView(category: category)
            }
            .navigationDestination(for: InventorySubcategory.self) { subcategory in
                SubcategoryDetailView(subcategory: subcategory)
            }
            .overlay(
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            print("🪄 Floating wand tapped")
                            
                            // Check if there's already an active shopping flow
                            if inventoryManager.shoppingState != .empty {
                                print("⚠️ Shopping flow already active, showing confirmation")
                                showingNewShoppingAlert = true
                            } else {
                                print("✅ Starting new shopping list")
                                inventoryManager.startGeneratingShoppingList()
                                selectedTab = 1 // Switch to Shopping tab
                            }
                        }) {
                            Image(systemName: "wand.and.rays")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            )
            .alert("Start New Shopping Trip?", isPresented: $showingNewShoppingAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Continue Current", role: .cancel) {
                    // Just switch to shopping tab to continue current flow
                    selectedTab = 1
                }
                Button("Start New", role: .destructive) {
                    inventoryManager.cancelShopping()
                    inventoryManager.startGeneratingShoppingList()
                    selectedTab = 1
                }
            } message: {
                Text(getShoppingStateMessage())
            }
            .onChange(of: selectedTab) {
                // Reset navigation to root when home tab is selected
                if selectedTab == 0 {
                    navigationPath = NavigationPath()
                }
            }
        }
    }
}

struct CategoryCardView: View {
    let category: InventoryCategory
    @EnvironmentObject var inventoryManager: InventoryManager
    @State private var refreshTrigger = UUID()
    
    var body: some View {
        VStack(spacing: 16) {
            // Large Icon
            Image(systemName: category.icon)
                .font(.system(size: 50))
                .foregroundColor(category.color)
            
            // Category Name
            Text(category.rawValue)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Stats
            let items = inventoryManager.itemsForCategory(category)
            let lowStockCount = items.filter { $0.needsRestocking }.count
            
            VStack(spacing: 4) {
                Text("\(items.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if lowStockCount > 0 {
                    Text("\(lowStockCount) need restocking")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .id(refreshTrigger)
        .onReceive(inventoryManager.objectWillChange) { _ in
            refreshTrigger = UUID()
        }
    }
}

struct CategoryDetailView: View {
    let category: InventoryCategory
    @EnvironmentObject var inventoryManager: InventoryManager
    
    var body: some View {
        List {
            ForEach(category.subcategories) { subcategory in
                NavigationLink(value: subcategory) {
                    SubcategoryRowView(subcategory: subcategory)
                }
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct SubcategoryRowView: View {
    let subcategory: InventorySubcategory
    @EnvironmentObject var inventoryManager: InventoryManager
    @State private var refreshTrigger = UUID()
    
    var body: some View {
        HStack {
            Image(systemName: subcategory.icon)
                .foregroundColor(subcategory.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(subcategory.rawValue)
                    .font(.headline)
                
                let items = inventoryManager.itemsForSubcategory(subcategory)
                let lowStockCount = items.filter { $0.needsRestocking }.count
                
                Text("\(items.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if lowStockCount > 0 {
                    Text("\(lowStockCount) need restocking")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 8)
        .id(refreshTrigger)
        .onReceive(inventoryManager.objectWillChange) { _ in
            refreshTrigger = UUID()
        }
    }
}

struct SubcategoryDetailView: View {
    let subcategory: InventorySubcategory
    @EnvironmentObject var inventoryManager: InventoryManager
    @State private var showingAddItem = false
    @State private var newItemName = ""
    
    var body: some View {
        List {
            ForEach(inventoryManager.itemsForSubcategory(subcategory)) { item in
                ItemRowView(item: item)
            }
            .onDelete(perform: deleteItems)
        }
        .navigationTitle(subcategory.rawValue)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarItems(trailing: Button("Add Item") {
            showingAddItem = true
        })
        .sheet(isPresented: $showingAddItem) {
            AddItemView(subcategory: subcategory, newItemName: $newItemName) {
                if !newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    inventoryManager.addCustomItem(name: newItemName.trimmingCharacters(in: .whitespacesAndNewlines), subcategory: subcategory)
                    newItemName = ""
                }
                showingAddItem = false
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        // Get a snapshot of items to avoid index issues
        let items = inventoryManager.itemsForSubcategory(subcategory)
        
        // Create array of items to delete based on offsets
        var itemsToDelete: [InventoryItem] = []
        for index in offsets {
            if index < items.count {
                itemsToDelete.append(items[index])
            }
        }
        
        // Delete items one by one with delay to prevent UI conflicts
        for (delayIndex, item) in itemsToDelete.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(delayIndex) * 0.1) {
                inventoryManager.removeItem(item)
            }
        }
    }
}

struct ItemRowView: View {
    @ObservedObject var item: InventoryItem
    @EnvironmentObject var inventoryManager: InventoryManager
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name)
                    .font(.headline)
                
                Spacer()
                
                Text("\(item.quantityPercentage)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(item.needsRestocking ? .red : .primary)
            }
            
            HStack {
                Text("Stock Level")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Slider(value: Binding(
                    get: { item.quantity },
                    set: { newValue in
                        inventoryManager.updateItemQuantity(item, quantity: newValue)
                    }
                ), in: 0...1, step: 0.05, onEditingChanged: { editing in
                    isEditing = editing
                    if !editing {
                        // User finished editing, persist to database
                        inventoryManager.persistItemQuantity(item)
                    }
                })
                .accentColor(item.needsRestocking ? .red : .blue)
            }
            
            if item.needsRestocking {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Needs restocking")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddItemView: View {
    let subcategory: InventorySubcategory
    @Binding var newItemName: String
    let onAdd: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with consistent grey background
                VStack(spacing: 12) {
                    Text("Add New Item")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Adding to \(subcategory.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Content area
                VStack(spacing: 20) {
                    TextField("Item name", text: $newItemName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    onAdd()
                }
                .disabled(newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
}

struct DarkModeToggle: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        Button(action: {
            settingsManager.toggleDarkMode()
        }) {
            Image(systemName: settingsManager.isDarkMode ? "sun.max.fill" : "moon.fill")
                .foregroundColor(settingsManager.isDarkMode ? .orange : .purple)
        }
    }
}

struct AuthenticationView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 10) {
                Text("Fridge App Locked")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Please authenticate to access your fridge data")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                settingsManager.checkAuthenticationIfNeeded { success in
                    if !success {
                        showingError = true
                    }
                }
            }) {
                HStack {
                    Image(systemName: "faceid")
                    Text("Authenticate")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
        .alert("Authentication Failed", isPresented: $showingError) {
            Button("Try Again") {
                settingsManager.checkAuthenticationIfNeeded { _ in }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Unable to authenticate. Please try again.")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(InventoryManager())
        .environmentObject(SettingsManager())
}