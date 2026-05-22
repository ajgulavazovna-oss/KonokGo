//
//  AddressMapView.swift
//  Конок Go
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Address Map View

struct AddressMapView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.5283, longitude: 72.7985),
            span: MKCoordinateSpan(latitudeDelta: 4.0, longitudeDelta: 4.0)
        )
    )
    @State private var address: String = ""
    @State private var selectedType: AddressType = .home
    @State private var entrance: String = ""
    @State private var intercom: String = ""
    @State private var floor: String = ""
    @State private var apartment: String = ""
    @State private var comment: String = ""
    @State private var pinOffset: CGFloat = 0
    @State private var isGeocoding: Bool = false

    private let orange = Color(red: 254/255, green: 134/255, blue: 5/255)
    private let geocoder = CLGeocoder()

    enum AddressType: String, CaseIterable {
        case home  = "Дом"
        case work  = "Работа"
        case other = "Другое"

        var icon: String {
            switch self {
            case .home:  return "house"
            case .work:  return "briefcase"
            case .other: return "mappin"
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {

                // MARK: Map
                ZStack {
                    Map(position: $cameraPosition)
                        .onMapCameraChange(frequency: .continuous) { _ in
                            withAnimation(.easeOut(duration: 0.1)) { pinOffset = -10 }
                        }
                        .onMapCameraChange(frequency: .onEnd) { context in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pinOffset = 0 }
                            reverseGeocode(context.region.center)
                        }
                        .ignoresSafeArea(edges: .top)

                    // Center pin
                    VStack(spacing: 0) {
                        Circle()
                            .fill(orange)
                            .frame(width: 22, height: 22)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                        Rectangle()
                            .fill(orange)
                            .frame(width: 2.5, height: 18)
                        Circle()
                            .fill(orange.opacity(0.3))
                            .frame(width: 8, height: 4)
                            .scaleEffect(x: 1, y: 0.4)
                    }
                    .offset(y: pinOffset - 21)

                    // Close button
                    VStack {
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color(.label))
                                    .frame(width: 36, height: 36)
                                    .background(Color(.systemBackground))
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, geo.safeAreaInsets.top + 12)
                        Spacer()

                        // Location button
                        HStack {
                            Spacer()
                            Button {
                                centerOnUser()
                            } label: {
                                Image(systemName: "location")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(Color(.label))
                                    .frame(width: 44, height: 44)
                                    .background(Color(.systemBackground))
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                            }
                            .padding(.trailing, 16)
                            .padding(.bottom, 12)
                        }
                    }
                }
                .frame(height: geo.size.height * 0.50)

                // MARK: Form
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {

                        // Country
                        HStack(spacing: 8) {
                            Text("🇰🇬")
                                .font(.system(size: 18))
                            Text("Кыргызстан")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color(.label))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())

                        // Address field
                        TextField("Город, улица и дом", text: $address)
                            .font(.system(size: 15))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                isGeocoding ?
                                HStack {
                                    Spacer()
                                    ProgressView().padding(.trailing, 12)
                                } : nil
                            )

                        // Type selector
                        HStack(spacing: 8) {
                            ForEach(AddressType.allCases, id: \.self) { type in
                                Button {
                                    selectedType = type
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 12, weight: .medium))
                                        Text(type.rawValue)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundStyle(selectedType == type ? .white : Color(.secondaryLabel))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .background(selectedType == type ? orange : Color(.systemGray6))
                                    .clipShape(Capsule())
                                }
                            }
                            Spacer()
                        }

                        // Подъезд + Домофон
                        HStack(spacing: 10) {
                            TextField("Подъезд", text: $entrance)
                                .font(.system(size: 15))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 13)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            TextField("Домофон", text: $intercom)
                                .font(.system(size: 15))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 13)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        // Этаж + Квартира
                        HStack(spacing: 10) {
                            TextField("Этаж", text: $floor)
                                .font(.system(size: 15))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 13)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            TextField("Квартира", text: $apartment)
                                .font(.system(size: 15))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 13)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        // Комментарий
                        TextField("Комментарий для курьера", text: $comment)
                            .font(.system(size: 15))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        // Continue button
                        Button {
                            dismiss()
                        } label: {
                            Text("Продолжить")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(orange)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, geo.safeAreaInsets.bottom + 16)
                }
                .background(Color(.systemBackground))
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Reverse Geocode

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        isGeocoding = true
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            isGeocoding = false
            guard let placemark = placemarks?.first else { return }
            var parts: [String] = []
            if let city = placemark.locality { parts.append(city) }
            if let street = placemark.thoroughfare { parts.append(street) }
            if let number = placemark.subThoroughfare { parts.append(number) }
            address = parts.joined(separator: ", ")
        }
    }

    // MARK: - Center on User

    private func centerOnUser() {
        cameraPosition = .userLocation(fallback: .automatic)
    }
}

#Preview {
    AddressMapView()
}
