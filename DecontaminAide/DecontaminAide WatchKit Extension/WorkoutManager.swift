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
    
    // MARK: Application Specific Constants
    
    struct ModelConstants {
        static let predictionWindowSize = 150
        static let sensorsUpdateInterval = 1.0 / 50.0
        static let stateInLength = 400
    }
    
    let faceTouchModel: MLModel = try! FaceTouchClassifier(configuration: MLModelConfiguration.init()).model
    var currentIndexInPredictionWindow = 0

    let gravityDataX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let gravityDataY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let gravityDataZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    
    let userAccelDataX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let userAccelDataY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let userAccelDataZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)

    let attitudeDataPitch = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let attitudeDataRoll = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let attitudeDataYaw = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    
    let rotRateDataX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rotRateDataY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rotRateDataZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    
    let rateAlongGravityBuffer = RunningBuffer(size: 50)

    let accumulatedRateAlongGravityData = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let peakRateData = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)

    var stateOutput = try! MLMultiArray(shape:[ModelConstants.stateInLength as NSNumber], dataType: MLMultiArrayDataType.double)
    
    var prevFaceTouchLabel = "nofacetouch"
    var currFaceTouchLabel = "nofacetouch"
    
    // Motion management
    let motionManager = CMMotionManager()
    let wristLocationIsLeft = WKInterfaceDevice.current().wristLocation == .left
    var recentDetection = false

    // Sound management
    let soundManager = SoundManager()

    
    // MARK: Face Touch Classification and Motion Manager

    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        // Reset everything when starting
        resetAllState()
        
        motionManager.deviceMotionUpdateInterval = TimeInterval(ModelConstants.sensorsUpdateInterval)
        
        // Retrieve motion updates
        motionManager.startDeviceMotionUpdates(to: .main) { deviceData, error in
            guard let deviceData = deviceData else { return }
            
            // Add current data sample to data array
//            startTime = Int(NSDate().timeIntervalSince1970)
//            processDeviceMotion()
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
        
        // Add current attitude reading to data array
        attitudeDataPitch[[currentIndexInPredictionWindow] as [NSNumber]] = deviceSample.attitude.pitch as NSNumber
        attitudeDataRoll[[currentIndexInPredictionWindow] as [NSNumber]] = deviceSample.attitude.roll as NSNumber
        attitudeDataYaw[[currentIndexInPredictionWindow] as [NSNumber]] = deviceSample.attitude.yaw as NSNumber
        
        // Add current rotation rate reading to data array
        rotRateDataX[[currentIndexInPredictionWindow] as [NSNumber]] = deviceSample.rotationRate.x as NSNumber
        rotRateDataY[[currentIndexInPredictionWindow] as [NSNumber]] = deviceSample.rotationRate.y as NSNumber
        rotRateDataZ[[currentIndexInPredictionWindow] as [NSNumber]] = deviceSample.rotationRate.z as NSNumber
        
        let rateAlongGravity = deviceSample.rotationRate.x * deviceSample.gravity.x
            + deviceSample.rotationRate.y * deviceSample.gravity.y
            + deviceSample.rotationRate.z * deviceSample.gravity.z
        self.rateAlongGravityBuffer.addSample(rateAlongGravity)

        if (!self.rateAlongGravityBuffer.isFull()) {
            return
        }

        let accumulatedRateAlongGravity = self.rateAlongGravityBuffer.sum() * ModelConstants.sensorsUpdateInterval
        let peakRate = accumulatedRateAlongGravity > 0 ? self.rateAlongGravityBuffer.max() : self.rateAlongGravityBuffer.min()
        
        accumulatedRateAlongGravityData[[currentIndexInPredictionWindow] as [NSNumber]] = accumulatedRateAlongGravity as NSNumber
        peakRateData[[currentIndexInPredictionWindow] as [NSNumber]] = peakRate as NSNumber
        
        // Update the index in the prediction window data array
        currentIndexInPredictionWindow += 1

        // If the data array is full, call the prediction method to get a new model prediction
        if (currentIndexInPredictionWindow == ModelConstants.predictionWindowSize) {
            if let modelPrediction = performModelPrediction() {

                // Use the predicted activity here
                prevFaceTouchLabel = currFaceTouchLabel
                currFaceTouchLabel = modelPrediction
                
                print("PrevLabel: \(prevFaceTouchLabel)")
                print("CurrtLabel: \(currFaceTouchLabel)\n")
                if (prevFaceTouchLabel == "nofacetouch" && currFaceTouchLabel == "facetouch") {
                    incrementFaceTouchCount()
                    print("Face touch count: \(faceTouchCount)\n")
                }

                // Start a new prediction window
                currentIndexInPredictionWindow = 0
                rateAlongGravityBuffer.reset()

//                prevFaceTouchLabel = "nofacetouch"
//                currFaceTouchLabel = "nofacetouch"
                recentDetection = false
                
//                soundManager.stopAudioEngine()
                
            }
        }
    }

    func performModelPrediction () -> String? {
//        let modelInput = FaceTouchClassifier2Input(accelX: userAccelDataX, accelY: userAccelDataY, accelZ: userAccelDataZ,
//                                                   attitudePitch: attitudeDataPitch, attitudeRoll: attitudeDataRoll, attitudeYaw: attitudeDataYaw,
//                                                   gravityX: gravityDataX, gravityY: gravityDataY, gravityZ: gravityDataZ,
//                                                   rotRateX: rotRateDataX, rotRateY: rotRateDataY, rotRateZ: rotRateDataZ,
//                                                   stateIn: stateOutput)
        let modelInput = FaceTouchClassifierInput(Accel_x: userAccelDataX, Accel_y: userAccelDataY, Accel_z: userAccelDataZ,
                                                  AccumulatedRateGravity: accumulatedRateAlongGravityData,
                                                  Attitude_pitch: attitudeDataPitch, Attitude_roll: attitudeDataRoll, Attitude_yaw: attitudeDataYaw,
                                                  Gravity_x: gravityDataX, Gravity_y: gravityDataY, Gravity_z: gravityDataZ,
                                                  PeakRate: peakRateData,
                                                  RotRate_x: rotRateDataX, RotRate_y: rotRateDataY, RotRate_z: rotRateDataZ,
                                                  stateIn: stateOutput)
        
        let modelOutput = try! faceTouchModel.prediction(from: modelInput)

        // Update the state vector
        stateOutput = (modelOutput.featureValue(for: "stateOut")?.multiArrayValue)!

        // print probability of facetouch and actual predicted label
        // TODO: use probabilty to count face touch only if above 80% confidence its a face touch
        print("Facetouch Probability: \(String(describing: modelOutput.featureValue(for: "labelProbability")?.dictionaryValue["facetouch"]?.doubleValue))")
        print("Label: \(modelOutput.featureValue(for: "label")!.stringValue)\n")

//        if ((modelOutput.featureValue(for: "labelProbability")?.dictionaryValue["facetouch"]?.doubleValue)! >= 0.8) {
//            return modelOutput.featureValue(for: "label")!.stringValue
//        }
//
//        return "nofacetouch"
        
        return modelOutput.featureValue(for: "label")!.stringValue
    }
    
    // MARK: Data Management

    func resetAllState() {
        rateAlongGravityBuffer.reset()
        prevFaceTouchLabel = "nofacetouch"
        currFaceTouchLabel = "nofacetouch"
        faceTouchCount = 0
        recentDetection = false
    }

    func incrementFaceTouchCount() {
        if(!recentDetection) {
            faceTouchCount += 1
            recentDetection = true

//            soundManager.startAudioEngine()
        }
    }
}
