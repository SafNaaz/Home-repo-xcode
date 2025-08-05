import SwiftUI

struct ContentView: View {
    @EnvironmentObject var fridgeManager: FridgeManager
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var selectedTab = 0
    @State private var showingAuthenticationAlert = false
    
    var body: some View {
        Group {
            if settingsManager.isSecurityEnabled && !settingsManager.isAuthenticated {
                AuthenticationView()
            } else {
                TabView(selection: $selectedTab) {
                    FridgeView(selectedTab: $selectedTab)
                        .tabItem {
                            Image(systemName: "refrigerator.fill")
                            Text("Fridge")
                        }
                        .tag(0)
                    
                    ShoppingListView()
                        .tabItem {
                            Image(systemName: "cart.fill")
                            Text("Shopping")
                        }
                        .tag(1)
                    
                    StatsView()
                        .tabItem {
                            Image(systemName: "chart.bar.fill")
                            Text("Stats")
                        }
                        .tag(2)
                    
                    SettingsView()
                        .tabItem {
                            Image(systemName: "gearshape.fill")
                            Text("Settings")
                        }
                        .tag(3)
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
        .alert("Authentication Failed", isPresented: $showingAuthenticationAlert) {
            Button("Try Again") {
                settingsManager.checkAuthenticationIfNeeded { _ in }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please authenticate to access your fridge data.")
        }
    }
}

struct FridgeView: View {
    @EnvironmentObject var fridgeManager: FridgeManager
    @State private var showingAddItem = false
    @State private var selectedSection: FridgeSection = .main
    @State private var showingNewShoppingAlert = false
    @Binding var selectedTab: Int
    
    private func getShoppingStateMessage() -> String {
        switch fridgeManager.shoppingState {
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
        NavigationView {
            VStack(spacing: 0) {
                // Quick Stats Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(fridgeManager.totalItems)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Low Stock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(fridgeManager.lowStockItemsCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(fridgeManager.lowStockItemsCount > 0 ? .red : .green)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Fridge Sections
                List {
                    ForEach(FridgeSection.allCases) { section in
                        NavigationLink(destination: SectionDetailView(section: section)) {
                            SectionRowView(section: section)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("My Fridge")
            .navigationBarItems(trailing: DarkModeToggle())
            .overlay(
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            print("🪄 Floating wand tapped")
                            
                            // Check if there's already an active shopping flow
                            if fridgeManager.shoppingState != .empty {
                                print("⚠️ Shopping flow already active, showing confirmation")
                                showingNewShoppingAlert = true
                            } else {
                                print("✅ Starting new shopping list")
                                fridgeManager.startGeneratingShoppingList()
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
                    fridgeManager.cancelShopping()
                    fridgeManager.startGeneratingShoppingList()
                    selectedTab = 1
                }
            } message: {
                Text(getShoppingStateMessage())
            }
        }
    }
    
}

struct SectionRowView: View {
    let section: FridgeSection
    @EnvironmentObject var fridgeManager: FridgeManager
    
    var body: some View {
        HStack {
            Image(systemName: section.icon)
                .foregroundColor(section.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(section.rawValue)
                    .font(.headline)
                
                let items = fridgeManager.itemsForSection(section)
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
    }
}

struct SectionDetailView: View {
    let section: FridgeSection
    @EnvironmentObject var fridgeManager: FridgeManager
    @State private var showingAddItem = false
    @State private var newItemName = ""
    
    var body: some View {
        List {
            ForEach(fridgeManager.itemsForSection(section)) { item in
                ItemRowView(item: item)
            }
            .onDelete(perform: deleteItems)
        }
        .navigationTitle(section.rawValue)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarItems(trailing: Button("Add Item") {
            showingAddItem = true
        })
        .sheet(isPresented: $showingAddItem) {
            AddItemView(section: section, newItemName: $newItemName) {
                if !newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    fridgeManager.addCustomItem(name: newItemName.trimmingCharacters(in: .whitespacesAndNewlines), section: section)
                    newItemName = ""
                }
                showingAddItem = false
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        // Get a snapshot of items to avoid index issues
        let items = fridgeManager.itemsForSection(section)
        
        // Create array of items to delete based on offsets
        var itemsToDelete: [FridgeItem] = []
        for index in offsets {
            if index < items.count {
                itemsToDelete.append(items[index])
            }
        }
        
        // Delete items one by one with delay to prevent UI conflicts
        for (delayIndex, item) in itemsToDelete.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(delayIndex) * 0.1) {
                fridgeManager.removeItem(item)
            }
        }
    }
}

struct ItemRowView: View {
    @ObservedObject var item: FridgeItem
    @EnvironmentObject var fridgeManager: FridgeManager
    
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
                        fridgeManager.updateItemQuantity(item, quantity: newValue)
                    }
                ), in: 0...1, step: 0.05)
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
    let section: FridgeSection
    @Binding var newItemName: String
    let onAdd: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add New Item to \(section.rawValue)")
                    .font(.headline)
                    .padding()
                
                TextField("Item name", text: $newItemName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Spacer()
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
        .environmentObject(FridgeManager())
        .environmentObject(SettingsManager())
}