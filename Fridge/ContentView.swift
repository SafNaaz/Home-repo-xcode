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
                    
                    InsightsView()
                        .tabItem {
                            Image(systemName: "chart.bar.fill")
                            Text("Insights")
                        }
                        .tag(2)
                    
                    NotesView()
                        .tabItem {
                            Image(systemName: "note.text")
                            Text("Notes")
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
                // Urgent Alerts Banner (if any)
                if !inventoryManager.urgentAttentionItems.isEmpty {
                    UrgentAlertsBanner(selectedTab: $selectedTab)
                }
                
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
                    HStack {
                        ReminderButton()
                        SettingsButton()
                        DarkModeToggle()
                    }
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
    @State private var newItemNames: [String] = [""]
    
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
            AddItemView(subcategory: subcategory, newItemNames: $newItemNames) {
                // Add all non-empty items
                for itemName in newItemNames {
                    let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedName.isEmpty {
                        inventoryManager.addCustomItem(name: trimmedName, subcategory: subcategory)
                    }
                }
                // Reset to single empty field
                newItemNames = [""]
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
    @State private var showingEditSheet = false
    @State private var editedName = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name)
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    editedName = item.name
                    showingEditSheet = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
                
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
        .sheet(isPresented: $showingEditSheet) {
            EditItemView(
                itemName: $editedName,
                onSave: {
                    inventoryManager.updateItemName(item, newName: editedName)
                    showingEditSheet = false
                },
                onCancel: {
                    showingEditSheet = false
                }
            )
        }
    }
}

struct AddItemView: View {
    let subcategory: InventorySubcategory
    @Binding var newItemNames: [String]
    let onAdd: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var focusedField: Int?
    
    var hasValidItems: Bool {
        newItemNames.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with full background
                VStack(spacing: 12) {
                    Text("Add New Items")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Adding to \(subcategory.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
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
                        ForEach(0..<newItemNames.count, id: \.self) { index in
                            if index < newItemNames.count {
                                HStack {
                                    Text("\(index + 1).")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                        .frame(width: 25, alignment: .leading)
                                    
                                    TextField("Enter item name", text: Binding(
                                        get: { index < newItemNames.count ? newItemNames[index] : "" },
                                        set: { newValue in
                                            if index < newItemNames.count {
                                                newItemNames[index] = newValue
                                            }
                                        }
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .focused($focusedField, equals: index)
                                    .onSubmit {
                                        // Move to next field or add new one
                                        if index == newItemNames.count - 1 && newItemNames.count < 5 {
                                            addNewField()
                                        } else if index < newItemNames.count - 1 {
                                            focusedField = index + 1
                                        }
                                    }
                                    
                                    if newItemNames.count > 1 {
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
                        if newItemNames.count < 5 {
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
            .navigationTitle("Add Items")
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
        if newItemNames.count < 5 {
            newItemNames.append("")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = newItemNames.count - 1
            }
        }
    }
    
    private func removeField(at index: Int) {
        guard newItemNames.count > 1 && index >= 0 && index < newItemNames.count else { return }
        
        // Clear focus before removing to prevent issues
        focusedField = nil
        
        // Remove the item
        newItemNames.remove(at: index)
        
        // Set focus to a safe index after removal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !self.newItemNames.isEmpty {
                let newFocusIndex = min(index, self.newItemNames.count - 1)
                self.focusedField = max(0, newFocusIndex)
            }
        }
    }
}

struct EditItemView: View {
    @Binding var itemName: String
    let onSave: () -> Void
    let onCancel: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text("Edit Item Name")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Update the name of this inventory item")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                
                VStack(spacing: 16) {
                    TextField("Item name", text: $itemName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            if !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onSave()
                            }
                        }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    onCancel()
                },
                trailing: Button("Save") {
                    onSave()
                }
                .disabled(itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
    }
}

struct NotificationsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                // Notifications Section
                Section("Inventory Reminders") {
                    HStack {
                        Image(systemName: settingsManager.isInventoryReminderEnabled ? "bell.fill" : "bell.slash.fill")
                            .foregroundColor(settingsManager.isInventoryReminderEnabled ? .blue : .gray)
                            .frame(width: 25)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable Reminders")
                            Text("Get reminded to update your inventory")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { settingsManager.isInventoryReminderEnabled },
                            set: { _ in settingsManager.toggleInventoryReminder() }
                        ))
                    }
                    .padding(.vertical, 4)
                    
                    if settingsManager.isInventoryReminderEnabled {
                        // First reminder time
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                                .frame(width: 25)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("First Reminder")
                                Text("Daily reminder time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            DatePicker("", selection: Binding(
                                get: { settingsManager.reminderTime1 },
                                set: { newTime in
                                    settingsManager.reminderTime1 = newTime
                                    settingsManager.updateReminderTimes()
                                }
                            ), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                        }
                        .padding(.vertical, 4)
                        
                        // Second reminder toggle
                        HStack {
                            Image(systemName: settingsManager.isSecondReminderEnabled ? "bell.fill" : "bell.slash.fill")
                                .foregroundColor(settingsManager.isSecondReminderEnabled ? .purple : .gray)
                                .frame(width: 25)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Second Reminder")
                                Text("Enable a second daily reminder")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { settingsManager.isSecondReminderEnabled },
                                set: { _ in
                                    settingsManager.isSecondReminderEnabled.toggle()
                                    settingsManager.updateReminderTimes()
                                    settingsManager.saveSettings()
                                }
                            ))
                        }
                        .padding(.vertical, 4)
                        
                        // Second reminder time (only if enabled)
                        if settingsManager.isSecondReminderEnabled {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.purple)
                                    .frame(width: 25)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Second Reminder Time")
                                    Text("Daily reminder time")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                DatePicker("", selection: Binding(
                                    get: { settingsManager.reminderTime2 },
                                    set: { newTime in
                                        settingsManager.reminderTime2 = newTime
                                        settingsManager.updateReminderTimes()
                                    }
                                ), displayedComponents: .hourAndMinute)
                                .labelsHidden()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct ReminderButton: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingNotifications = false
    
    var body: some View {
        Button(action: {
            showingNotifications = true
        }) {
            Image(systemName: settingsManager.isInventoryReminderEnabled ? "bell.fill" : "bell")
                .foregroundColor(settingsManager.isInventoryReminderEnabled ? .blue : .gray)
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView()
        }
    }
}

struct SettingsButton: View {
    @State private var showingSettings = false
    
    var body: some View {
        Button(action: {
            showingSettings = true
        }) {
            Image(systemName: "gearshape.fill")
                .foregroundColor(.gray)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
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

// MARK: - Urgent Alerts Banner
struct UrgentAlertsBanner: View {
    @EnvironmentObject var inventoryManager: InventoryManager
    @Binding var selectedTab: Int
    
    init(selectedTab: Binding<Int> = .constant(0)) {
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Critical Kitchen Items Alert
            if !inventoryManager.criticalKitchenItems.isEmpty {
                Button(action: {
                    selectedTab = 2 // Switch to Insights tab
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("🚨 URGENT: Kitchen Items Expired")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            
                            Text("\(inventoryManager.criticalKitchenItems.count) kitchen items need immediate attention (2+ weeks old)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Stale Other Items Alert
            if !inventoryManager.staleOtherItems.isEmpty {
                Button(action: {
                    selectedTab = 2 // Switch to Insights tab
                }) {
                    HStack {
                        Image(systemName: "clock.badge.exclamationmark.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("⚠️ Stale Items Alert")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                            
                            Text("\(inventoryManager.staleOtherItems.count) items haven't been updated in 2+ months")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Near Expiry Items Alert
            if !inventoryManager.nearExpiryItems.isEmpty {
                Button(action: {
                    selectedTab = 2 // Switch to Insights tab
                }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.yellow)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Items Need Attention Soon")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("\(inventoryManager.nearExpiryItems.count) items approaching update deadline")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

#Preview {
    ContentView()
        .environmentObject(InventoryManager())
        .environmentObject(SettingsManager())
        .environmentObject(NotesManager())
}