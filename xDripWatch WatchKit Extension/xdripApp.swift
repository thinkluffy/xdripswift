//
//  xdripApp.swift
//  xDripWatch WatchKit Extension
//
//  Created by Liu Xudong on 2021/11/16.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import SwiftUI

@main
struct xdripApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
