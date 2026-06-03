import SwiftUI

struct AccountView: View {
    @EnvironmentObject var authState: AuthState
    @State private var showSubscription = false

    var body: some View {
        NavigationStack {
            List {
                profileSection
                subscriptionSection
                actionsSection
            }
            .navigationTitle("Hesabım")
            .sheet(isPresented: $showSubscription) { SubscriptionView() }
        }
    }

    private var profileSection: some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.purple)
                VStack(alignment: .leading, spacing: 4) {
                    Text(authState.user?.username ?? "")
                        .font(.headline)
                    Text(authState.user?.email ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var subscriptionSection: some View {
        Section("Abonelik") {
            HStack {
                Label(tierName, systemImage: tierIcon)
                    .foregroundColor(tierColor)
                Spacer()
                if authState.user?.tier != .full {
                    Button("Yükselt") { showSubscription = true }
                        .font(.caption.bold())
                        .foregroundColor(.purple)
                }
            }
        }
    }

    private var actionsSection: some View {
        Section {
            Button(role: .destructive) {
                authState.logout()
            } label: {
                Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    private var tierName: String {
        switch authState.user?.tier {
        case .free: return "Ücretsiz Plan"
        case .adFree: return "Reklamsız Plan"
        case .full: return "Full Plan"
        case .none: return ""
        }
    }

    private var tierIcon: String {
        switch authState.user?.tier {
        case .free: return "star"
        case .adFree: return "star.fill"
        case .full: return "crown.fill"
        case .none: return "star"
        }
    }

    private var tierColor: Color {
        switch authState.user?.tier {
        case .full: return .yellow
        case .adFree: return .purple
        default: return .secondary
        }
    }
}
