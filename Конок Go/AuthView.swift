//
//  AuthView.swift
//  Конок Go
//

import SwiftUI
import AuthenticationServices

private let orange = Color(red: 254/255, green: 134/255, blue: 5/255)

// MARK: - Auth Root

struct AuthView: View {
    var onAuthenticated: () -> Void
    @State private var showPhone = false

    var body: some View {
        NavigationStack {
            WelcomeScreen(onAuthenticated: onAuthenticated, showPhone: $showPhone)
                .navigationDestination(isPresented: $showPhone) {
                    PhoneEntryView(onAuthenticated: onAuthenticated)
                }
        }
    }
}

// MARK: - Welcome Screen

struct WelcomeScreen: View {
    var onAuthenticated: () -> Void
    @Binding var showPhone: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo block
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(orange.opacity(0.1))
                        .frame(width: 150, height: 150)
                    Image("Logo")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(orange)
                        .scaledToFit()
                        .frame(width: 92, height: 92)
                }

                VStack(spacing: 8) {
                    Text("Конок Go")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(.label))

                    Text("Быстрая доставка еды и товаров\nпо всему Ошу — круглосуточно")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color(.secondaryLabel))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
            }

            Spacer()

            // Buttons block
            VStack(spacing: 12) {

                // Phone
                Button {
                    showPhone = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Войти по номеру телефона")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(orange)
                    .clipShape(Capsule())
                }

                // Apple Sign In — whiteOutline чтобы не сливался с белым фоном
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let auth):
                        switch auth.credential {
                        case let credential as ASAuthorizationAppleIDCredential:
                            let userID = credential.user
                            UserDefaults.standard.set(userID, forKey: "konok_appleUserID")
                        default: break
                        }
                        onAuthenticated()
                    case .failure:
                        break
                    }
                }
                .signInWithAppleButtonStyle(.whiteOutline)
                .frame(height: 58)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color(.systemGray3), lineWidth: 1.5)
                )

                // Skip
                Button {
                    onAuthenticated()
                } label: {
                    Text("Войти позже")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabel))
                        .frame(height: 44)
                }
            }
            .padding(.horizontal, 24)

            // Terms
            Text("Продолжая, вы соглашаетесь с\nПользовательским соглашением")
                .font(.system(size: 12))
                .foregroundStyle(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
                .padding(.top, 16)
                .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
    }
}

// MARK: - Phone Entry View

struct PhoneEntryView: View {
    var onAuthenticated: () -> Void

    @State private var phone: String = ""
    @State private var showOTP = false
    @FocusState private var isFocused: Bool

    private var isValid: Bool { phone.count >= 9 }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Введите номер")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color(.label))

                Text("Отправим код подтверждения по SMS")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(.secondaryLabel))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 32)

            // Phone field
            HStack(spacing: 10) {
                // Flag + code
                HStack(spacing: 6) {
                    Text("🇰🇬")
                        .font(.system(size: 22))
                    Text("+996")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(.label))
                }
                .padding(.leading, 18)
                .padding(.vertical, 17)

                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 1, height: 24)

                TextField("XXX XXX XXX", text: $phone)
                    .font(.system(size: 17, weight: .semibold))
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .onChange(of: phone) { _, val in
                        phone = String(val.filter { $0.isNumber }.prefix(10))
                    }
                    .padding(.trailing, 18)
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal, 24)
            .padding(.top, 32)

            Spacer()

            // CTA
            NavigationLink(destination: OTPView(phone: "+996 \(phone)", onAuthenticated: onAuthenticated),
                           isActive: $showOTP) { EmptyView() }

            Button {
                isFocused = false
                showOTP = true
            } label: {
                Text("Получить код")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isValid ? .white : Color(.tertiaryLabel))
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(isValid ? orange : Color(.systemGray5))
                    .clipShape(Capsule())
            }
            .disabled(!isValid)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Вход")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { isFocused = true } }
    }
}

// MARK: - OTP View

struct OTPView: View {
    let phone: String
    var onAuthenticated: () -> Void

    @State private var code: String = ""
    @State private var timeLeft: Int = 60
    @State private var canResend: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorShake: Bool = false
    @FocusState private var isFocused: Bool

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var isComplete: Bool { code.count == 6 }

    var body: some View {
        VStack(spacing: 0) {

            VStack(alignment: .leading, spacing: 8) {
                Text("Введите код")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color(.label))

                Text("Отправили на \(phone)")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(.secondaryLabel))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 32)

            // OTP Boxes
            OTPBoxes(code: $code, isFocused: $isFocused)
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .offset(x: errorShake ? -8 : 0)
                .animation(errorShake ? .default.repeatCount(4, autoreverses: true).speed(4) : .default, value: errorShake)

            // Resend
            HStack {
                if canResend {
                    Button {
                        restartTimer()
                    } label: {
                        Text("Отправить снова")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(orange)
                    }
                } else {
                    Text("Повторная отправка через \(timeLeft) сек")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(.secondaryLabel))
                }
            }
            .padding(.top, 20)
            .onReceive(timer) { _ in
                if timeLeft > 0 { timeLeft -= 1 }
                else { canResend = true }
            }

            Spacer()

            // Confirm button
            Button {
                verify()
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Подтвердить")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundStyle(isComplete ? .white : Color(.tertiaryLabel))
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(isComplete ? orange : Color(.systemGray5))
                .clipShape(Capsule())
            }
            .disabled(!isComplete || isLoading)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Подтверждение")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { isFocused = true } }
        .onChange(of: code) { _, val in
            if val.count == 6 { verify() }
        }
    }

    private func verify() {
        guard code.count == 6 else { return }
        isLoading = true
        // Имитация проверки — здесь подключается ваш backend
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            // Любой 6-значный код принимается (пока нет backend)
            onAuthenticated()
        }
    }

    private func restartTimer() {
        timeLeft = 60
        canResend = false
    }
}

// MARK: - OTP Boxes

struct OTPBoxes: View {
    @Binding var code: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        ZStack {
            // Hidden input
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .opacity(0.001)
                .frame(width: 1, height: 1)
                .onChange(of: code) { _, val in
                    code = String(val.filter { $0.isNumber }.prefix(6))
                }

            // Visual boxes
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { i in
                    let filled = code.count > i
                    let active = code.count == i
                    let char = filled ? String(code[code.index(code.startIndex, offsetBy: i)]) : ""

                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.systemGray6))
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .overlay(
                            Text(char)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Color(.label))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(active ? orange : Color.clear, lineWidth: 2)
                        )
                        .animation(.easeInOut(duration: 0.15), value: active)
                }
            }
            .onTapGesture { isFocused = true }
        }
    }

    private let orange = Color(red: 254/255, green: 134/255, blue: 5/255)
}

#Preview {
    AuthView(onAuthenticated: {})
}
