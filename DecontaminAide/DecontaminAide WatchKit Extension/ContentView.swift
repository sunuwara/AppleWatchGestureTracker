//
//  ContentView.swift
//  DecontaminAide WatchKit Extension
//
//  Created by PGCapstone Team on 9/21/20.
//

import SwiftUI

struct ContentView: View {
    
    // MARK: Properties
    
    @ObservedObject var motionManager = MotionManager()
    @ObservedObject var locationManager = LocationManager()
    
    @State var started: Bool = false
    
    // MARK: View Body
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading, spacing: 10, content: {
                HStack(alignment: .center) {
                    Text("FACE TOUCH COUNT")
                        .font(.headline)
                }
                
                Button(action: {}) {
                    Text("\(motionManager.faceTouchCount)")
                        .font(.title)
                }
                
                HStack() {
                    Spacer()
                    Button(action: {
                        if(!started) {
                            started = true
                            motionManager.startUpdates()
                            locationManager.startUpdates()
                        } else {
                            started = false
                            motionManager.stopUpdates()
                            locationManager.stopUpdates()
                        }
                    }) {
                        Image(systemName: started ? "stop.fill" : "play.fill")
                            .padding(20)
                            .foregroundColor(.white)
                            .background(started ? Color.red : Color.green)
                            .font(.largeTitle)
                            .mask(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
            })
        }
    }
    
    // MARK: Functions
    
    
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
