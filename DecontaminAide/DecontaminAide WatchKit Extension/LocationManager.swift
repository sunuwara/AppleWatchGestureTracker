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
    
    // Home address
    var address = "355 54th St SW, Wyoming, MI 49548"
    
    // Latitude and longitude variables of home address
    var homeLatitude = 0.0
    var homeLongitude = 0.0

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
        
        // Retrieve location update
        manager.startUpdatingLocation()
        
        addressToCoordinate(address: address)
        
        processDeviceLocation()
        
    }
    
    // Stop updating location
    func stopUpdates() {
        manager.stopUpdatingLocation()
    }
    
    // convering address to coordinates
    func addressToCoordinate(address: String) {
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(address) { (placemarks, error) in
            guard
                let placemarks = placemarks,
                let location = placemarks.first?.location?.coordinate
            else {
                // Handle no location found
                return
            }
            print("ADDRESS-LATI: \(String(describing: location.latitude))")
            print("ADDRESS-LONG: \(String(describing: location.longitude))")

            self.homeLatitude = location.latitude
            self.homeLongitude = location.longitude

        }
    }
    
    // MARK: Location Processing
    func processDeviceLocation() {
        
        // Configure timer to fetch motion data
        self.timer = Timer(fire:Date(), interval: 60, repeats: true, block: { [self] (timer) in
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
            
                atHome(currLatitude: data.latitude, currLongitude: data.longitude)
            }
        })
        
        // Add timer to the current run loop
        RunLoop.current.add(self.timer!, forMode: .default)
    }
    
    // MARK: Data Management
    func resetState() {
        rateAlongGravityBuffer.reset()
    }
    
    // Check if the user is leaving home
    func atHome(currLatitude: Double, currLongitude: Double) {
        
        let homeLocation = CLLocation(latitude: homeLatitude, longitude: homeLongitude)
        let distance = homeLocation.distance(from: CLLocation(latitude: currLatitude, longitude: currLongitude))
//        print("HOMELATI: \(self.homeLatitude) = HOMELONGI: \(self.homeLongitude)")
//        print("CURRLATI: \(lati) CURRLONGI: \(longi)")
//        print("DISTANCE: \(distance)")

        // TODO: implement notification
        // Notify if distance from home and current location is >50 meters
        if(distance > 50) {
            print("Mask-up!\n")
        }
    }
    
    // TODO: Monitoring a region around the specified coordinate
//    func monitorRegionAtLocation() {
//
//        // Make sure the app is authorized.
//        if manager.authorizationStatus == .authorizedAlways {
//
//            let center = CLLocationCoordinate2D(latitude: homeLatitude, longitude: homeLongitude)
//            // Register the region
//            let region = CLCircularRegion(center: center, radius: 5.0, identifier: "Home")
//            region.notifyOnEntry = true
//            region.notifyOnExit = false
//
//            locationManager.startMonitoring(for: region)
//        }
//    }

    // TODO: Handling a region-entered notification
//    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
//        print("LocationManager didEnterRegion:- \(region)")
//    }

}
