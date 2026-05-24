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
    // CLGeocoder: deprecated warning only, still functional in iOS 26
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
        geocoder.cancelGeocode()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        Task {
            // --- Primary: CLGeocoder ---
            var inOsh = false
            var street: String? = nil
            var num: String? = nil

            if let placemarks = try? await geocoder.reverseGeocodeLocation(location),
               let p = placemarks.first {
                let city = p.locality ?? p.subLocality ?? ""
                inOsh = city == "Ош" || city.lowercased() == "osh"
                if let raw = p.thoroughfare {
                    street = raw.components(separatedBy: " ").last ?? raw
                }
                num = p.subThoroughfare
            }

            // --- Fallback: MKLocalSearch when street or house number missing ---
            if street == nil || num == nil {
                if let nearby = await nearbyAddress(coordinate: coordinate, inOsh: &inOsh) {
                    completion(nearby, inOsh)
                    return
                }
            }

            var parts: [String] = []
            if let s = street { parts.append(s) }
            if let n = num    { parts.append(n) }

            completion(parts.isEmpty ? nil : parts.joined(separator: ", "), inOsh)
        }
    }

    // MKLocalSearch fallback — finds nearest named address within ~300 m
    private func nearbyAddress(coordinate: CLLocationCoordinate2D,
                                inOsh: inout Bool) async -> String? {
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
        )
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = "дом"
        req.region = region
        req.resultTypes = .address

        guard let resp = try? await MKLocalSearch(req).start(),
              !resp.mapItems.isEmpty else { return nil }

        let here = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let nearest = resp.mapItems.min {
            CLLocation(latitude: $0.placemark.coordinate.latitude,
                       longitude: $0.placemark.coordinate.longitude).distance(from: here)
            <
            CLLocation(latitude: $1.placemark.coordinate.latitude,
                       longitude: $1.placemark.coordinate.longitude).distance(from: here)
        }
        guard let item = nearest else { return nil }

        let city = item.placemark.locality ?? item.placemark.subLocality ?? ""
        if city == "Ош" || city.lowercased() == "osh" { inOsh = true }

        let rawStreet = item.placemark.thoroughfare ?? ""
        let street = rawStreet.components(separatedBy: " ").last ?? rawStreet
        let houseNum = item.placemark.subThoroughfare ?? ""

        let parts = [street, houseNum].filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}
