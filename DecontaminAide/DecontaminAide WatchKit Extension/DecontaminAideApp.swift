//
//  DecontaminAideApp.swift
//  DecontaminAide WatchKit Extension
//
//  Created by PGCapstone Team on 9/21/20.
//

import SwiftUI

@main
struct DecontaminAideApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            HomeView()
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}

struct DecontaminAideApp_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello, World Testing!")
    }
}
