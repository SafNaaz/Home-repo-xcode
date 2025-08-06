import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var inventoryManager: InventoryManager
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingClearDataAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Appearance Section
                Section("Appearance") {
                    HStack {
                        Image(systemName: settingsManager.isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(settingsManager.isDarkMode ? .purple : .orange)
                            .frame(width: 25)
                        
                        Text("Dark Mode")
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { settingsManager.isDarkMode },
                            set: { _ in settingsManager.toggleDarkMode() }
                        ))
                    }
                }
                
                // Security Section
                Section("Security") {
                    HStack {
                        Image(systemName: settingsManager.isSecurityEnabled ? "lock.fill" : "lock.open.fill")
                            .foregroundColor(settingsManager.isSecurityEnabled ? .green : .red)
                            .frame(width: 25)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("App Lock")
                            Text("Require authentication to access the app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { settingsManager.isSecurityEnabled },
                            set: { _ in settingsManager.toggleSecurity() }
                        ))
                    }
                    .padding(.vertical, 4)
                }
                
                // Notifications Section
                Section("Notifications") {
                    HStack {
                        Image(systemName: settingsManager.isInventoryReminderEnabled ? "bell.fill" : "bell.slash.fill")
                            .foregroundColor(settingsManager.isInventoryReminderEnabled ? .blue : .gray)
                            .frame(width: 25)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Inventory Reminders")
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
                        
                        // Second reminder time
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.purple)
                                .frame(width: 25)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Second Reminder")
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
                
                // Data Management Section
                Section("Data Management") {
                    Button(action: {
                        showingClearDataAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                                .frame(width: 25)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Clear All Data")
                                    .foregroundColor(.red)
                                Text("Remove all items and shopping lists")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // App Info Section
                Section("App Information") {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .frame(width: 25)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Version")
                            Text("1.0.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Image(systemName: "house.fill")
                            .foregroundColor(.green)
                            .frame(width: 25)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total Items")
                            Text("\(inventoryManager.totalItems) items in inventory")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Settings")
        }
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                settingsManager.clearAllData(inventoryManager: inventoryManager)
            }
        } message: {
            Text("This will permanently delete all your household inventory items and shopping lists. This action cannot be undone.")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(InventoryManager())
        .environmentObject(SettingsManager())
}