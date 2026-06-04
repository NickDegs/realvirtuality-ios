import SwiftUI

struct AccountView: View {
    @EnvironmentObject var authState: AuthState
    @State private var showSubscription = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        profileCard
                        subscriptionCard
                        actionsCard
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Hesabım")
            .sheet(isPresented: $showSubscription) { SubscriptionView() }
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.5), Color.indigo.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                Image(systemName: "person.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(authState.user?.username ?? "")
                    .font(.title3.bold())
                Text(authState.user?.email ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            tierBadge
        }
        .padding(20)
        .glassCard()
    }

    private var tierBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: tierIcon)
                .font(.caption.bold())
            Text(tierShortName)
                .font(.caption.bold())
        }
        .foregroundStyle(tierColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(tierColor.opacity(0.15), in: Capsule())
        .overlay(Capsule().stroke(tierColor.opacity(0.3), lineWidth: 0.7))
    }

    // MARK: - Subscription Card

    private var subscriptionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Abonelik")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: tierIcon)
                            .foregroundStyle(tierColor)
                        Text(tierName)
                            .font(.headline)
                    }
                    Text(tierDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if authState.user?.tier != .full {
                    Button("Yükselt") { showSubscription = true }
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.55, green: 0.18, blue: 0.90),
                                         Color(red: 0.38, green: 0.08, blue: 0.72)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Capsule()
                        )
                        .shadow(color: .purple.opacity(0.35), radius: 6, y: 3)
                }
            }
        }
        .padding(20)
        .glassCard()
    }

    // MARK: - Actions Card

    private var actionsCard: some View {
        VStack(spacing: 0) {
            Button(role: .destructive) {
                authState.logout()
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Çıkış Yap")
                    Spacer()
                }
                .padding(18)
                .foregroundStyle(.red)
            }
        }
        .glassCard()
    }

    // MARK: - Helpers

    private var tierName: String {
        switch authState.user?.tier {
        case .free:   return "Ücretsiz Plan"
        case .adFree: return "Reklamsız Plan"
        case .full:   return "Full Plan"
        case .none:   return ""
        }
    }

    private var tierShortName: String {
        switch authState.user?.tier {
        case .free:   return "Free"
        case .adFree: return "Pro"
        case .full:   return "Full"
        case .none:   return ""
        }
    }

    private var tierDescription: String {
        switch authState.user?.tier {
        case .free:   return "Temel özellikler"
        case .adFree: return "Reklamsız deneyim"
        case .full:   return "Tüm özellikler açık"
        case .none:   return ""
        }
    }

    private var tierIcon: String {
        switch authState.user?.tier {
        case .free:   return "star"
        case .adFree: return "star.fill"
        case .full:   return "crown.fill"
        case .none:   return "star"
        }
    }

    private var tierColor: Color {
        switch authState.user?.tier {
        case .full:   return .yellow
        case .adFree: return .purple
        default:      return .secondary
        }
    }
}
