import SwiftUI
import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift

struct AuthView: View {
    @EnvironmentObject var authState: AuthState
    @State private var isLogin = true
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            AppBackground()
            RadialGradient(
                colors: [Color.purple.opacity(0.35), Color.clear],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    socialButtons
                    divider
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

    // MARK: - Social Buttons

    private var socialButtons: some View {
        VStack(spacing: 12) {
            SignInWithAppleButton(
                isLogin ? .signIn : .signUp,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    handleAppleSignIn(result)
                }
            )
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 13))

            Button {
                handleGoogleSignIn()
            } label: {
                HStack(spacing: 10) {
                    Image("google_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text(isLogin ? "Google ile Giriş Yap" : "Google ile Kayıt Ol")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 13))
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
                )
            }
            .disabled(authState.isLoading)
        }
    }

    // MARK: - Divider

    private var divider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 0.5)
            Text("veya")
                .font(.caption)
                .foregroundStyle(.secondary)
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 0.5)
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

    // MARK: - Social Auth Handlers

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8) else { return }
            let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            Task {
                await authState.loginWithApple(identityToken: token, fullName: fullName.isEmpty ? nil : fullName)
            }
        case .failure(let error):
            let nsErr = error as NSError
            if nsErr.domain != ASAuthorizationErrorDomain || nsErr.code != ASAuthorizationError.Code.canceled.rawValue {
                authState.error = error.localizedDescription
            }
        }
    }

    private func handleGoogleSignIn() {
        // GIDClientID is configured programmatically — must be set before calling signIn
        let clientID = GoogleClientID.value
        guard !clientID.isEmpty else {
            authState.error = "Google Sign-In henüz yapılandırılmadı"
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.keyWindow?.rootViewController else { return }
        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            if let error {
                let nsErr = error as NSError
                let isCanceled = nsErr.domain == "com.google.GIDSignIn" && nsErr.code == -5
                if !isCanceled {
                    DispatchQueue.main.async { self.authState.error = error.localizedDescription }
                }
                return
            }
            guard let idToken = result?.user.idToken?.tokenString else { return }
            Task { await self.authState.loginWithGoogle(idToken: idToken) }
        }
    }
}
