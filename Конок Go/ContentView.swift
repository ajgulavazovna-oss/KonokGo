//
//  ContentView.swift
//  Конок Go
//
//  Created by продажа on 21/5/26.
//

import SwiftUI
import SwiftData

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
    var body: some View {
        NavigationStack {
            Text("Главная")
                .navigationTitle("Главная")
        }
    }
}

// MARK: - Cart

struct CartView: View {
    var body: some View {
        NavigationStack {
            Text("Корзина")
                .navigationTitle("Корзина")
        }
    }
}

// MARK: - Profile

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            Text("Профиль")
                .navigationTitle("Профиль")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
