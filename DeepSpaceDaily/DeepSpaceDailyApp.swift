//
//  DeepSpaceDailyApp.swift
//  DeepSpaceDaily
//
//  Created by admin on 28/02/25.
//

import SwiftUI

@main
struct DeepSpaceDailyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
