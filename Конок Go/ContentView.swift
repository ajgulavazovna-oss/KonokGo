//
//  ContentView.swift
//  Конок Go
//
//  Created by продажа on 21/5/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabContent(selectedTab: selectedTab)
            LiquidGlassTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Tab Content

struct TabContent: View {
    let selectedTab: Int

    var body: some View {
        switch selectedTab {
        case 0:
            HomeView()
        case 1:
            CartView()
        case 2:
            ProfileView()
        default:
            HomeView()
        }
    }
}

// MARK: - Liquid Glass Tab Bar

struct LiquidGlassTabBar: View {
    @Binding var selectedTab: Int

    private let tabs: [(title: String, icon: String)] = [
        ("Главная", "house.fill"),
        ("Корзина", "cart.fill"),
        ("Профиль", "person.fill")
    ]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)

            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    TabBarButton(
                        title: tabs[index].title,
                        icon: tabs[index].icon,
                        isSelected: selectedTab == index
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(height: 72)
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}

// MARK: - Tab Bar Button

struct TabBarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.orange,
                                        Color.orange.opacity(0.75)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 32)
                            .shadow(color: Color.orange.opacity(0.45), radius: 8, x: 0, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
                            )
                    }
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : Color.primary.opacity(0.45))
                        .frame(width: 52, height: 32)
                        .scaleEffect(isSelected ? 1.08 : 1.0)
                }

                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? Color.orange : Color.primary.opacity(0.45))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Home View

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(0..<8, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.orange.opacity(0.08))
                            .frame(height: 90)
                            .overlay(
                                Text("Товар")
                                    .font(.headline)
                                    .foregroundStyle(Color.orange)
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            .navigationTitle("Главная")
        }
    }
}

// MARK: - Cart View

struct CartView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Image(systemName: "cart")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.orange.opacity(0.4))
                Text("Корзина пуста")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 12)
                Spacer()
            }
            .navigationTitle("Корзина")
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.orange.opacity(0.4), radius: 16, x: 0, y: 8)
                    Image(systemName: "person.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                }

                Text("Профиль")
                    .font(.title)
                    .bold()

                Text("Здесь будет ваш профиль")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .navigationTitle("Профиль")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
