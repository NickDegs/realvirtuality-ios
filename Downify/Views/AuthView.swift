import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authState: AuthState
    @State private var isLogin = true
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            AppBackground()
            // Extra purple glow at top
            RadialGradient(
                colors: [Color.purple.opacity(0.35), Color.clear],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    header
                    formCard
                    actionButton
                    toggleSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.4), Color.indigo.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .blur(radius: 20)

                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(red: 0.85, green: 0.65, blue: 1.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            Text("Downify")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, Color.purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(isLogin ? "Hesabınıza giriş yapın" : "Yeni hesap oluşturun")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Form Card

    private var formCard: some View {
        VStack(spacing: 12) {
            inputField("envelope", placeholder: "E-posta", text: $email,
                       contentType: .emailAddress, keyboard: .emailAddress)

            if !isLogin {
                inputField("person", placeholder: "Kullanıcı adı", text: $username)
            }

            secureField("lock", placeholder: "Şifre", text: $password,
                        contentType: isLogin ? .password : .newPassword)

            if let error = authState.error {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
            }
        }
        .padding(20)
        .glassCard()
    }

    private func inputField(
        _ icon: String,
        placeholder: String,
        text: Binding<String>,
        contentType: UITextContentType? = nil,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.purple)
                .frame(width: 18)
            TextField(placeholder, text: text)
                .textContentType(contentType)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(14)
        .glassInput()
    }

    private func secureField(
        _ icon: String,
        placeholder: String,
        text: Binding<String>,
        contentType: UITextContentType? = nil
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.purple)
                .frame(width: 18)
            SecureField(placeholder, text: text)
                .textContentType(contentType)
        }
        .padding(14)
        .glassInput()
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button {
            Task {
                if isLogin {
                    await authState.login(email: email, password: password)
                } else {
                    await authState.register(email: email, username: username, password: password)
                }
            }
        } label: {
            HStack(spacing: 8) {
                if authState.isLoading {
                    ProgressView().tint(.white).scaleEffect(0.85)
                }
                Text(isLogin ? "Giriş Yap" : "Kayıt Ol")
            }
        }
        .buttonStyle(PrimaryButtonStyle(
            enabled: !authState.isLoading && !email.isEmpty && !password.isEmpty
        ))
        .disabled(authState.isLoading || email.isEmpty || password.isEmpty)
    }

    // MARK: - Toggle Section

    private var toggleSection: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isLogin.toggle()
                authState.error = nil
            }
        } label: {
            Group {
                if isLogin {
                    Text("Hesabınız yok mu? ") + Text("Kayıt olun").bold()
                } else {
                    Text("Zaten hesabınız var mı? ") + Text("Giriş yapın").bold()
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
}
