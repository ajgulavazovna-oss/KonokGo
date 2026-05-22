//
//  LocationManager.swift
//  Конок Go
//

import Foundation
import CoreLocation
import MapKit
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var userLocation: CLLocation?
    @Published var userAddress: String = ""
    @Published var hasAddress: Bool = false
    @Published var isInOsh: Bool = false

    private static let savedAddressKey = "konok_savedAddress"
    private var activeGeocodeTask: Task<Void, Never>?

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

    func refreshLocation() {
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        } else {
            requestPermission()
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
        reverseGeocode(coordinate: location.coordinate) { [weak self] address, inOsh in
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
        reverseGeocode(coordinate: coordinate, completion: completion)
    }

    private func reverseGeocode(coordinate: CLLocationCoordinate2D,
                                completion: @escaping (String?, Bool) -> Void) {
        activeGeocodeTask?.cancel()
        activeGeocodeTask = Task {
            do {
                let request = MKReverseGeocodeRequest(coordinate: coordinate)
                let response = try await request.response
                guard !Task.isCancelled else { return }
                let p = response.placemark
                let city = p.locality ?? ""
                let inOsh = city == "Ош" || city.lowercased() == "osh"
                var parts: [String] = []
                if !city.isEmpty { parts.append(city) }
                if let street = p.thoroughfare { parts.append(street) }
                if let num = p.subThoroughfare { parts.append(num) }
                completion(parts.joined(separator: ", "), inOsh)
            } catch {
                completion(nil, false)
            }
        }
    }
}
