//
//  HomeView.swift
//  DecontaminAide WatchKit Extension
//
//  Created by PGCapstone Team on 11/12/20.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack{
                Text("DecontaminAide").padding(10)
                    
                NavigationLink(destination: ContentView()) {
                    Text("Start Tracking")
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
