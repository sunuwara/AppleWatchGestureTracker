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
                ContentView(motion: MotionManager())
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}

struct DecontaminAideApp_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello, World Testing!")
    }
}
