//
//  WorkoutManager.swift
//  DecontaminAide WatchKit Extension
//
//  Created by PGCapstone Team on 11/1/20.
//

import Foundation
import HealthKit
import CoreMotion
import WatchKit
import os.log

class WorkoutManager: ObservableObject {
    
    // MARK: Properties
    
    // HealthKit and Workout session
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession!
    
    // Motion management
    let motionManager = CMMotionManager()
    let wristLocationIsLeft = WKInterfaceDevice.current().wristLocation == .left
    
    // Sound management
    //let soundManager = SoundManager()
    
    // MARK: Application Specific Constants
    
    // Add threshold data
    let rollThreshold = 0.85
    let rateThreshold = 1.35
    let resetThreshold = 1.35 * 0.05
    
    // The app is using 50hz data and the buffer is going to hold 1s worth of data.
    let sampleInterval = 1.0 / 50
    let rateAlongGravityBuffer = RunningBuffer(size: 50)
    let activity = 0
    
    var timer:Timer!
    var recentDetection = false
    var startTime = 0
    
    @Published var faceTouchCount = 0
    
    // MARK: Workout Manager
    
    func workoutConfiguration() -> HKWorkoutConfiguration {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .unknown
        
        return configuration
    }
    
    func startWorkout() {
        // If we have already started the workout, then do nothing.
        if (session != nil) {
            return
        }
        
        // Create session
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: self.workoutConfiguration())
        } catch {
            fatalError("Unable to create the workout session!")
        }
        
        // Start the workout session and begin device motion updates
        session.startActivity(with: Date())
        startUpdates()
    }
    
    func stopWorkout() {
        // If we have already stopped the workout, then do nothing.
        if (session == nil) {
            return
        }

        // Stop the device motion updates and workout session.
        stopUpdates()
        session.end()
        
        // Clear the workout session.
        session = nil
    }
    
    // MARK: Motion Manager

    func startUpdates() {
        if(motionManager.isDeviceMotionAvailable) {
            // Reset everything when starting
            resetAllState()
            
            motionManager.deviceMotionUpdateInterval = sampleInterval
            motionManager.showsDeviceMovementDisplay = true
            
            // Retrieve motion updates
            motionManager.startDeviceMotionUpdates()
            
            startTime = Int(NSDate().timeIntervalSince1970)
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

                let accumulatedRateAlongGravity = self.rateAlongGravityBuffer.sum() * self.sampleInterval
                let peakRate = accumulatedRateAlongGravity > 0 ? self.rateAlongGravityBuffer.max() : self.rateAlongGravityBuffer.min()

                // Determine face touch
                if(accumulatedRateAlongGravity > rollThreshold && accumulatedRateAlongGravity < (2 * rollThreshold)) {
                    if(peakRate > rateThreshold) {
                        incrementFaceTouchCount()
                    }
                }
                
                let timeInterval = Int(NSDate().timeIntervalSince1970) - startTime
                os_log("Motion: %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@",
                       String(timeInterval),
                       String(activity),
                       String(acceleration.x),
                       String(acceleration.y),
                       String(acceleration.z),
                       String(rotationRate.x),
                       String(rotationRate.y),
                       String(rotationRate.z),
                       String(gravity.x),
                       String(gravity.y),
                       String(gravity.z),
                       String(attitude.pitch),
                       String(attitude.roll),
                       String(attitude.yaw),
                       String(accumulatedRateAlongGravity),
                       String(peakRate)
                )

                // Reset after letting the rate settle
                if(self.recentDetection && abs(self.rateAlongGravityBuffer.recentMean()) < self.resetThreshold) {
                    self.recentDetection = false
                    self.rateAlongGravityBuffer.reset()
                    
                    //TODO: commented out to fix face touch detection
                    //soundManager.stopAudioEngine()
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
            
            //soundManager.startAudioEngine()
        }
    }
}
