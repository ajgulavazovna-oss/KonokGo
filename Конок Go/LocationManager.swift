//
//  LocationManager.swift
//  Конок Go
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var userLocation: CLLocation?
    @Published var userAddress: String = ""
    @Published var hasAddress: Bool = false
    @Published var isInOsh: Bool = false

    private static let savedAddressKey = "konok_savedAddress"

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus

        if let saved = UserDefaults.standard.string(forKey: Self.savedAddressKey), !saved.isEmpty {
            userAddress = saved
            hasAddress = true
        }
    }

    func requestPermission() {
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func saveAddress(_ address: String) {
        guard !address.isEmpty else { return }
        userAddress = address
        hasAddress = true
        UserDefaults.standard.set(address, forKey: Self.savedAddressKey)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async { self.userLocation = location }
        manager.stopUpdatingLocation()
        reverseGeocode(location) { [weak self] address, inOsh in
            DispatchQueue.main.async {
                self?.isInOsh = inOsh
                if inOsh, let addr = address {
                    self?.saveAddress(addr)
                }
            }
        }
    }

    func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D,
                                   completion: @escaping (String?, Bool) -> Void) {
        let loc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        reverseGeocode(loc, completion: completion)
    }

    private func reverseGeocode(_ location: CLLocation,
                                  completion: @escaping (String?, Bool) -> Void) {
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            guard let p = placemarks?.first else { completion(nil, false); return }
            let city = p.locality ?? ""
            let inOsh = city == "Ош" || city.lowercased() == "osh"
            var parts: [String] = []
            if !city.isEmpty { parts.append(city) }
            if let street = p.thoroughfare { parts.append(street) }
            if let num   = p.subThoroughfare { parts.append(num) }
            completion(parts.joined(separator: ", "), inOsh)
        }
    }
}
