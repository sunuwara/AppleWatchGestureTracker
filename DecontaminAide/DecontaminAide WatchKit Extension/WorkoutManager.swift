//
//  WorkoutManager.swift
//  DecontaminAide WatchKit Extension
//
//  Created by PGCapstone Team on 11/1/20.
//

import Foundation
import HealthKit
import Dispatch

class WorkoutManager: NSObject, ObservableObject, MotionManagerDelegate {
    
    // MARK: Properties
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession!
    let motionManager = MotionManager()

    @Published var faceTouchCount = 0

    // workout configuration
    func workoutConfiguration() -> HKWorkoutConfiguration {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .unknown
        
        return configuration
    }
    
    // MARK: Workout Manager
    
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
        motionManager.startUpdates()
    }
    
    func stopWorkout() {
        // If we have already stopped the workout, then do nothing.
        if (session == nil) {
            return
        }

        // Stop the device motion updates and workout session.
        motionManager.stopUpdates()
        session.end()
        
        // Clear the workout session.
        session = nil
    }
    
    // MARK: MotionManagerDelegate
    
    func didUpdateFaceTouchCount(_ manager: MotionManager, faceTouchCount: Int) {
        DispatchQueue.main.async {
            self.faceTouchCount = faceTouchCount
        }
    }
}

// MARK: - HKWorkoutSessionDelegate
//extension WorkoutManager: HKWorkoutSessionDelegate {
//    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
//                        from fromState: HKWorkoutSessionState, date: Date) {
//        // Wait for the session to transition states before ending the builder.
//        /// - Tag: SaveWorkout
//        if toState == .ended {
//            print("The workout has now ended.")
//            builder.endCollection(withEnd: Date()) { (success, error) in
//                self.builder.finishWorkout { (workout, error) in
//                    // Optionally display a workout summary to the user.
//                    self.resetWorkout()
//                }
//            }
//        }
//    }
//
//    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
//
//    }
//}
