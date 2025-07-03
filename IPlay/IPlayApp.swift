//
//  IPlayApp.swift
//  IPlay
//
//  Created by Aswanth K on 01/07/25.
//

import SwiftUI

@main
struct IPlayApp: App {
//    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
//            ContentView()
            AudioListView()
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
