//
//  SplashView.swift
//  Конок Go
//
//  Created by продажа on 21/5/26.
//

import SwiftUI

struct SplashView: View {
    @State private var drawProgress: CGFloat = 0
    @State private var fillOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textBlur: CGFloat = 24
    @State private var textOffset: CGFloat = 40
    @State private var splashOpacity: Double = 1
    @Binding var isFinished: Bool

    var body: some View {
        ZStack {
            Color.orange
                .ignoresSafeArea()

            VStack(spacing: 28) {
                // Logo with draw animation
                LogoDrawView(drawProgress: drawProgress, fillOpacity: fillOpacity)
                    .frame(width: 130, height: 130)

                // "Конок Go" text
                Text("Конок Go")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(textOpacity)
                    .blur(radius: textBlur)
                    .offset(y: textOffset)
            }
        }
        .opacity(splashOpacity)
        .onAppear {
            runAnimation()
        }
    }

    private func runAnimation() {
        // Phase 1 — draw logo stroke top → bottom
        withAnimation(.easeInOut(duration: 1.4)) {
            drawProgress = 1.0
        }

        // Phase 2 — fill logo
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeIn(duration: 0.4)) {
                fillOpacity = 1.0
            }
        }

        // Phase 3 — text rises from bottom with blur clear
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                textOffset = 0
            }
            withAnimation(.easeOut(duration: 0.8)) {
                textOpacity = 1.0
                textBlur = 0
            }
        }

        // Phase 4 — fade out splash
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeInOut(duration: 0.5)) {
                splashOpacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
            isFinished = true
        }
    }
}

// MARK: - Logo Draw View

struct LogoDrawView: View {
    let drawProgress: CGFloat
    let fillOpacity: Double

    var body: some View {
        GeometryReader { geo in
            let logoHeight = geo.size.height
            let drawY = logoHeight * drawProgress

            ZStack(alignment: .top) {
                // Filled logo — fades in after draw
                Image("Logo")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .opacity(fillOpacity)

                // Masked stroke reveal — top to bottom wipe
                Image("Logo")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundStyle(.white.opacity(0.55))
                    .mask(
                        VStack(spacing: 0) {
                            Color.white.frame(height: drawY)
                            Color.clear
                        }
                        .frame(maxHeight: .infinity, alignment: .top)
                    )
                    .opacity(fillOpacity < 1 ? 1 : 0)

                // Glowing draw line
                if drawProgress > 0 && drawProgress < 1 {
                    ZStack {
                        // Glow
                        Capsule()
                            .fill(Color.white.opacity(0.35))
                            .frame(height: 6)
                            .blur(radius: 4)
                            .offset(y: drawY - 3)

                        // Sharp line
                        Capsule()
                            .fill(Color.white.opacity(0.9))
                            .frame(height: 2)
                            .offset(y: drawY - 1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

#Preview {
    SplashView(isFinished: .constant(false))
}
