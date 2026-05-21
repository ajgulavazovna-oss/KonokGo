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

                ContentView()
                    .opacity(splashFinished ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: splashFinished)

                if !splashFinished {
                    SplashView(isFinished: $splashFinished)
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
