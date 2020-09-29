//
//  ContentView.swift
//  DecontaminAide WatchKit Extension
//
//  Created by KaranDev on 9/21/20.
//

import SwiftUI
import CoreMotion


class MotionManager: ObservableObject {
    
    @State var xGrav  = 0.0
    @State var yGrav  = 0.0
    @State var zGrav  = 0.0
    
    @State var xAcc  = 0.0
    @State var yAcc  = 0.0
    @State var zAcc  = 0.0
    
    @State var xRot  = 0.0
    @State var yRot  = 0.0
    @State var zRot  = 0.0
    
    let motionManager = CMMotionManager()
    
    init(){
        self.motionManager.deviceMotionUpdateInterval = 1.0 / 50
        
        motionManager.startDeviceMotionUpdates()
    }
    
    func processDeviceMotion(_ deviceMotion: CMDeviceMotion){
        self.xGrav = deviceMotion.gravity.x
        self.yGrav = deviceMotion.gravity.y
        self.zGrav = deviceMotion.gravity.z
        
        self.xAcc = deviceMotion.userAcceleration.x
        self.yAcc = deviceMotion.userAcceleration.y
        self.zAcc = deviceMotion.userAcceleration.z
        
        self.xRot = deviceMotion.rotationRate.x
        self.yRot = deviceMotion.rotationRate.y
        self.zRot = deviceMotion.rotationRate.z
    }
    
}


struct ContentView: View {
    
    var motion: MotionManager
    
//    @State private var xGrav  = 0
//    @State private var yGrav  = 0
//    @State private var zGrav  = 0
//
//    @State private var xAcc  = 0
//    @State private var yAcc  = 0
//    @State private var zAcc  = 0
//
//    @State private var xRot  = 0
//    @State private var yRot  = 0
//    @State private var zRot  = 0
//
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3, content: {
            Text("Core Motion Data")
                .underline()
                .bold()
            Spacer()
            Text("Gravity:")
            HStack{
                Text("X: " + String(motion.xGrav))
                Text("Y: " + String(motion.yGrav))
                Text("Z: " + String(motion.zGrav))

            }
            Text("Acceleration:")
            HStack(alignment: .center){
                Text("X: " + String(motion.xAcc))
                Text("Y: " + String(motion.yAcc))
                Text("Z: " + String(motion.zAcc))

            }
            Text("Rotation:")
            HStack{
                Text("X: " + String(motion.xRot))
                Text("Y: " + String(motion.yRot))
                Text("Z: " + String(motion.zRot))

            }
            
        })
        
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(motion: MotionManager())
    }
}
