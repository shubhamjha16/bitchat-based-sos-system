//
// LocationService.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation
import CoreLocation
import Combine

#if os(macOS)
import AppKit
#else
import UIKit
#endif

class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<LocationData?, Never>?
    
    @Published var currentLocation: LocationData?
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationEnabled = false
    
    private var isRequestingLocation = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        
        locationPermissionStatus = locationManager.authorizationStatus
        checkLocationEnabled()
    }
    
    private func checkLocationEnabled() {
        isLocationEnabled = locationManager.authorizationStatus == .authorizedWhenInUse || 
                           locationManager.authorizationStatus == .authorizedAlways
    }
    
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Show alert to go to settings
            showLocationSettingsAlert()
        case .authorizedWhenInUse, .authorizedAlways:
            isLocationEnabled = true
        @unknown default:
            break
        }
    }
    
    func getCurrentLocation() async -> LocationData? {
        guard isLocationEnabled else {
            requestLocationPermission()
            return nil
        }
        
        guard !isRequestingLocation else {
            return currentLocation
        }
        
        isRequestingLocation = true
        
        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            
            // Set timeout for location request
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if self.locationContinuation != nil {
                    self.locationContinuation?.resume(returning: self.currentLocation)
                    self.locationContinuation = nil
                    self.isRequestingLocation = false
                }
            }
            
            locationManager.requestLocation()
        }
    }
    
    func startLocationUpdates() {
        guard isLocationEnabled else {
            requestLocationPermission()
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    private func showLocationSettingsAlert() {
        DispatchQueue.main.async {
            #if os(macOS)
            let alert = NSAlert()
            alert.messageText = "Location Access Required"
            alert.informativeText = "Please enable location access in System Preferences to use emergency location services."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")!)
            }
            #else
            let alert = UIAlertController(
                title: "Location Access Required",
                message: "Please enable location access in Settings to use emergency location services.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            // Present the alert
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(alert, animated: true)
            }
            #endif
        }
    }
    
    // Convert CLLocation to LocationData
    private func convertToLocationData(_ location: CLLocation) -> LocationData {
        return LocationData(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            accuracy: location.horizontalAccuracy,
            address: nil, // Will be populated by geocoding if needed
            landmark: nil
        )
    }
    
    // Geocode location to get human-readable address
    func geocodeLocation(_ locationData: LocationData) async -> LocationData {
        let location = CLLocation(latitude: locationData.latitude, longitude: locationData.longitude)
        
        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let address = [
                    placemark.subThoroughfare,
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.postalCode,
                    placemark.country
                ].compactMap { $0 }.joined(separator: ", ")
                
                let landmark = placemark.name
                
                return LocationData(
                    latitude: locationData.latitude,
                    longitude: locationData.longitude,
                    altitude: locationData.altitude,
                    accuracy: locationData.accuracy,
                    address: address.isEmpty ? nil : address,
                    landmark: landmark
                )
            }
        } catch {
            print("Geocoding error: \(error)")
        }
        
        return locationData
    }
    
    // Format location for display
    func formatLocation(_ locationData: LocationData) -> String {
        if let address = locationData.address {
            return address
        } else if let landmark = locationData.landmark {
            return "\(landmark) (lat: \(String(format: "%.6f", locationData.latitude)), lng: \(String(format: "%.6f", locationData.longitude)))"
        } else {
            return "lat: \(String(format: "%.6f", locationData.latitude)), lng: \(String(format: "%.6f", locationData.longitude))"
        }
    }
    
    // Get distance between two locations
    func distance(from: LocationData, to: LocationData) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    // Format distance for display
    func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = convertToLocationData(location)
        
        // If we have a pending location request, fulfill it
        if let continuation = locationContinuation {
            continuation.resume(returning: currentLocation)
            locationContinuation = nil
            isRequestingLocation = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
        
        // If we have a pending location request, fulfill it with nil
        if let continuation = locationContinuation {
            continuation.resume(returning: nil)
            locationContinuation = nil
            isRequestingLocation = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.locationPermissionStatus = status
            self.checkLocationEnabled()
        }
    }
}