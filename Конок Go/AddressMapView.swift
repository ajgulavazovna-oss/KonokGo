//
//  AddressMapView.swift
//  Конок Go
//

import SwiftUI
import MapKit
import CoreLocation

struct AddressMapView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var locationManager: LocationManager

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.5283, longitude: 72.7985),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
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
    @State private var showNotInOshAlert: Bool = false
    @State private var isOutsideOsh: Bool = false

    private let orange = Color(red: 254/255, green: 134/255, blue: 5/255)

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

                // MARK: — Map
                ZStack {
                    Map(position: $cameraPosition)
                        .onMapCameraChange(frequency: .continuous) { _ in
                            withAnimation(.easeOut(duration: 0.1)) { pinOffset = -10 }
                        }
                        .onMapCameraChange(frequency: .onEnd) { context in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pinOffset = 0 }
                            geocodeCenter(context.region.center)
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

                    // Buttons overlay
                    VStack {
                        HStack {
                            Button { dismiss() } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color(.label))
                                    .frame(width: 36, height: 36)
                                    .background(Color(.systemBackground))
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, geo.safeAreaInsets.top + 12)

                        Spacer()

                        HStack {
                            Spacer()
                            Button { centerOnUser() } label: {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(orange)
                                    .frame(width: 44, height: 44)
                                    .background(Color(.systemBackground))
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 16)
                            .padding(.bottom, 12)
                        }
                    }

                    // Outside Osh warning banner
                    if isOutsideOsh {
                        VStack {
                            Spacer()
                            Text("😔 Мы пока не работаем в этом месте")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.black.opacity(0.75))
                                .clipShape(Capsule())
                                .padding(.bottom, 8)
                        }
                    }
                }
                .frame(height: geo.size.height * 0.48)

                // MARK: — Form
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {

                        // Address field
                        HStack {
                            TextField("Улица и дом", text: $address)
                                .font(.system(size: 15))
                            if isGeocoding {
                                ProgressView().scaleEffect(0.8)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

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

                        TextField("Комментарий для курьера", text: $comment)
                            .font(.system(size: 15))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }
                .scrollDismissesKeyboard(.interactively)

                // MARK: — Continue button (pinned)
                VStack(spacing: 0) {
                    Button {
                        if isOutsideOsh {
                            showNotInOshAlert = true
                        } else if address.trimmingCharacters(in: .whitespaces).isEmpty {
                            showNotInOshAlert = true
                        } else {
                            locationManager.saveAddress(address)
                            dismiss()
                        }
                    } label: {
                        Text("Продолжить")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(orange)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, geo.safeAreaInsets.bottom > 0 ? geo.safeAreaInsets.bottom : 16)
                }
                .background(Color(.systemBackground))
            }
        }
        .ignoresSafeArea(edges: .top)
        .alert("Мы здесь пока не работаем 😔", isPresented: $showNotInOshAlert) {
            Button("Понятно", role: .cancel) { }
        } message: {
            Text("Сервис доступен только в городе Ош, Кыргызстан.")
        }
        .onAppear {
            if let loc = locationManager.userLocation {
                cameraPosition = .region(MKCoordinateRegion(
                    center: loc.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
                geocodeCenter(loc.coordinate)
            }
        }
        .onChange(of: locationManager.userLocation) { _, loc in
            guard let loc else { return }
            cameraPosition = .region(MKCoordinateRegion(
                center: loc.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }

    // MARK: — Geocode center

    private func geocodeCenter(_ coordinate: CLLocationCoordinate2D) {
        isGeocoding = true
        isOutsideOsh = false
        locationManager.reverseGeocodeCoordinate(coordinate) { addr, inOsh in
            DispatchQueue.main.async {
                isGeocoding = false
                if let addr {
                    address = addr
                }
                isOutsideOsh = !inOsh
            }
        }
    }

    // MARK: — Center on user

    private func centerOnUser() {
        locationManager.requestPermission()
        if let loc = locationManager.userLocation {
            withAnimation {
                cameraPosition = .region(MKCoordinateRegion(
                    center: loc.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }
    }
}

#Preview {
    AddressMapView()
        .environmentObject(LocationManager())
}
