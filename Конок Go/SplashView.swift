//
//  SplashView.swift
//  Конок Go
//
//  Created by продажа on 21/5/26.
//

import SwiftUI

// MARK: - Splash View

struct SplashView: View {
    @Binding var isFinished: Bool

    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.85
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 30

    private let orange = Color(red: 254/255, green: 134/255, blue: 5/255)

    var body: some View {
        ZStack {
            orange.ignoresSafeArea()

            VStack(spacing: 16) {
                Image("Logo")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(.white)
                    .scaledToFit()
                    .frame(width: 240, height: 189)
                    .opacity(logoOpacity)
                    .scaleEffect(logoScale)

                Text("Конок Go")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(textOpacity)
                    .offset(y: textOffset)
            }
        }
        .ignoresSafeArea()
        .onAppear { startAnimation() }
    }

    private func startAnimation() {
        // Phase 1 — логотип появляется
        withAnimation(.easeOut(duration: 0.7)) {
            logoOpacity = 1.0
            logoScale = 1.0
        }

        // Phase 2 — текст выезжает снизу
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                textOffset = 0
                textOpacity = 1.0
            }
        }

        // Phase 3 — экран исчезает мгновенно
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isFinished = true
        }
    }
}

#Preview {
    SplashView(isFinished: .constant(false))
}
