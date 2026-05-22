//
//  ContentView.swift
//  Конок Go
//
//  Created by продажа on 21/5/26.
//

import SwiftUI
import SwiftData

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    static let inputBackground = Color(.systemGray6)
}

// MARK: - Root

struct ContentView: View {
    var splashFinished: Bool
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            Tab("Главная", systemImage: "house.fill", value: 0) {
                HomeView(splashFinished: splashFinished)
            }
            Tab("Корзина", systemImage: "cart.fill", value: 1) {
                CartView()
            }
            Tab("Профиль", systemImage: "person.fill", value: 2) {
                ProfileView()
            }
        }
        .tint(.orange)
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

// MARK: - Address Prompt Sheet

struct AddressPromptSheet: View {
    @Binding var isPresented: Bool
    @Binding var showMap: Bool
    @EnvironmentObject var locationManager: LocationManager

    private let orange = Color(red: 254/255, green: 134/255, blue: 5/255)

    var body: some View {
        VStack(spacing: 12) {
            Image("Logo")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(orange)
                .scaledToFit()
                .frame(width: 44, height: 44)

            Text("Укажите адрес для заказа")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(.label))

            HStack(spacing: 12) {
                Button {
                    isPresented = false
                } label: {
                    Text("Пропустить")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(.secondaryLabel))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }

                Button {
                    isPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showMap = true
                    }
                } label: {
                    Text("Указать")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(orange)
                        .clipShape(Capsule())
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Home

struct HomeView: View {
    var splashFinished: Bool
    @EnvironmentObject var locationManager: LocationManager
    @State private var selectedSegment: Int = 0
    @State private var showAddressPrompt: Bool = false
    @State private var showAddressMap: Bool = false
    @State private var showAddressSearch: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AppHeader(selectedSegment: $selectedSegment, showAddressSearch: $showAddressSearch)
                BannersSection()
                    .padding(.top, 6)
                Spacer(minLength: 100)
            }
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showAddressPrompt) {
            AddressPromptSheet(isPresented: $showAddressPrompt, showMap: $showAddressMap)
                .presentationDetents([.fraction(0.28)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
                .environmentObject(locationManager)
        }
        .fullScreenCover(isPresented: $showAddressMap) {
            AddressMapView()
                .environmentObject(locationManager)
        }
        .sheet(isPresented: $showAddressSearch) {
            AddressSearchSheet()
                .presentationDetents([.fraction(0.70)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
                .environmentObject(locationManager)
        }
        .onChange(of: splashFinished) { _, finished in
            if finished && !locationManager.hasAddress {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showAddressPrompt = true
                }
            }
        }
        .onChange(of: locationManager.hasAddress) { _, hasAddr in
            if hasAddr {
                showAddressPrompt = false
                showAddressMap = false
                showAddressSearch = false
            }
        }
    }
}

// MARK: - Banners Section

struct BannerItem: Identifiable {
    let id = UUID()
    let imageName: String?
    let backgroundColor: Color
    let title: String
}

struct BannersSection: View {
    private let banners: [BannerItem] = [
        BannerItem(imageName: "Banner1",   backgroundColor: .clear,                            title: "Дино\nмастер-р-р\nкласс"),
        BannerItem(imageName: "Banner2",   backgroundColor: .clear,                            title: ""),
        BannerItem(imageName: nil,         backgroundColor: Color(red: 0.13, green: 0.13, blue: 0.18), title: "Новинка"),
        BannerItem(imageName: nil,         backgroundColor: Color(red: 0.35, green: 0.60, blue: 0.90), title: "Как развлечь\nмалыша?"),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(banners) { banner in
                    BannerCard(banner: banner)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }
}

struct BannerCard: View {
    let banner: BannerItem
    private let cardW: CGFloat = 110
    private let cardH: CGFloat = 135

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image or color
            if let name = banner.imageName {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardW, height: cardH)
                    .clipped()
            } else {
                banner.backgroundColor
            }

            // Dark overlay for text readability
            Color.black.opacity(0.32)

            // Title
            Text(banner.title)
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
        }
        .frame(width: cardW, height: cardH)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - App Header

struct AppHeader: View {
    @Binding var selectedSegment: Int
    @Binding var showAddressSearch: Bool
    @State private var searchText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            AddressRow(showAddressSearch: $showAddressSearch)
            SearchBar(text: $searchText)
            SegmentSwitcher(selected: $selectedSegment)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .background(Color(.systemBackground))
    }
}

// MARK: - Address Row

struct AddressRow: View {
    @Binding var showAddressSearch: Bool
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        Button {
            showAddressSearch = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 48, height: 48)
                    Image("Logo")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(locationManager.userAddress.isEmpty ? "Укажите адрес" : locationManager.userAddress)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(.label))
                            .lineLimit(1)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(.label))
                    }
                    Text("Круглосуточно")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color(.secondaryLabel))
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(.tertiaryLabel))
            TextField("Поиск", text: $text)
                .font(.system(size: 16))
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.inputBackground)
        .clipShape(Capsule())
    }
}

// MARK: - Segment Switcher

struct SegmentSwitcher: View {
    @Binding var selected: Int

    private let segments: [(title: String, subtitle: String)] = [
        ("Еда", "Рестораны и кафе"),
        ("Супермаркеты", "Продукты и товары")
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.inputBackground)
                    .frame(height: 52)

                // Active pill
                RoundedRectangle(cornerRadius: 29, style: .continuous)
                    .fill(Color.orange)
                    .frame(width: (geo.size.width - 8) / 2, height: 44)
                    .padding(.leading, selected == 0 ? 4 : (geo.size.width - 8) / 2 + 4)
                    .animation(.spring(response: 0.3, dampingFraction: 0.75), value: selected)

                // Labels
                HStack(spacing: 0) {
                    ForEach(0..<segments.count, id: \.self) { index in
                        Button {
                            UISelectionFeedbackGenerator().selectionChanged()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                selected = index
                            }
                        } label: {
                            VStack(spacing: 1) {
                                Text(segments[index].title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(selected == index ? .white : Color(.secondaryLabel))
                                Text(segments[index].subtitle)
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(selected == index ? .white.opacity(0.85) : Color(.tertiaryLabel))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(height: 52)
    }
}

// MARK: - Cart

struct CartView: View {
    var body: some View {
        Color.clear
    }
}

// MARK: - Profile

struct ProfileView: View {
    var body: some View {
        Color.clear
    }
}

#Preview {
    ContentView(splashFinished: true)
        .environmentObject(LocationManager())
        .modelContainer(for: Item.self, inMemory: true)
}
