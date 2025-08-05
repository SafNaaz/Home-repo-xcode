import Foundation
import SwiftUI
import LocalAuthentication

class SettingsManager: ObservableObject {
    @Published var isDarkMode: Bool = false
    @Published var isSecurityEnabled: Bool = false
    @Published var isAuthenticated: Bool = false
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadSettings()
    }
    
    // MARK: - Settings Management
    private func loadSettings() {
        isDarkMode = userDefaults.bool(forKey: "isDarkMode")
        isSecurityEnabled = userDefaults.bool(forKey: "isSecurityEnabled")
    }
    
    func saveSettings() {
        userDefaults.set(isDarkMode, forKey: "isDarkMode")
        userDefaults.set(isSecurityEnabled, forKey: "isSecurityEnabled")
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
            let reason = "Authenticate to access your fridge data"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                completion(success)
            }
        } else {
            // Fallback to device passcode
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                let reason = "Authenticate with your device passcode to access your fridge data"
                
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
    
    // MARK: - Data Management
    func clearAllData(fridgeManager: FridgeManager) {
        fridgeManager.clearAllData()
    }
    
    func resetToDefaults(fridgeManager: FridgeManager) {
        fridgeManager.resetToDefaults()
    }
}