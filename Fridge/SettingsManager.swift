import Foundation
import SwiftUI
import LocalAuthentication
import UserNotifications

class SettingsManager: ObservableObject {
    @Published var isDarkMode: Bool = false
    @Published var isSecurityEnabled: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var isInventoryReminderEnabled: Bool = false
    @Published var isSecondReminderEnabled: Bool = false
    @Published var reminderTime1: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @Published var reminderTime2: Date = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadSettings()
    }
    
    // MARK: - Settings Management
    private func loadSettings() {
        isDarkMode = userDefaults.bool(forKey: "isDarkMode")
        isSecurityEnabled = userDefaults.bool(forKey: "isSecurityEnabled")
        isInventoryReminderEnabled = userDefaults.bool(forKey: "isInventoryReminderEnabled")
        isSecondReminderEnabled = userDefaults.bool(forKey: "isSecondReminderEnabled")
        
        // Load reminder times
        if let time1Data = userDefaults.data(forKey: "reminderTime1"),
           let time1 = try? JSONDecoder().decode(Date.self, from: time1Data) {
            reminderTime1 = time1
        }
        
        if let time2Data = userDefaults.data(forKey: "reminderTime2"),
           let time2 = try? JSONDecoder().decode(Date.self, from: time2Data) {
            reminderTime2 = time2
        }
    }
    
    func saveSettings() {
        userDefaults.set(isDarkMode, forKey: "isDarkMode")
        userDefaults.set(isSecurityEnabled, forKey: "isSecurityEnabled")
        userDefaults.set(isInventoryReminderEnabled, forKey: "isInventoryReminderEnabled")
        userDefaults.set(isSecondReminderEnabled, forKey: "isSecondReminderEnabled")
        
        // Save reminder times
        if let time1Data = try? JSONEncoder().encode(reminderTime1) {
            userDefaults.set(time1Data, forKey: "reminderTime1")
        }
        
        if let time2Data = try? JSONEncoder().encode(reminderTime2) {
            userDefaults.set(time2Data, forKey: "reminderTime2")
        }
    }
    
    func toggleDarkMode() {
        isDarkMode.toggle()
        saveSettings()
    }
    
    func toggleSecurity() {
        if !isSecurityEnabled {
            // Enabling security - authenticate first
            authenticateUser { success in
                DispatchQueue.main.async {
                    if success {
                        self.isSecurityEnabled = true
                        self.isAuthenticated = true
                        self.saveSettings()
                    }
                }
            }
        } else {
            // Disabling security
            isSecurityEnabled = false
            isAuthenticated = false
            saveSettings()
        }
    }
    
    // MARK: - Biometric Authentication
    func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to access your household inventory data"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                completion(success)
            }
        } else {
            // Fallback to device passcode
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                let reason = "Authenticate with your device passcode to access your household inventory data"
                
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                    completion(success)
                }
            } else {
                completion(false)
            }
        }
    }
    
    func checkAuthenticationIfNeeded(completion: @escaping (Bool) -> Void) {
        if isSecurityEnabled && !isAuthenticated {
            authenticateUser { success in
                DispatchQueue.main.async {
                    self.isAuthenticated = success
                    completion(success)
                }
            }
        } else {
            completion(true)
        }
    }
    
    // MARK: - Inventory Reminders
    func toggleInventoryReminder() {
        isInventoryReminderEnabled.toggle()
        
        if isInventoryReminderEnabled {
            requestNotificationPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.scheduleInventoryReminders()
                        self.saveSettings()
                    } else {
                        self.isInventoryReminderEnabled = false
                    }
                }
            }
        } else {
            cancelInventoryReminders()
            saveSettings()
        }
    }
    
    func updateReminderTimes() {
        if isInventoryReminderEnabled {
            scheduleInventoryReminders()
        }
        saveSettings()
    }
    
    private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            completion(granted)
        }
    }
    
    private func scheduleInventoryReminders() {
        // Cancel existing notifications
        cancelInventoryReminders()
        
        // Schedule first reminder
        scheduleReminder(at: reminderTime1, identifier: "inventoryReminder1")
        
        // Schedule second reminder only if enabled
        if isSecondReminderEnabled {
            scheduleReminder(at: reminderTime2, identifier: "inventoryReminder2")
            print("✅ Inventory reminders scheduled for \(formatTime(reminderTime1)) and \(formatTime(reminderTime2))")
        } else {
            print("✅ Inventory reminder scheduled for \(formatTime(reminderTime1))")
        }
    }
    
    private func scheduleReminder(at time: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "Inventory Update Reminder"
        content.body = "Don't forget to update your household inventory levels!"
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling reminder: \(error)")
            }
        }
    }
    
    private func cancelInventoryReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["inventoryReminder1", "inventoryReminder2"])
        print("🗑️ Inventory reminders cancelled")
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Data Management
    func clearAllData(inventoryManager: InventoryManager) {
        inventoryManager.clearAllData()
    }
}