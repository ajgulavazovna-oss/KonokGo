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

                        // Address field — tap to open search
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
                if let addr {
                    address = addr
                }
                isOutsideOsh = !inOsh
            }
        }
    }

    // MARK: — Forward Geocode (address text → map coordinates)

    private func forwardGeocode(_ query: String) {
        Task {
            guard let loc = try? await CLGeocoder().geocodeAddressString(query).first?.location else { return }
            await MainActor.run {
                withAnimation {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: loc.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                }
            }
        }
    }

    // MARK: — Center on user

    private func centerOnUser() {
        locationManager.refreshLocation()
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
                // Running logo
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
            // Text appears
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                appear = true
            }
            // Logo runs in from left
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
                runX = 0
            }
            // Bob up/down loop
            withAnimation(.easeInOut(duration: 0.28).repeatForever(autoreverses: true).delay(0.5)) {
                bobY = -8
            }
            // Auto-dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                onDismiss()
            }
        }
    }
}

#Preview {
    AddressMapView()
        .environmentObject(LocationManager())
}
