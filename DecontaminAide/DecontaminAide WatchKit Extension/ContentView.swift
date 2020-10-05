//
//  ContentView.swift
//  DecontaminAide WatchKit Extension
//
//  Created by PGCapstone Team on 9/21/20.
//

import SwiftUI
import CoreMotion
import os.log


class MotionManager: ObservableObject {
    
    var timer:Timer!
    @Published
    var xGrav  = 0.0
    var yGrav  = 0.0
    var zGrav  = 0.0
    
    var xAcc  = 0.0
    var yAcc  = 0.0
    var zAcc  = 0.0
    
    var xRot  = 0.0
    var yRot  = 0.0
    var zRot  = 0.0
    
    var pAtt = 0.0
    var rAtt = 0.0
    var yAtt = 0.0
    
    let motionManager = CMMotionManager()
    
    func startMotion(){
        
        if(self.motionManager.isDeviceMotionAvailable){
            motionManager.deviceMotionUpdateInterval = 1.0 / 50
            motionManager.startDeviceMotionUpdates()
            self.timer = Timer(fire:Date(), interval: (1.0 / 50.0), repeats: true, block: { (timer) in
                if let data = self.motionManager.deviceMotion{
                    self.xGrav = data.gravity.x
                    self.yGrav = data.gravity.y
                    self.zGrav = data.gravity.z
                    
                    self.xAcc = data.userAcceleration.x
                    self.yAcc = data.userAcceleration.y
                    self.zAcc = data.userAcceleration.z
                    
                    self.xRot = data.rotationRate.x
                    self.yRot = data.rotationRate.y
                    self.zRot = data.rotationRate.z
                    
                    self.pAtt = data.attitude.pitch
                    self.rAtt = data.attitude.roll
                    self.yAtt = data.attitude.yaw
                    
                    let timestamp = Date().timeIntervalSinceNow
                    os_log("Motion: %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@,",
                           String(timestamp),
                           String(data.gravity.x),
                           String(data.gravity.y),
                           String(data.gravity.z),
                           String(data.userAcceleration.x),
                           String(data.userAcceleration.y),
                           String(data.userAcceleration.z),
                           String(data.rotationRate.x),
                           String(data.rotationRate.y),
                           String(data.rotationRate.z),
                           String(data.attitude.pitch),
                           String(data.attitude.roll),
                           String(data.attitude.yaw)
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
                    Text("X: " + String(format: "%.3f", motion.xGrav))
                    Text("Y: " + String(format: "%.3f", motion.yGrav))
                    Text("Z: " + String(format: "%.3f", motion.zGrav))

                }
                
                Text("Acceleration:")
                HStack(alignment: .center){
                    Text("X: " + String(format: "%.3f", motion.xAcc))
                    Text("Y: " + String(format: "%.3f", motion.yAcc))
                    Text("Z: " + String(format: "%.3f", motion.zAcc))

                }
                
                Text("Rotation:")
                HStack{
                    Text("X: " + String(format: "%.3f", motion.xRot))
                    Text("Y: " + String(format: "%.3f", motion.yRot))
                    Text("Z: " + String(format: "%.3f", motion.zRot))

                }
                
                Text("Attitude:")
                HStack{
                    Text("P: " + String(format: "%.3f", motion.pAtt))
                    Text("R: " + String(format: "%.3f", motion.rAtt))
                    Text("Y: " + String(format: "%.3f", motion.yAtt))
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
