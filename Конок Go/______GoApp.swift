//
//  ______GoApp.swift
//  Конок Go
//
//  Created by продажа on 21/5/26.
//

import SwiftUI
import SwiftData
import YandexMapsMobile

@main
struct ______GoApp: App {
    @State private var splashFinished = false
    @StateObject private var locationManager = LocationManager()

    init() {
        YMKMapKit.setLocale("ru_RU")
        YMKMapKit.setApiKey("7284aedc-5194-4064-b5af-dcd0944dd279")
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
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
                Color(red: 254/255, green: 134/255, blue: 5/255)
                    .ignoresSafeArea()

                ContentView(splashFinished: splashFinished)
                    .opacity(splashFinished ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: splashFinished)

                if !splashFinished {
                    SplashView(isFinished: $splashFinished)
                }
            }
            .environmentObject(locationManager)
            .onAppear {
                locationManager.requestPermission()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
