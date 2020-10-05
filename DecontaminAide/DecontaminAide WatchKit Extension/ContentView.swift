//
//  ContentView.swift
//  DecontaminAide WatchKit Extension
//
//  Created by KaranDev on 9/21/20.
//

import SwiftUI
import CoreMotion
import os.log


class MotionManager: ObservableObject {
    
    var timer:Timer!
    @Published var xGrav  = 0.0
    var yGrav  = 0.0
    var zGrav  = 0.0
    
    var xAcc  = 0.0
    var yAcc  = 0.0
    var zAcc  = 0.0
    
    var xRot  = 0.0
    var yRot  = 0.0
    var zRot  = 0.0
    
    let motionManager = CMMotionManager()
    
    func startMotion(){
        
        if(self.motionManager.isDeviceMotionAvailable){
            motionManager.deviceMotionUpdateInterval = 1.0 / 50
            motionManager.startDeviceMotionUpdates()
            self.timer = Timer(fire:Date(), interval: (1.0 / 50.0), repeats: true, block: { (timer) in
                if let data =
                    self.motionManager.deviceMotion{
                    self.xGrav = data.gravity.x
                    self.yGrav = data.gravity.y
                    self.zGrav = data.gravity.z
                    
                    self.xAcc = data.userAcceleration.x
                    self.yAcc = data.userAcceleration.y
                    self.zAcc = data.userAcceleration.z
                    
                    self.xRot = data.rotationRate.x
                    self.yRot = data.rotationRate.y
                    self.zRot = data.rotationRate.z
                    
                    let timestamp = Date().timeIntervalSinceNow
                    os_log("Motion: %@, %@, %@, %@, %@, %@, %@, %@, %@, %@,",
                           String(timestamp),
                           String(data.gravity.x),
                           String(data.gravity.y),
                           String(data.gravity.z),
                           String(data.userAcceleration.x),
                           String(data.userAcceleration.y),
                           String(data.userAcceleration.z),
                           String(data.rotationRate.x),
                           String(data.rotationRate.y),
                           String(data.rotationRate.z)
                           )

                }
            })
            
            RunLoop.current.add(self.timer!, forMode: .default)
            
        }
    }
    func stopMotion(){
        motionManager.stopDeviceMotionUpdates()
    }
    
}


struct ContentView: View {
    
    @ObservedObject var motion: MotionManager
    @State var started: Bool = false
    @State var btnString:String = "Start Tracking"
//    @State private var xGravTest  = 0
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
        ScrollView{
        VStack(alignment: .leading, spacing: 3, content: {
            Button(action: {
                if(!started){
                    started = true
                    motion.startMotion()
                    btnString = "Stop Tracking"
                } else{
                    started = false
                    motion.stopMotion()
                    btnString = "Start Tracking"
                }
            }) {
                Text(btnString)
                    
                    
            }
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
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(motion: MotionManager())
    }
}
