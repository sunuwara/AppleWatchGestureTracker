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
    
    @State var started: Bool = false
    @State var btnString: String = "Start Tracking"
    
    // MARK: View Body
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading, spacing: 3, content: {
                Button(action: {
                    if(!started){
                        started = true
                        motionManager.startUpdates()
                        btnString = "Stop Tracking"
                    } else{
                        started = false
                        motionManager.stopUpdates()
                        btnString = "Start Tracking"
                    }
                }) {
                    Text(btnString)
                }
                
                Spacer()
                Text("Gravity:")
                HStack{
                    Text(motionManager.gravityStr)
                }
                
                Text("Acceleration:")
                HStack(){
                    Text(motionManager.accelerationStr)
                }
                
                Text("Rotation:")
                HStack{
                    Text(motionManager.rotationStr)
                }
                
                Text("Attitude:")
                HStack{
                    Text(motionManager.attitudeStr)
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
