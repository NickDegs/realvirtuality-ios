import SwiftUI

@MainActor
final class AuthState: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: String?

    var isAuthenticated: Bool { user != nil }

    init() {
        Task { await tryAutoLogin() }
    }

    func tryAutoLogin() async {
        guard KeychainService.shared.loadToken() != nil else { return }
        isLoading = true
        do {
            user = try await APIService.shared.getMe()
        } catch {
            KeychainService.shared.deleteToken()
        }
        isLoading = false
    }

    func login(email: String, password: String) async {
        isLoading = true
        error = nil
        do {
            let response = try await APIService.shared.login(email: email, password: password)
            KeychainService.shared.saveToken(response.accessToken)
            user = response.user
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func register(email: String, username: String, password: String) async {
        isLoading = true
        error = nil
        do {
            let response = try await APIService.shared.register(email: email, username: username, password: password)
            KeychainService.shared.saveToken(response.accessToken)
            user = response.user
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loginWithApple(identityToken: String, fullName: String?) async {
        isLoading = true
        error = nil
        do {
            let response = try await APIService.shared.loginWithApple(identityToken: identityToken, fullName: fullName)
            KeychainService.shared.saveToken(response.accessToken)
            user = response.user
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loginWithGoogle(idToken: String) async {
        isLoading = true
        error = nil
        do {
            let response = try await APIService.shared.loginWithGoogle(idToken: idToken)
            KeychainService.shared.saveToken(response.accessToken)
            user = response.user
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func logout() {
        KeychainService.shared.deleteToken()
        user = nil
    }

    func refreshUser() async {
        do {
            user = try await APIService.shared.getMe()
        } catch APIError.unauthorized {
            logout()
        } catch {}
    }
}
