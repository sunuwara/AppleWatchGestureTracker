//
//  MotionManager.swift
//  DecontaminAide WatchKit Extension
//
//  Created by PGCapstone Team on 10/15/20.
//  This class manages the CoreMotion interactions and
//  provides a delegate to indicate changes in data.
//

import Foundation
import CoreMotion
import WatchKit
import os.log

class MotionManager: ObservableObject {
    
    // MARK: Properties
    
    let motionManager = CMMotionManager()
    let wristLocationIsLeft = WKInterfaceDevice.current().wristLocation == .left
    
    // MARK: Application Specific Constants
    
    // TODO: add threshold data
    
    // The app is using 50hz data and the buffer is going to hold 1s worth of data.
    let motionUpdateInterval = 1.0 / 50
    let rateAlongGravityBuffer = RunningBuffer(size: 50)

    var timer:Timer!
    @Published var gravityStr = ""
    @Published var accelerationStr = ""
    @Published var rotationStr = ""
    @Published var attitudeStr = ""
    
    // Face touch count
    var faceTouchCount = 0

    var recentDetection = false


    // MARK: Motion Manager

    func startUpdates() {
        if(!motionManager.isDeviceMotionAvailable) {
            print("Device Motion is not available.")
            return
        }

        // Reset everything when we start.
        //resetAllState()

        motionManager.deviceMotionUpdateInterval = motionUpdateInterval
        motionManager.startDeviceMotionUpdates()
        
        processDeviceMotion()
    }

    func stopUpdates() {
        if(motionManager.isDeviceMotionAvailable) {
            motionManager.stopDeviceMotionUpdates()
        }
    }

    // MARK: Motion Processing
    
    func processDeviceMotion() {
        self.timer = Timer(fire:Date(), interval: (1.0 / 50.0), repeats: true, block: { (timer) in
            if let data = self.motionManager.deviceMotion {
                self.gravityStr = String(format: "X: %.1f Y: %.1f Z: %.1f" ,
                                         data.gravity.x,
                                         data.gravity.y,
                                         data.gravity.z)
                self.accelerationStr = String(format: "X: %.1f Y: %.1f Z: %.1f" ,
                                              data.userAcceleration.x,
                                              data.userAcceleration.y,
                                              data.userAcceleration.z)
                self.rotationStr = String(format: "X: %.1f Y: %.1f Z: %.1f" ,
                                          data.rotationRate.x,
                                          data.rotationRate.y,
                                          data.rotationRate.z)
                self.attitudeStr = String(format: "r: %.1f p: %.1f y: %.1f" ,
                                          data.attitude.roll,
                                          data.attitude.pitch,
                                          data.attitude.yaw)
                
                let timestamp = Date().timeIntervalSinceNow
                os_log("Motion: %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@",
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
                       String(data.attitude.roll),
                       String(data.attitude.pitch),
                       String(data.attitude.yaw))
            }
        })
        
        RunLoop.current.add(self.timer!, forMode: .default)

        /*
        let gravity = deviceMotion.gravity
        let rotationRate = deviceMotion.rotationRate

        let rateAlongGravity = rotationRate.x * gravity.x // r⃗ · ĝ
                             + rotationRate.y * gravity.y
                             + rotationRate.z * gravity.z
        rateAlongGravityBuffer.addSample(rateAlongGravity)

        if !rateAlongGravityBuffer.isFull() {
            return
        }

        let accumulatedYawRot = rateAlongGravityBuffer.sum() * sampleInterval
        let peakRate = accumulatedYawRot > 0 ?
            rateAlongGravityBuffer.max() : rateAlongGravityBuffer.min()

        if (accumulatedYawRot < -yawThreshold && peakRate < -rateThreshold) {
            // Counter clockwise swing.
            if (wristLocationIsLeft) {
                incrementBackhandCountAndUpdateDelegate()
            } else {
                incrementForehandCountAndUpdateDelegate()
            }
        } else if (accumulatedYawRot > yawThreshold && peakRate > rateThreshold) {
            // Clockwise swing.
            if (wristLocationIsLeft) {
                incrementForehandCountAndUpdateDelegate()
            } else {
                incrementBackhandCountAndUpdateDelegate()
            }
         
        }
        */

        // TODO: Reset after letting the rate settle to catch the return swing.
        /*
        if (recentDetection && abs(rateAlongGravityBuffer.recentMean()) < resetThreshold) {
            recentDetection = false
            rateAlongGravityBuffer.reset()
        }
        */
    }

    // MARK: Data and Delegate Management
    /*
    func resetAllState() {
        rateAlongGravityBuffer.reset()

        faceTouchCount = 0
        recentDetection = false

        updateFaceTouchDelegate()
    }

    func incrementFaceTouchCountAndUpdateDelegate() {
        if(!recentDetection) {
            faceTouchCount += 1
            recentDetection = true

            print("Face touch count: \(faceTouchCount)")
            updateFaceTouchDelegate()
        }
    }

    func updateFaceTouchDelegate() {
        delegate?.didUpdateFaceTouchCount(self, faceTouchCount: faceTouchCount)
    }
     */
}
