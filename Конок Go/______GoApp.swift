//
//  ______GoApp.swift
//  Конок Go
//
//  Created by продажа on 21/5/26.
//

import SwiftUI
import SwiftData

@main
struct ______GoApp: App {
    @State private var splashFinished = false
    @State private var isAuthenticated: Bool = UserDefaults.standard.bool(forKey: "konok_isAuthenticated")
    @StateObject private var locationManager = LocationManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Item.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !splashFinished {
                    // Splash
                    Color(red: 254/255, green: 134/255, blue: 5/255)
                        .ignoresSafeArea()
                    SplashView(isFinished: $splashFinished)
                } else if !isAuthenticated {
                    // Auth
                    AuthView {
                        UserDefaults.standard.set(true, forKey: "konok_isAuthenticated")
                        withAnimation(.easeInOut(duration: 0.4)) {
                            isAuthenticated = true
                        }
                    }
                    .transition(.opacity)
                } else {
                    // Main App
                    ContentView(splashFinished: splashFinished)
                        .transition(.opacity)
                        .environmentObject(locationManager)
                        .onAppear { locationManager.requestPermission() }
                }
            }
            .animation(.easeInOut(duration: 0.4), value: splashFinished)
            .animation(.easeInOut(duration: 0.4), value: isAuthenticated)
            .environmentObject(locationManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
