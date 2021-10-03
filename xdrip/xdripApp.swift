//
//  xdripApp.swift
//  xdrip
//
//  Created by Johan Degraeve on 29/09/2021.
//

import SwiftUI

@main
struct xdripApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            BgReadingView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
