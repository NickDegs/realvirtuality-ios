import SwiftUI

struct PrivateAccountsView: View {
    @EnvironmentObject var authState: AuthState
    @State private var sessions: [PlatformSession] = []
    @State private var isLoading = false
    @State private var showInstagramLogin = false
    @State private var showSubscription = false
    @State private var errorMessage: String?
    @State private var deleteTarget: PlatformSession?
    @State private var showDeleteConfirm = false

    var isFullTier: Bool { authState.user?.tier == .full }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                Group {
                    if isFullTier {
                        fullContent
                    } else {
                        lockedContent
                    }
                }
            }
            .navigationTitle("Özel Hesaplar")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showInstagramLogin, onDismiss: { Task { await loadSessions() } }) {
                InstagramLoginView()
            }
            .sheet(isPresented: $showSubscription) { SubscriptionView() }
            .alert("Oturumu Sil", isPresented: $showDeleteConfirm) {
                Button("Sil", role: .destructive) {
                    if let s = deleteTarget { Task { await deleteSession(s) } }
                }
                Button("İptal", role: .cancel) {}
            } message: {
                Text("\(deleteTarget?.platform ?? "") oturumunu silmek istediğinizden emin misiniz?")
            }
            .alert("Hata", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Tamam") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .task { if isFullTier { await loadSessions() } }
        }
    }

    // MARK: - Full Content

    private var fullContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                infoCard
                connectSection
                if !sessions.isEmpty { connectedList }
                howItWorksCard
            }
            .padding(.horizontal)
            .padding(.vertical)
        }
    }

    private var infoCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "lock.open.fill")
                .font(.title2)
                .foregroundStyle(.purple)
                .frame(width: 44, height: 44)
                .background(Color.purple.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("Özel Hesap İndirme")
                    .font(.subheadline.bold())
                Text("Takip ettiğin özel hesapların içeriklerini indir. Cookie veya şifre paylaşmana gerek yok — oturumun güvenli şekilde saklanır.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .glassCard()
    }

    private var connectSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hesap Bağla")
                .font(.headline)

            PlatformConnectButton(
                platform: "Instagram",
                icon: "camera.fill",
                color: .pink,
                isConnected: sessions.contains(where: { $0.platform == "Instagram" })
            ) {
                showInstagramLogin = true
            }

            PlatformConnectButton(
                platform: "TikTok",
                icon: "music.note",
                color: .primary,
                isConnected: sessions.contains(where: { $0.platform == "TikTok" }),
                comingSoon: true
            ) {}

            PlatformConnectButton(
                platform: "Twitter / X",
                icon: "bird.fill",
                color: .blue,
                isConnected: sessions.contains(where: { $0.platform == "Twitter" }),
                comingSoon: true
            ) {}
        }
    }

    private var connectedList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bağlı Hesaplar")
                .font(.headline)

            ForEach(sessions) { session in
                SessionRow(session: session) {
                    deleteTarget = session
                    showDeleteConfirm = true
                }
            }
        }
    }

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Güvenlik Notu", systemImage: "shield.fill")
                .font(.subheadline.bold())
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 8) {
                securityPoint("Şifreni asla görmüyoruz, sadece oturum çerezleri saklanır")
                securityPoint("Oturum verisi şifreli sunucuda tutulur")
                securityPoint("İstediğin zaman oturumu silebilirsin")
                securityPoint("Yalnızca takip ettiğin özel hesaplara erişilir")
            }
        }
        .padding(16)
        .glassCard()
    }

    private func securityPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Locked

    private var lockedContent: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.12))
                        .frame(width: 90, height: 90)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.purple)
                }

                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Text("Özel Hesaplar")
                            .font(.title2.bold())
                        PremiumBadge()
                    }
                    Text("Özel Instagram ve diğer platform hesaplarından içerik indirmek Full üyelik gerektirir.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    showSubscription = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                        Text("Full'e Geç")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .sheet(isPresented: $showSubscription) { SubscriptionView() }
    }

    // MARK: - Actions

    private func loadSessions() async {
        isLoading = true
        do {
            sessions = try await APIService.shared.getPrivateSessions()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func deleteSession(_ session: PlatformSession) async {
        do {
            try await APIService.shared.deletePrivateSession(platform: session.platform)
            sessions.removeAll { $0.id == session.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Platform Connect Button

struct PlatformConnectButton: View {
    let platform: String
    let icon: String
    let color: Color
    let isConnected: Bool
    var comingSoon: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(comingSoon ? .secondary : color)
                    .frame(width: 44, height: 44)
                    .background((comingSoon ? Color.secondary : color).opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(platform)
                        .font(.subheadline.bold())
                        .foregroundStyle(comingSoon ? .secondary : .primary)
                    Text(comingSoon ? "Yakında" : isConnected ? "Bağlı" : "Bağla")
                        .font(.caption)
                        .foregroundStyle(isConnected ? .green : comingSoon ? .secondary : .purple)
                }

                Spacer()

                if comingSoon {
                    Text("Yakında")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.secondary, in: Capsule())
                } else if isConnected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.purple)
                        .font(.title3)
                }
            }
            .padding(14)
            .glassCard()
        }
        .buttonStyle(.plain)
        .disabled(comingSoon)
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: PlatformSession
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: platformIcon(session.platform))
                .font(.title3)
                .foregroundStyle(platformColor(session.platform))
                .frame(width: 44, height: 44)
                .background(platformColor(session.platform).opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(session.platform)
                    .font(.subheadline.bold())
                if let username = session.username {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let date = session.connectedAt {
                    Text("Bağlandı: \(date)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Menu {
                Button(role: .destructive, action: onDelete) {
                    Label("Oturumu Sil", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }
        }
        .padding(14)
        .glassCard()
    }

    private func platformIcon(_ p: String) -> String {
        switch p {
        case "Instagram": return "camera.fill"
        case "TikTok":    return "music.note"
        case "Twitter":   return "bird.fill"
        default:          return "globe"
        }
    }

    private func platformColor(_ p: String) -> Color {
        switch p {
        case "Instagram": return .pink
        case "TikTok":    return .primary
        case "Twitter":   return .blue
        default:          return .purple
        }
    }
}

