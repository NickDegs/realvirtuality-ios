import SwiftUI

struct AccountView: View {
    @EnvironmentObject var authState: AuthState
    @State private var showSubscription = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    profileRow
                }

                Section("Abonelik") {
                    subscriptionRow
                }

                Section("Özellikler") {
                    NavigationLink(destination: PrivateAccountsView()) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Özel Hesaplar")
                                    if authState.user?.tier != .full {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.yellow)
                                    }
                                }
                                Text("Instagram özel içerik erişimi")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "lock.open.fill")
                                .foregroundStyle(.purple)
                        }
                    }

                    NavigationLink(destination: ShortcutView()) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Kestirmeler")
                                    if authState.user?.tier != .full {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.yellow)
                                    }
                                }
                                Text("Siri & paylaşım menüsü")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(.orange)
                        }
                    }

                    NavigationLink(destination: AutoDownloadView()) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Otomatik İndirme")
                                Text("Profil takibi & zamanlama")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "clock.arrow.2.circlepath")
                                .foregroundStyle(.green)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        authState.logout()
                    } label: {
                        Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Hesabım")
            .sheet(isPresented: $showSubscription) { SubscriptionView() }
        }
    }

    // MARK: - Profile Row

    private var profileRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.purple)

            VStack(alignment: .leading, spacing: 4) {
                Text(authState.user?.username ?? "")
                    .font(.headline)
                Text(authState.user?.email ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            tierBadge
        }
        .padding(.vertical, 6)
    }

    private var tierBadge: some View {
        Text(tierShortName)
            .font(.caption.bold())
            .foregroundStyle(tierColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tierColor.opacity(0.15), in: Capsule())
    }

    // MARK: - Subscription Row

    private var subscriptionRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: tierIcon)
                        .foregroundStyle(tierColor)
                    Text(tierName).font(.subheadline.bold())
                }
                Text(tierDescription)
                    .font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            if authState.user?.tier != .full {
                Button("Yükselt") { showSubscription = true }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private var tierName: String {
        switch authState.user?.tier {
        case .free:   return "Ücretsiz Plan"
        case .adFree: return "Pro Plan"
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
        case .adFree: return "Gelişmiş özellikler"
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
