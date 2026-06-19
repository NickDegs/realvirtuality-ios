import SwiftUI

struct AccountView: View {
    @EnvironmentObject var authState: AuthState
    @State private var showSubscription = false
    @State private var showDeleteConfirm = false

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
                    NavigationLink(destination: ShortcutView()) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Kestirmeler")
                                    if authState.tier != .full {
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

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Hesabı Sil", systemImage: "trash")
                    }
                } footer: {
                    Text("Hesabın ve tüm verilerin kalıcı olarak silinir. Bu işlem geri alınamaz.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Hesabım")
            .sheet(isPresented: $showSubscription) { SubscriptionView() }
            .alert("Hesabı Sil", isPresented: $showDeleteConfirm) {
                Button("İptal", role: .cancel) {}
                Button("Hesabı Sil", role: .destructive) {
                    Task { await authState.deleteAccount() }
                }
            } message: {
                Text("Hesabın ve tüm verilerin kalıcı olarak silinecek. Bu işlem geri alınamaz.")
            }
        }
    }

    // MARK: - Profile Row

    private var profileRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)

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

            if authState.tier != .full {
                Button("Yükselt") { showSubscription = true }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private var tierName: String {
        switch authState.tier {
        case .free:   return "Ücretsiz Plan"
        case .adFree: return "Pro Plan"
        case .full:   return "Full Plan"
        }
    }

    private var tierShortName: String {
        switch authState.tier {
        case .free:   return "Free"
        case .adFree: return "Pro"
        case .full:   return "Full"
        }
    }

    private var tierDescription: String {
        switch authState.tier {
        case .free:   return "Temel özellikler"
        case .adFree: return "Gelişmiş özellikler"
        case .full:   return "Tüm özellikler açık"
        }
    }

    private var tierIcon: String {
        switch authState.tier {
        case .free:   return "star"
        case .adFree: return "star.fill"
        case .full:   return "crown.fill"
        }
    }

    private var tierColor: Color {
        switch authState.tier {
        case .full:   return .yellow
        case .adFree: return Theme.accent
        default:      return .secondary
        }
    }
}
