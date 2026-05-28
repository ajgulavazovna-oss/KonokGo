//
//  AddressMapView.swift
//  Конок Go
//

import SwiftUI
import MapKit
import CoreLocation
import YandexMapsMobile

// MARK: - Yandex Map Controller

final class YandexMapController: ObservableObject {
    weak var mapView: YMKMapView?

    func moveTo(_ coord: CLLocationCoordinate2D, zoom: Float = 16, animated: Bool = true) {
        guard let mapView else { return }
        let target = YMKPoint(latitude: coord.latitude, longitude: coord.longitude)
        let pos = YMKCameraPosition(target: target, zoom: zoom, azimuth: 0, tilt: 0)
        if animated {
            mapView.mapWindow.map.move(
                with: pos,
                animation: YMKAnimation(type: .smooth, duration: 0.5),
                cameraCallback: nil
            )
        } else {
            mapView.mapWindow.map.move(with: pos)
        }
    }
}

// MARK: - Yandex Map UIViewRepresentable

struct YandexMapRepresentable: UIViewRepresentable {
    let controller: YandexMapController
    let initialCoord: CLLocationCoordinate2D
    var onCameraMoving: () -> Void
    var onCameraIdle: (CLLocationCoordinate2D) -> Void

    func makeUIView(context: Context) -> YMKMapView {
        let mapView = YMKMapView(frame: .zero)
        controller.mapView = mapView
        mapView.mapWindow.map.addCameraListener(with: context.coordinator)
        let target = YMKPoint(latitude: initialCoord.latitude, longitude: initialCoord.longitude)
        let pos = YMKCameraPosition(target: target, zoom: 14, azimuth: 0, tilt: 0)
        mapView.mapWindow.map.move(with: pos)
        return mapView
    }

    func updateUIView(_ uiView: YMKMapView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCameraMoving: onCameraMoving, onCameraIdle: onCameraIdle)
    }

    final class Coordinator: NSObject, YMKMapCameraListener {
        var onCameraMoving: () -> Void
        var onCameraIdle: (CLLocationCoordinate2D) -> Void

        init(onCameraMoving: @escaping () -> Void, onCameraIdle: @escaping (CLLocationCoordinate2D) -> Void) {
            self.onCameraMoving = onCameraMoving
            self.onCameraIdle = onCameraIdle
        }

        func onCameraPositionChanged(
            with map: YMKMap,
            cameraPosition: YMKCameraPosition,
            cameraUpdateReason: YMKCameraUpdateReason,
            finished: Bool
        ) {
            DispatchQueue.main.async {
                if finished {
                    let coord = CLLocationCoordinate2D(
                        latitude: cameraPosition.target.latitude,
                        longitude: cameraPosition.target.longitude
                    )
                    self.onCameraIdle(coord)
                } else {
                    self.onCameraMoving()
                }
            }
        }
    }
}

// MARK: - Address Map View

struct AddressMapView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var locationManager: LocationManager

    @StateObject private var mapController = YandexMapController()

    private let defaultCoord = CLLocationCoordinate2D(latitude: 40.5283, longitude: 72.7985)

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
    @State private var showSearchSheet: Bool = false

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
                    YandexMapRepresentable(
                        controller: mapController,
                        initialCoord: locationManager.userLocation?.coordinate ?? defaultCoord,
                        onCameraMoving: {
                            withAnimation(.easeOut(duration: 0.1)) { pinOffset = -10 }
                        },
                        onCameraIdle: { coord in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pinOffset = 0 }
                            geocodeCenter(coord)
                        }
                    )
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
                        .padding(.top, 72)

                        Spacer()

                        HStack {
                            Spacer()
                            Button { centerOnUser() } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(.systemBackground))
                                        .frame(width: 56, height: 56)
                                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(orange)
                                }
                            }
                            .padding(.trailing, 16)
                            .padding(.bottom, 12)
                        }
                    }

                    // Outside Osh warning
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

                        Button {
                            showSearchSheet = true
                        } label: {
                            HStack {
                                Text(address.isEmpty ? "Улица и дом" : address)
                                    .font(.system(size: 15))
                                    .foregroundStyle(address.isEmpty ? Color(.placeholderText) : Color(.label))
                                    .lineLimit(1)
                                Spacer()
                                if isGeocoding {
                                    ProgressView().scaleEffect(0.8)
                                } else {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(.tertiaryLabel))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

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

                // MARK: — Continue button
                VStack(spacing: 0) {
                    Button {
                        if isOutsideOsh || address.trimmingCharacters(in: .whitespaces).isEmpty {
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
        .sheet(isPresented: $showSearchSheet) {
            AddressSearchSheet()
                .presentationDetents([.fraction(0.70)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
                .environmentObject(locationManager)
        }
        .alert("Мы здесь пока не работаем 😔", isPresented: $showNotInOshAlert) {
            Button("Понятно", role: .cancel) { }
        } message: {
            Text("Сервис доступен только в городе Ош, Кыргызстан.")
        }
        .onAppear {
            if let loc = locationManager.userLocation {
                mapController.moveTo(loc.coordinate, animated: false)
                geocodeCenter(loc.coordinate)
            }
        }
        .onChange(of: locationManager.userLocation) { _, loc in
            guard let loc else { return }
            mapController.moveTo(loc.coordinate)
        }
        .onChange(of: locationManager.userAddress) { _, newAddress in
            guard !newAddress.isEmpty else { return }
            address = newAddress
            forwardGeocode(newAddress)
        }
    }

    // MARK: — Geocode center

    private func geocodeCenter(_ coordinate: CLLocationCoordinate2D) {
        isGeocoding = true
        isOutsideOsh = false
        locationManager.reverseGeocodeCoordinate(coordinate) { addr, inOsh in
            DispatchQueue.main.async {
                isGeocoding = false
                if let addr { address = addr }
                isOutsideOsh = !inOsh
            }
        }
    }

    // MARK: — Forward Geocode

    private func forwardGeocode(_ query: String) {
        Task {
            guard let loc = try? await CLGeocoder().geocodeAddressString(query).first?.location else { return }
            await MainActor.run {
                mapController.moveTo(loc.coordinate)
            }
        }
    }

    // MARK: — Center on user

    private func centerOnUser() {
        locationManager.refreshLocation()
        if let loc = locationManager.userLocation {
            mapController.moveTo(loc.coordinate)
        }
    }
}

// MARK: - Address Saved Overlay

struct AddressSavedOverlay: View {
    let orange: Color
    let onDismiss: () -> Void

    @State private var runX: CGFloat = -160
    @State private var bobY: CGFloat = 0
    @State private var appear: Bool = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(orange.opacity(0.12))
                        .frame(width: 130, height: 130)

                    Image("Logo")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundStyle(orange)
                        .frame(width: 80, height: 80)
                        .offset(x: runX, y: bobY)
                }
                .frame(width: 130, height: 130)
                .clipped()

                VStack(spacing: 8) {
                    Text("Адрес сохранён!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color(.label))

                    Text("Курьер доставит заказ\nпо указанному адресу")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(.secondaryLabel))
                        .multilineTextAlignment(.center)
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) { appear = true }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) { runX = 0 }
            withAnimation(.easeInOut(duration: 0.28).repeatForever(autoreverses: true).delay(0.5)) { bobY = -8 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { onDismiss() }
        }
    }
}

#Preview {
    AddressMapView()
        .environmentObject(LocationManager())
}
