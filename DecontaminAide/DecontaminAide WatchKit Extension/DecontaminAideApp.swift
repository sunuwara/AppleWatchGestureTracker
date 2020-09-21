//
//  DecontaminAideApp.swift
//  DecontaminAide WatchKit Extension
//
//  Created by KaranDev on 9/21/20.
//

import SwiftUI

@main
struct DecontaminAideApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
