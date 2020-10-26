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
    
    let soundManager = SoundManager()
    let motionManager = CMMotionManager()
    let wristLocationIsLeft = WKInterfaceDevice.current().wristLocation == .left
    
    // MARK: Application Specific Constants
    
    // Add threshold data
    let rollThreshold = 0.85
    let rateThreshold = 1.35
    let resetThreshold = 1.35 * 0.05
    
    // The app is using 50hz data and the buffer is going to hold 1s worth of data.
    let sampleInterval = 1.0 / 50
    let rateAlongGravityBuffer = RunningBuffer(size: 50)
    
    var timer:Timer!
    var recentDetection = false
    
    // Face touch count
    @Published var faceTouchCount = 0

    // MARK: Motion Manager

    func startUpdates() {
        if(motionManager.isDeviceMotionAvailable) {
            // Reset everything when starting
            resetAllState()
            
            motionManager.deviceMotionUpdateInterval = sampleInterval
            motionManager.showsDeviceMovementDisplay = true
            
            // Retrieve motion updates
            // TODO: implement Retrieving steady stream of motion updates in background
            motionManager.startDeviceMotionUpdates()
            
            processDeviceMotion()
        }
        else {
            print("Device Motion is not available.")
            return
        }
    }

    func stopUpdates() {
        if(motionManager.isDeviceMotionAvailable) {
            motionManager.stopDeviceMotionUpdates()
        }
    }

    // MARK: Motion Processing
    
    func processDeviceMotion() {
        
        // Configure timer to fetch motion data
        self.timer = Timer(fire:Date(), interval: sampleInterval, repeats: true, block: { [self] (timer) in
            if let data = self.motionManager.deviceMotion {
                
                // TODO: implement more accurate face touch detection
                let gravity = data.gravity
                let acceleration = data.userAcceleration
                let rotationRate = data.rotationRate
                let attitude = data.attitude
                
                let rateAlongGravity = rotationRate.x * gravity.x
                                     + rotationRate.y * gravity.y
                                     + rotationRate.z * gravity.z
                self.rateAlongGravityBuffer.addSample(rateAlongGravity)

                if (!self.rateAlongGravityBuffer.isFull()) {
                    return
                }

                let accumulatedRollRot = self.rateAlongGravityBuffer.sum() * self.sampleInterval
                let peakRate = accumulatedRollRot > 0 ? self.rateAlongGravityBuffer.max() : self.rateAlongGravityBuffer.min()

                // Determine face touch
                if(accumulatedRollRot > rollThreshold && accumulatedRollRot < (2 * rollThreshold)) {
                    if(peakRate > rateThreshold) {
                        incrementFaceTouchCount()
                    }
                }
                
//                let timestamp = Date().timeIntervalSinceNow
//                os_log("Motion: %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@",
//                       String(timestamp),
//                       String(gravity.x),
//                       String(gravity.y),
//                       String(gravity.z),
//                       String(acceleration.x),
//                       String(acceleration.y),
//                       String(acceleration.z),
//                       String(rotationRate.x),
//                       String(rotationRate.y),
//                       String(rotationRate.z),
//                       String(attitude.pitch),
//                       String(attitude.roll),
//                       String(attitude.yaw),
//                       String(accumulatedRollRot),
//                       String(peakRate)
//                )

                // Reset after letting the rate settle
                if(self.recentDetection && abs(self.rateAlongGravityBuffer.recentMean()) < self.resetThreshold) {
                    self.recentDetection = false
                    self.rateAlongGravityBuffer.reset()
                    soundManager.stopAudioEngine()
                }
            }
        })
        
        // Add timer to the current run loop
        RunLoop.current.add(self.timer!, forMode: .default)
    }

    // MARK: Data Management
    
    func resetAllState() {
        rateAlongGravityBuffer.reset()

        faceTouchCount = 0
        recentDetection = false
    }
    
    func incrementFaceTouchCount() {
        if(!recentDetection) {
            faceTouchCount += 1
            recentDetection = true
            soundManager.startAudioEngine()
        }
    }
    
}
