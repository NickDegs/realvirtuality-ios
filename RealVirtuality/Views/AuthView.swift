import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authState: AuthState
    @State private var isLogin = true
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    header
                    formSection
                    actionButton
                    toggleSection
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            Text("Real Virtuality")
                .font(.largeTitle.bold())
            Text(isLogin ? "Hesabınıza giriş yapın" : "Yeni hesap oluşturun")
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }

    private var formSection: some View {
        VStack(spacing: 14) {
            TextField("E-posta", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

            if !isLogin {
                TextField("Kullanıcı adı", text: $username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }

            SecureField("Şifre", text: $password)
                .textContentType(isLogin ? .password : .newPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

            if let error = authState.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

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
            HStack {
                if authState.isLoading { ProgressView().tint(.white) }
                Text(isLogin ? "Giriş Yap" : "Kayıt Ol")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(authState.isLoading || email.isEmpty || password.isEmpty)
    }

    private var toggleSection: some View {
        Button {
            withAnimation { isLogin.toggle() }
            authState.error = nil
        } label: {
            Group {
                if isLogin {
                    Text("Hesabınız yok mu? ") + Text("Kayıt olun").bold()
                } else {
                    Text("Zaten hesabınız var mı? ") + Text("Giriş yapın").bold()
                }
            }
            .font(.subheadline)
        }
    }
}
