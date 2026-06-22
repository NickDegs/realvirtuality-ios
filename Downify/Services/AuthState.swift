import SwiftUI

@MainActor
final class AuthState: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: String?

    /// Active StoreKit entitlement (set by StoreManager). Source of truth for
    /// unlocking premium features so we never depend on a server round-trip.
    @Published var storeTier: SubscriptionTier = .free

    var isAuthenticated: Bool { user != nil }

    /// Effective tier = highest of server tier and live StoreKit entitlement.
    var tier: SubscriptionTier {
        let server = user?.tier ?? .free
        return server.rank >= storeTier.rank ? server : storeTier
    }

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

    /// Sends an SMS code. Returns true if sent so the UI can show the code field.
    func sendSMSCode(phone: String) async -> Bool {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            try await APIService.shared.sendSMSCode(phone: phone)
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func verifySMSCode(phone: String, code: String) async {
        isLoading = true
        error = nil
        do {
            let response = try await APIService.shared.verifySMSCode(phone: phone, code: code)
            KeychainService.shared.saveToken(response.accessToken)
            user = response.user
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loginAsGuest() async {
        isLoading = true
        error = nil
        do {
            let response = try await APIService.shared.guestLogin()
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

    func deleteAccount() async {
        isLoading = true
        error = nil
        do {
            try await APIService.shared.deleteAccount()
            KeychainService.shared.deleteToken()
            user = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func refreshUser() async {
        do {
            user = try await APIService.shared.getMe()
        } catch APIError.unauthorized {
            logout()
        } catch {}
    }
}
