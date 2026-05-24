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
    private let mkGeocoder = MKGeocoder()

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
        Task {
            // Primary: MKGeocoder (iOS 26 API)
            var inOsh = false
            var street: String? = nil
            var num: String? = nil

            if let items = try? await mkGeocoder.reverseGeocode(MKGeocodingRequest(coordinate: coordinate)),
               let item = items.first {
                let addr = item.addressRepresentations.first
                let city = addr?.locality ?? ""
                inOsh = city == "Ош" || city.lowercased() == "osh"
                if let raw = addr?.thoroughfare {
                    street = raw.components(separatedBy: " ").last ?? raw
                }
                num = addr?.subThoroughfare
            }

            // Fallback: MKLocalSearch when street or house number missing
            if street == nil || num == nil {
                let (fallbackAddr, fallbackInOsh) = await nearbyAddress(coordinate: coordinate)
                if let addr = fallbackAddr {
                    completion(addr, fallbackInOsh || inOsh)
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
        let nearest = resp.mapItems.min {
            ($0.location?.distance(from: here) ?? .infinity) < ($1.location?.distance(from: here) ?? .infinity)
        }
        guard let item = nearest else { return (nil, false) }

        let addr = item.addressRepresentations.first
        let city = addr?.locality ?? ""
        let inOsh = city == "Ош" || city.lowercased() == "osh"
        let rawStreet = addr?.thoroughfare ?? ""
        let street = rawStreet.components(separatedBy: " ").last ?? rawStreet
        let houseNum = addr?.subThoroughfare ?? ""

        let parts = [street, houseNum].filter { !$0.isEmpty }
        return (parts.isEmpty ? nil : parts.joined(separator: ", "), inOsh)
    }
}
