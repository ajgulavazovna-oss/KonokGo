//
//  SplashView.swift
//  Конок Go
//
//  Created by продажа on 21/5/26.
//

import SwiftUI

// MARK: - SVG Path Parser

private func tokenizeSVG(_ d: String) -> [String] {
    var tokens: [String] = []
    var current = ""
    for char in d {
        if char.isLetter {
            if !current.isEmpty { tokens.append(current); current = "" }
            tokens.append(String(char))
        } else if char == "-" {
            if !current.isEmpty { tokens.append(current) }
            current = "-"
        } else if char == " " || char == "," || char == "\n" || char == "\t" {
            if !current.isEmpty { tokens.append(current); current = "" }
        } else {
            current.append(char)
        }
    }
    if !current.isEmpty { tokens.append(current) }
    return tokens
}

private func buildCGPath(from tokens: [String]) -> CGPath {
    let path = CGMutablePath()
    var i = 0
    var cx: CGFloat = 0
    var cy: CGFloat = 0

    func next() -> CGFloat {
        guard i < tokens.count else { return 0 }
        let v = CGFloat(Double(tokens[i]) ?? 0)
        i += 1
        return v
    }

    while i < tokens.count {
        let cmd = tokens[i]; i += 1
        switch cmd {
        case "M":
            cx = next(); cy = next()
            path.move(to: CGPoint(x: cx, y: cy))
        case "C":
            let x1 = next(), y1 = next()
            let x2 = next(), y2 = next()
            cx = next(); cy = next()
            path.addCurve(to: CGPoint(x: cx, y: cy),
                          control1: CGPoint(x: x1, y: y1),
                          control2: CGPoint(x: x2, y: y2))
        case "L":
            cx = next(); cy = next()
            path.addLine(to: CGPoint(x: cx, y: cy))
        case "H":
            cx = next()
            path.addLine(to: CGPoint(x: cx, y: cy))
        case "V":
            cy = next()
            path.addLine(to: CGPoint(x: cx, y: cy))
        case "Z":
            path.closeSubpath()
        default:
            break
        }
    }
    return path
}

// MARK: - Logo Shape

struct LogoShape: Shape {

    // Original SVG viewBox: 0 0 295 232
    private static let viewW: CGFloat = 295
    private static let viewH: CGFloat = 232

    private static let rawPath: CGPath = {
        let d = "M161.571 2.47876C163.077 3.59255 164.951 5.81588 165.736 7.41986C169.934 15.9903 159.416 34.4873 150.343 34.4873C143.882 34.4873 138.384 27.7337 138.384 19.7964C138.384 17.3338 137.782 16.6223 135.028 15.8325C130.121 14.4244 130.176 12.5759 135.15 11.7352C141.213 10.7104 141.348 9.39439 135.475 8.57493C132.71 8.1885 129.258 7.23035 127.804 6.44477L125.159 5.01548L127.804 4.36754C138.554 1.73131 151.226 -0.307806 154.693 0.038399C156.971 0.266026 160.066 1.36392 161.571 2.47876ZM204.093 19.7689C205.431 21.1082 206.138 22.9038 205.872 24.2928C205.1 28.3372 179.416 61.954 176.509 62.7258C174.21 63.3356 142.657 61.2097 141.729 60.3818C141.532 60.206 142.603 58.2463 144.11 56.0283C145.616 53.8092 146.849 51.0903 146.849 49.9861C146.849 48.2053 147.417 48.0518 151.875 48.6288C154.64 48.9856 160.277 49.5848 164.403 49.9596L171.903 50.6404L183.341 35.9473C198.833 16.0453 199.697 15.3709 204.093 19.7689ZM115.749 27.1144C128.825 31.4753 135.66 34.301 137.265 36.0098C140.136 39.0685 141.227 46.0561 139.489 50.255C138.406 52.869 128.352 62.4886 109.652 78.7984L105.787 82.1694L111.508 64.4166C114.655 54.6519 117.505 45.64 117.841 44.3896C118.494 41.9662 115.833 40.6312 101.208 36.0469L95.2479 34.1793L81.6327 43.7025C60.9545 58.1669 62.6729 57.2754 59.49 55.1887C57.36 53.7933 56.8521 52.6943 57.1092 50.038C57.4013 47.0291 59.3176 45.2567 74.794 33.6933C84.3416 26.5606 93.1496 20.7239 94.3696 20.7239C95.5886 20.7239 105.209 23.5994 115.749 27.1144ZM255.217 51.4863C258.759 52.5874 264.653 55.2681 268.316 57.4427C275.292 61.5866 286.524 71.3523 286.524 73.275C286.524 73.8911 282.275 77.981 277.081 82.3621L267.637 90.329L262.226 85.246C255.609 79.0292 249.619 76.0224 241.134 74.6545C212.77 70.085 186.156 97.3134 191.167 125.775C193.242 137.566 200.33 145.901 211.669 149.889C223.069 153.897 237.137 151.583 247.462 144C251.805 140.81 257.954 133.525 257.954 131.569C257.954 131.163 250.842 130.832 242.151 130.832C233.459 130.832 225.151 130.377 223.688 129.821C214.302 126.25 215.945 110.375 225.991 107.583C228.262 106.952 242.776 106.491 260.457 106.487L291 106.481L290.244 112.569C288.235 128.743 280.842 143.76 269.038 155.641C256.05 168.715 241.71 175.239 224.094 176.087C191.506 177.657 166.531 156.6 164.137 125.538C162.49 104.162 173.11 80.3695 190.634 66.1698C197.344 60.7343 209.927 53.7245 217.112 51.4217C228.117 47.894 243.741 47.9205 255.217 51.4863ZM101.204 71.2782C98.9979 82.7781 96.4827 94.0938 95.614 96.423C93.7707 101.367 93.5305 107.607 94.9844 112.833C96.6785 118.925 101.487 123.614 111.264 128.709C116.286 131.326 120.396 133.771 120.396 134.141C120.396 134.512 118.767 136.058 116.777 137.577L113.159 140.338L108.259 133.468C105.564 129.688 102.964 126.597 102.482 126.597C100.615 126.597 86.5351 140.993 86.5351 142.902C86.5351 145.168 75.7336 196.923 70.1074 221.618C69.608 223.808 68.9721 224 62.1777 224C58.1145 224 54.7908 223.718 54.7908 223.375C54.7908 222.797 91.2216 58.0875 92.5295 52.7504C93.0501 50.6256 93.7675 50.3683 99.164 50.3683H105.216L101.204 71.2782ZM153.325 68.5096C160.265 69.2253 165.814 70.0988 165.656 70.4503C165.497 70.8028 157.748 77.9302 148.436 86.2899C139.125 94.6497 130.408 102.532 129.065 103.806L126.624 106.12L139.777 113.696C154.485 122.169 156.458 124.551 154.686 131.695C153.835 135.124 151.311 137.385 132.214 151.838L110.702 168.118L111.445 177.041C112.088 184.767 111.935 186.244 110.307 188.042C109.274 189.186 107.874 190.121 107.195 190.121C106.518 190.121 103.419 184.614 100.308 177.884C94.7643 165.887 94.6923 165.61 96.6785 163.752C97.7927 162.71 105.846 155.768 114.576 148.325C123.306 140.883 131.087 134.199 131.869 133.47C133.029 132.39 130.936 130.916 120.493 125.459C104.901 117.31 102.289 114.838 101.591 107.57C100.668 97.955 102.866 94.4379 119.149 79.4876C132.663 67.0793 133.857 66.2313 137.165 66.7034C139.113 66.9808 146.386 67.7939 153.325 68.5096ZM77.5737 86.1004C77.1695 88.8669 76.4648 91.5179 76.0077 91.9944C75.5516 92.4697 63.7586 92.708 49.8017 92.5237C22.6614 92.1648 20.9303 91.8229 20.9303 86.8278C20.9303 85.4768 21.526 83.9872 22.253 83.5161C24.0391 82.3589 38.8827 81.4822 60.4667 81.2567L78.3102 81.0715L77.5737 86.1004ZM73.1083 104.628C72.7359 106.52 72.1179 109.26 71.7338 110.716L71.0365 113.363L58.9546 112.974C45.3564 112.538 42.5905 111.833 41.5461 108.541C39.9324 103.454 45.3268 101.945 67.1976 101.363L73.7845 101.187L73.1083 104.628ZM31.6927 103.998C33.9031 106 34.228 109.692 32.3582 111.563C31.517 112.405 26.9501 112.833 18.814 112.833C5.83482 112.833 4 112.227 4 107.932C4 103.202 6.44431 102.246 18.5421 102.246C27.4939 102.246 30.1488 102.6 31.6927 103.998ZM68.189 128.185L67.1351 134.008L45.8845 133.992C30.9234 133.981 23.8508 133.581 21.9884 132.642C19.1082 131.19 17.922 127.067 19.833 125.152C21.0562 123.927 36.1072 122.886 57.5208 122.547L69.244 122.362L68.189 128.185ZM64.3078 144.331C64.3046 145.35 63.8062 147.97 63.1999 150.154L62.0984 154.124H47.7933C39.9261 154.124 32.5677 153.63 31.4419 153.028C28.9372 151.687 28.7679 147.495 31.1392 145.518C32.8481 144.096 42.6127 143.022 57.1717 142.657C63.3385 142.502 64.3131 142.731 64.3078 144.331ZM159.85 160.302C164.339 167.775 168.012 174.207 168.012 174.594C168.012 174.982 160.508 175.298 151.337 175.298C136.583 175.298 134.532 175.085 133.552 173.446C132.941 172.426 131.368 169.821 130.055 167.653L127.668 163.715L139.111 155.24C145.404 150.578 150.808 146.753 151.12 146.738C151.432 146.724 155.361 152.828 159.85 160.302Z"
        return buildCGPath(from: tokenizeSVG(d))
    }()

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width / Self.viewW, rect.height / Self.viewH)
        let dx = (rect.width  - Self.viewW * scale) / 2 + rect.minX
        let dy = (rect.height - Self.viewH * scale) / 2 + rect.minY
        let transform = CGAffineTransform(translationX: dx, y: dy).scaledBy(x: scale, y: scale)
        return Path(Self.rawPath).applying(transform)
    }
}

// MARK: - Animated Logo

struct AnimatedLogo: View {
    var strokeProgress: CGFloat   // 0 → 1  stroke draws
    var fillOpacity: Double        // 0 → 1  fill fades in

    var body: some View {
        ZStack {
            // Filled logo — crisp, fully white
            LogoShape()
                .fill(Color.white)
                .opacity(fillOpacity)

            // Stroke that draws — thicker for visibility
            LogoShape()
                .trim(from: 0, to: strokeProgress)
                .stroke(
                    Color.white,
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
                )
                .opacity(1 - fillOpacity)
        }
    }
}

// MARK: - Splash View

struct SplashView: View {
    @Binding var isFinished: Bool

    @State private var strokeProgress: CGFloat = 0
    @State private var fillOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    @State private var textBlur: CGFloat = 10
    @State private var slideUp: CGFloat = 0

    private let orange = Color(red: 254/255, green: 134/255, blue: 5/255)

    var body: some View {
        ZStack {
            orange.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Logo — bigger, crisp
                AnimatedLogo(strokeProgress: strokeProgress, fillOpacity: fillOpacity)
                    .frame(width: 240, height: 189)

                // "Конок Go" text — slightly above center
                Text("Конок Go")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(textOpacity)
                    .blur(radius: textBlur)
                    .offset(y: textOffset)

                Spacer()
                Spacer()
            }
        }
        // Rounded bottom corners
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 40,
                bottomTrailingRadius: 40,
                topTrailingRadius: 0
            )
        )
        .ignoresSafeArea()
        .offset(y: slideUp)
        .onAppear { startAnimation() }
    }

    private func startAnimation() {
        // Phase 1 — stroke draws (0 → 1.6s)
        withAnimation(.easeInOut(duration: 1.6)) {
            strokeProgress = 1.0
        }

        // Phase 2 — fill fades in (1.1s → 1.7s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeIn(duration: 0.6)) {
                fillOpacity = 1.0
            }
        }

        // Phase 3 — text rises up with blur clear (1.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) {
                textOffset = 0
            }
            withAnimation(.easeOut(duration: 0.6)) {
                textOpacity = 1.0
                textBlur = 0
            }
        }

        // Phase 4 — slide up fast off screen (3.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeIn(duration: 0.38)) {
                slideUp = -UIScreen.main.bounds.height
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.38) {
            isFinished = true
        }
    }
}

#Preview {
    SplashView(isFinished: .constant(false))
}
