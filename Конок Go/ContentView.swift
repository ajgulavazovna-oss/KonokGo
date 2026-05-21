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
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            Tab("Главная", systemImage: "house.fill", value: 0) {
                HomeView()
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

// MARK: - Home

struct HomeView: View {
    @State private var selectedSegment: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            AppHeader(selectedSegment: $selectedSegment)
            Spacer()
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - App Header

struct AppHeader: View {
    @Binding var selectedSegment: Int
    @State private var searchText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            AddressRow()
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
    var body: some View {
        HStack(spacing: 12) {
            // Logo
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

            // Address text
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("Укажите адрес")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(.label))
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
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
