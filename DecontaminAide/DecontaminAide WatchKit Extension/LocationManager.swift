//
//  LocationManager.swift
//  DecontaminAide WatchKit Extension
//
//  Created by PGCapstone Team on 10/18/20.
//  This class manages the CoreLocation interactions and
//  provides a delegate to indicate changes in data.
//

import Foundation
import CoreLocation
import WatchKit
import os.log

class LocationManager: ObservableObject {

    // MARK: Properties
    
    let manager = CLLocationManager()
    
    // The app is using 50hz data and the buffer is going to hold 1s worth of data.
    let locationUpdateInterval = 1.0 / 50
    let rateAlongGravityBuffer = RunningBuffer(size: 50)

    var timer:Timer!
    @Published var locationStr = ""

    // MARK: Location Manager
    
    func startUpdates() {

        // Reset location when starting
        resetState()
        
        // The best level of accuracy location available
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestAlwaysAuthorization()
        
        // Retrieve location update
        manager.startUpdatingLocation()
        
        processDeviceLocation()
    }

    func stopUpdates() {
        // Stop updating location
        manager.stopUpdatingLocation()
    }

    // MARK: Location Processing
    
    func processDeviceLocation() {
        
        // Configure timer to fetch motion data
        self.timer = Timer(fire:Date(), interval: (1.0 / 50.0), repeats: true, block: { (timer) in
            if let data = self.manager.location?.coordinate {
                self.locationStr = String(format: "Lati: %.1f Long: %.1f" ,
                                      data.latitude,
                                      data.longitude)

//                let timestamp = Date().timeIntervalSinceNow
//                os_log("Location: %@, %@, %@",
//                       String(timestamp),
//                       String(data.latitude),
//                       String(data.longitude)
//                )
            }
        })

        // Add timer to the current run loop
        RunLoop.current.add(self.timer!, forMode: .default)
    }
    
    // MARK: Data Management
    
    func resetState() {
        rateAlongGravityBuffer.reset()
    }
}
