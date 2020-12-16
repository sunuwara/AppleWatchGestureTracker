//
//  WorkoutManager.swift
//  DecontaminAide WatchKit Extension
//
//  Created by PGCapstone Team on 11/1/20.
//

import Foundation
import HealthKit
import CoreMotion
import CoreML
import WatchKit
import os.log

class WorkoutManager: ObservableObject {
    
    // MARK: Workout Manager
    
    @Published var faceTouchCount = 0
    
    // HealthKit and Workout session
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession!
    
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
    
    // MARK: Face Touch Classification and Motion Manager

    struct ModelConstants {
        static let predictionWindowSize = 150
        static let sensorsUpdateInterval = 1.0 / 50.0
        static let stateInLength = 400
    }

    let faceTouchModel: MLModel = try! ActivityClassifier1(configuration: MLModelConfiguration.init()).model
    var currentIndexInPredictionWindow = 0

    let gravityDataX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let gravityDataY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let gravityDataZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)

    let userAccelDataX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let userAccelDataY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let userAccelDataZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)

    let rotRateDataX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rotRateDataY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rotRateDataZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    
    let attitudeDataPitch = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let attitudeDataRoll = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let attitudeDataYaw = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)

    var stateOutput = try! MLMultiArray(shape:[ModelConstants.stateInLength as NSNumber], dataType: MLMultiArrayDataType.double)

    var prevFaceTouchLabel = "nofacetouch"
    var currFaceTouchLabel = "nofacetouch"

    // Motion management
    let motionManager = CMMotionManager()
    let wristLocationIsLeft = WKInterfaceDevice.current().wristLocation == .left
    var recentDetection = false

    // Sound management
    let soundManager = SoundManager()
    
    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }

        // Reset everything when starting
        resetAllState()

        motionManager.deviceMotionUpdateInterval = TimeInterval(ModelConstants.sensorsUpdateInterval)

        // Retrieve motion updates
        motionManager.startDeviceMotionUpdates(to: .main) { deviceData, error in
            guard let deviceData = deviceData else { return }

            // Add current data sample to data array
            self.addDeviceSampleToDataArray(deviceSample: deviceData)
        }
    }

    func stopUpdates() {
        if(motionManager.isDeviceMotionAvailable) {
            motionManager.stopDeviceMotionUpdates()
        }
    }
    
    func addDeviceSampleToDataArray(deviceSample: CMDeviceMotion) {
        // Add current gravity reading to data array
        gravityDataX[[currentIndexInPredictionWindow] as [NSNumber]] = deviceSample.gravity.x as NSNumber
        gravityDataY[[currentIndexInPredictionWindow] as [NSNumber]] = deviceSample.gravity.x as NSNumber
        gravityDataZ[[currentIndexInPredictionWindow] as [NSNumber]] = deviceSample.gravity.x as NSNumber

        // Add current user accelerometer reading to data array
        userAccelDataX[[currentIndexInPredictionWindow] as [NSNumber]] = deviceSample.userAcceleration.x as NSNumber
        userAccelDataY[[currentIndexInPredictionWindow] as [NSNumber]] = deviceSample.userAcceleration.y as NSNumber
        userAccelDataZ[[currentIndexInPredictionWindow] as [NSNumber]] = deviceSample.userAcceleration.z as NSNumber
        
        // Add current rotation rate reading to data array
        rotRateDataX[[currentIndexInPredictionWindow] as [NSNumber]] = deviceSample.rotationRate.x as NSNumber
        rotRateDataY[[currentIndexInPredictionWindow] as [NSNumber]] = deviceSample.rotationRate.y as NSNumber
        rotRateDataZ[[currentIndexInPredictionWindow] as [NSNumber]] = deviceSample.rotationRate.z as NSNumber
        
        // Add current attitude reading to data array
        attitudeDataPitch[[currentIndexInPredictionWindow] as [NSNumber]] = deviceSample.attitude.pitch as NSNumber
        attitudeDataRoll[[currentIndexInPredictionWindow] as [NSNumber]] = deviceSample.attitude.roll as NSNumber
        attitudeDataYaw[[currentIndexInPredictionWindow] as [NSNumber]] = deviceSample.attitude.yaw as NSNumber

        // Update the index in the prediction window data array
        currentIndexInPredictionWindow += 1

        // If the data array is full, call the prediction method to get a new model prediction
        if (currentIndexInPredictionWindow == ModelConstants.predictionWindowSize) {
            if let modelPrediction = performModelPrediction() {
                
                // Use the predicted activity here
                prevFaceTouchLabel = currFaceTouchLabel
                currFaceTouchLabel = modelPrediction
                
//                print("Previous Facetouch prediction: \(prevFaceTouchLabel)")
                print("Facetouch prediction: \(currFaceTouchLabel)\n")
                
                if (prevFaceTouchLabel == "nofacetouch" && currFaceTouchLabel == "facetouch") {
                    incrementFaceTouchCount()
                }

                // Start a new prediction window
                currentIndexInPredictionWindow = 0
                
                // Start Sound Analysis after face touch is detected
//                soundManager.stopAudioEngine()
            }
        }
    }

    func performModelPrediction() -> String? {
        /**
            Works properly if the run on the returns value for face touch confidence.
            Certain builds the labelProbability output of the prediction is filled with NaN values and will cause the prediction to never count any face touches.
            Unsure if this due to watchOS, ActivityClassifier or simply sensor issue but the implementation of machine learning model is accurate when build installs properly
         */
        let predictInput = ActivityClassifier1Input(accelX: userAccelDataX, accelY: userAccelDataY, accelZ: userAccelDataZ,
                                                    attPitch: attitudeDataPitch, attRoll: attitudeDataRoll, attYaw: attitudeDataYaw,
                                                    gravityX: gravityDataX, gravityY: gravityDataY, gravityZ: gravityDataZ,
                                                    rotRatY: rotRateDataY, rotRateX: rotRateDataX, rotRateZ: rotRateDataZ,
                                                    stateIn: stateOutput)

        guard let predictOutput = try? faceTouchModel.prediction(from: predictInput) else {
            print("Prediction Failed!")
            return "0"
        }

        // Get prediction output
        let labelProbability = predictOutput.featureValue(for: "labelProbability")!.dictionaryValue as! [String : Double]
        let label = predictOutput.featureValue(for: "label")!.stringValue
        stateOutput = predictOutput.featureValue(for: "stateOut")!.multiArrayValue!
        let facetouchConfidence = labelProbability["facetouch"] ?? 0.0
        
        // Print probability of facetouch and actual predicted label
//        print("Current Label: \(label)")
        print("Facetouch Confidence: \(facetouchConfidence)")
//        print("Recent Detection: \(recentDetection)\n")
        
        // Count face touch only if its 99% - 100% confident and hasn't detected face touch recently
        // Handles the lag in confidence staying high after detection
        if ((facetouchConfidence >= 0.999 && facetouchConfidence <= 1.00) && (recentDetection == false)) {
            return "facetouch"
        }
        
        if (facetouchConfidence <= 0.999 || facetouchConfidence > 1.00) {
            recentDetection = false
        }

        return "nofacetouch"
    }

    func resetAllState() {
        prevFaceTouchLabel = "nofacetouch"
        currFaceTouchLabel = "nofacetouch"
        faceTouchCount = 0
        recentDetection = false
    }

    func incrementFaceTouchCount() {
        if(!recentDetection) {
            faceTouchCount += 1
            recentDetection = true
            print("Face touch count: \(faceTouchCount)\n")
                
            // Start Sound Analysis after face touch is detected
            soundManager.startAudioEngine()
        }
    }
}
