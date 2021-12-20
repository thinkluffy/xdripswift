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
	
	@WKExtensionDelegateAdaptor(WatchExtensionDelegate.self) var extensionDelegate
	
	@Environment(\.scenePhase) private var scenePhase
	
    @SceneBuilder var body: some Scene {
		WindowGroup() {
            NavigationView {
				ContentView()
					.environmentObject(PhoneCommunicator.shared.usefulData)
					.ignoresSafeArea(.container, edges: .bottom)
					.navigationTitle(Constants.DisplayName)
					.navigationBarTitleDisplayMode(.inline)
			}
		}
		.onChange(of: scenePhase) { newScenePhase in
			if newScenePhase == .active {
				print("onChange active")
				PhoneCommunicator.shared.startRequestChart()
				// Update any complications on active watch faces.
                
			} else if newScenePhase == .inactive {
				print("onChange inactive")
                
            } else if newScenePhase == .background {
				print("onChange background")
				PhoneCommunicator.shared.stopRequestChart()
				ComplicationController.reload()
				WatchExtensionDelegate.fireBackgroundTasks()
                
			} else {
				print("onChange others: \(newScenePhase)")
			}
		}

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
