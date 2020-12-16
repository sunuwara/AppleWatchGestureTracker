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
    
    var manager = CLLocationManager()
    var defaults = UserDefaults.standard

    // The app is using 50hz data and the buffer is going to hold 1s worth of data.
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
        manager.requestWhenInUseAuthorization()
        
        // Retrieve location update
        manager.startUpdatingLocation()
    
        processDeviceLocation()
        
    }
    
    // Stop updating location
    func stopUpdates() {
        manager.stopUpdatingLocation()
    }
    
    // MARK: Location Processing
    func processDeviceLocation() {
        
        // Configure timer to fetch motion data
        self.timer = Timer(fire:Date(), interval: 60, repeats: true, block: { [self] (timer) in
            if let data = self.manager.location?.coordinate {
                self.locationStr = String(format: "Lati: %.1f Long: %.1f" ,
                                          data.latitude,
                                          data.longitude)

                // to print out the output
//                let timestamp = Date().timeIntervalSinceNow
//                os_log("Location: %@, %@, %@",
//                       String(timestamp),
//                       String(data.latitude),
//                       String(data.longitude)
//                )
                
                getHomeAddress(currLatitude: data.latitude, currLongitude: data.longitude)
                leavingHome(currLatitude: data.latitude, currLongitude: data.longitude)
                
            }
        })
        
        // Add timer to the current run loop
        RunLoop.current.add(self.timer!, forMode: .default)
    }
    
    // MARK: Data Management
    func resetState() {
        rateAlongGravityBuffer.reset()
    }
    
    // get user home address first time user launch app
    func getHomeAddress(currLatitude: Double, currLongitude: Double) {
                
        // get the users location
        let launchedBefore = defaults.bool(forKey: "launchedBefore")
        if launchedBefore {
            print("Not first time lunch")
        }
        else {
            print("\nFirst launch, setting UserDefault")
            defaults.set(true, forKey: "launchedBefore")
            
            // set address coordinates in default setting
            defaults.set(currLatitude, forKey: "homeLatitude")
            defaults.set(currLongitude, forKey: "homeLongitude")

        }
    }
    
    // Check if the user is leaving home
    func leavingHome(currLatitude: Double, currLongitude: Double) {
        let tempLati = getHomeLatitude()
        let tempLongi = getHomeLongitude()
        
        let homeLocation = CLLocation(latitude: tempLati, longitude: tempLongi)
        let distance = homeLocation.distance(from: CLLocation(latitude: currLatitude, longitude: currLongitude))
        
        // Notify if distance from home and current location is >50 meters
        if(distance > 50) {
            print("Mask-up: You are leaving home.\n")
        }
    }
    
    // returns the user's home latitude
    func getHomeLatitude() -> Double {
        let homeLatitude = defaults.double(forKey: "homeLatitude")
        return homeLatitude
    }
    
    // returns the user's home longitude
    func getHomeLongitude() -> Double {
        let homeLongitude = defaults.double(forKey: "homeLongitude")
        return homeLongitude
    }
    
}
