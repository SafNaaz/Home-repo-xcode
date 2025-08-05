//
//  FridgeApp.swift
//  Fridge
//
//  Created by Safnas Othayoth Chakkara on 06/08/25.
//

import SwiftUI

@main
struct FridgeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
