import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authState: AuthState
    @State private var isLogin = true
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                    .padding(.top, 60)

                SignInWithAppleButton(
                    isLogin ? .signIn : .signUp,
                    onRequest: { $0.requestedScopes = [.fullName, .email] },
                    onCompletion: { handleAppleSignIn($0) }
                )
                .signInWithAppleButtonStyle(.whiteOutline)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .padding(.horizontal)

                HStack(spacing: 12) {
                    Rectangle().fill(.separator).frame(height: 0.5)
                    Text("veya").font(.caption).foregroundStyle(.secondary)
                    Rectangle().fill(.separator).frame(height: 0.5)
                }
                .padding(.horizontal)

                formSection

                actionButton
                    .padding(.horizontal)

                toggleSection

                guestSection
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 64, weight: .medium))
                .foregroundStyle(Theme.accent)

            Text("Downify")
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Text(isLogin ? "Hesabınıza giriş yapın" : "Yeni hesap oluşturun")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "envelope").foregroundStyle(Theme.accent).frame(width: 18)
                TextField("E-posta", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .padding(14)
            .glassInput()
            .padding(.horizontal)

            if !isLogin {
                HStack(spacing: 10) {
                    Image(systemName: "person").foregroundStyle(Theme.accent).frame(width: 18)
                    TextField("Kullanıcı adı", text: $username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(14)
                .glassInput()
                .padding(.horizontal)
                .padding(.top, 8)
            }

            HStack(spacing: 10) {
                Image(systemName: "lock").foregroundStyle(Theme.accent).frame(width: 18)
                SecureField("Şifre", text: $password)
                    .textContentType(isLogin ? .password : .newPassword)
            }
            .padding(14)
            .glassInput()
            .padding(.horizontal)
            .padding(.top, 8)

            if let error = authState.error {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red)
                    Text(error).font(.caption).foregroundStyle(.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isLogin)
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
                if authState.isLoading { ProgressView().tint(.white).scaleEffect(0.85) }
                Text(isLogin ? "Giriş Yap" : "Kayıt Ol").fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(Theme.accent)
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

    // MARK: - Guest Section

    private var guestSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Rectangle().fill(.separator).frame(height: 0.5)
                Text("veya").font(.caption).foregroundStyle(.secondary)
                Rectangle().fill(.separator).frame(height: 0.5)
            }
            .padding(.horizontal)

            Button {
                Task { await authState.loginAsGuest() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.dashed")
                    Text("Hesap olmadan devam et").fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(Theme.accent)
            .padding(.horizontal)
            .disabled(authState.isLoading)

            Text("Herkese açık içeriği hesap açmadan indirebilirsin.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Apple Sign In

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8) else { return }
            let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }.joined(separator: " ")
            Task {
                await authState.loginWithApple(identityToken: token, fullName: fullName.isEmpty ? nil : fullName)
            }
        case .failure(let error):
            let nsErr = error as NSError
            if nsErr.domain != ASAuthorizationErrorDomain ||
               nsErr.code != ASAuthorizationError.Code.canceled.rawValue {
                authState.error = error.localizedDescription
            }
        }
    }
}
