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
        reverseGeocodeCoordinate(location.coordinate) { [weak self] address, inOsh in
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
        Task {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                guard let placemark = placemarks.first else {
                    let fallback = await nearbyAddress(coordinate: coordinate)
                    completion(fallback.0, fallback.1)
                    return
                }

                let city = placemark.locality ?? ""
                let inOsh = city == "Ош" || city.lowercased() == "osh"
                let street = placemark.thoroughfare ?? ""
                let num = placemark.subThoroughfare ?? ""

                if !street.isEmpty && !num.isEmpty {
                    // Full address: street + house number
                    completion("\(street), \(num)", inOsh)
                } else if !street.isEmpty {
                    // Only street — try MKLocalSearch fallback to find house number
                    let fallback = await nearbyAddress(coordinate: coordinate)
                    if let addr = fallback.0 {
                        completion(addr, fallback.1 || inOsh)
                    } else {
                        completion(street, inOsh)
                    }
                } else {
                    let fallback = await nearbyAddress(coordinate: coordinate)
                    completion(fallback.0, fallback.1)
                }
            } catch {
                let fallback = await nearbyAddress(coordinate: coordinate)
                completion(fallback.0, fallback.1)
            }
        }
    }

    // MKLocalSearch fallback — finds nearest named address with house number within ~300 m
    private func nearbyAddress(coordinate: CLLocationCoordinate2D) async -> (String?, Bool) {
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = "дом"
        req.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
        )
        req.resultTypes = .address

        guard let resp = try? await MKLocalSearch(request: req).start(),
              !resp.mapItems.isEmpty else { return (nil, false) }

        let here = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let nearest = resp.mapItems.min { a, b in
            let aDist = a.placemark.location?.distance(from: here) ?? .infinity
            let bDist = b.placemark.location?.distance(from: here) ?? .infinity
            return aDist < bDist
        }
        guard let item = nearest else { return (nil, false) }

        let placemark = item.placemark
        let city = placemark.locality ?? ""
        let inOsh = city == "Ош" || city.lowercased() == "osh"
        let street = placemark.thoroughfare ?? ""
        let houseNum = placemark.subThoroughfare ?? ""

        let parts = [street, houseNum].filter { !$0.isEmpty }
        return (parts.isEmpty ? nil : parts.joined(separator: ", "), inOsh)
    }
}
