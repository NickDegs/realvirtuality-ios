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
            Group {
                if isFullTier {
                    fullContent
                } else {
                    lockedContent
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
            )) { Button("Tamam") { errorMessage = nil } }
            message: { Text(errorMessage ?? "") }
            .task { if isFullTier { await loadSessions() } }
        }
    }

    // MARK: - Full Content

    private var fullContent: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    Image(systemName: "lock.open.fill")
                        .font(.title2).foregroundStyle(.purple)
                        .frame(width: 44, height: 44)
                        .background(Color.purple.opacity(0.12), in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Özel Hesap İndirme").font(.subheadline.bold())
                        Text("Takip ettiğin özel hesapların içeriklerini indir. Şifreni asla görmüyoruz.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Hesap Bağla") {
                platformConnectRow("Instagram", icon: "camera.fill", color: .pink,
                                   isConnected: sessions.contains(where: { $0.platform == "Instagram" }),
                                   comingSoon: false) { showInstagramLogin = true }

                platformConnectRow("TikTok", icon: "music.note", color: .primary,
                                   isConnected: false, comingSoon: true) {}

                platformConnectRow("Twitter / X", icon: "bird.fill", color: .blue,
                                   isConnected: false, comingSoon: true) {}
            }

            if !sessions.isEmpty {
                Section("Bağlı Hesaplar") {
                    ForEach(sessions) { session in
                        sessionRow(session)
                    }
                }
            }

            Section {
                Label("Şifreni asla görmüyoruz, sadece oturum çerezleri saklanır", systemImage: "checkmark.shield.fill")
                    .font(.caption).foregroundStyle(.green)
                Label("Oturum verisi şifreli sunucuda tutulur", systemImage: "checkmark.shield.fill")
                    .font(.caption).foregroundStyle(.green)
                Label("İstediğin zaman oturumu silebilirsin", systemImage: "checkmark.shield.fill")
                    .font(.caption).foregroundStyle(.green)
            } header: {
                Label("Güvenlik", systemImage: "shield.fill").foregroundStyle(.green)
            }
        }
        .listStyle(.insetGrouped)
    }

    private func platformConnectRow(_ platform: String, icon: String, color: Color,
                                    isConnected: Bool, comingSoon: Bool,
                                    action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(comingSoon ? .secondary : color)
                    .frame(width: 44, height: 44)
                    .background((comingSoon ? Color.secondary : color).opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(platform).font(.subheadline.bold())
                        .foregroundStyle(comingSoon ? .secondary : .primary)
                    Text(comingSoon ? "Yakında" : isConnected ? "Bağlı" : "Bağla")
                        .font(.caption)
                        .foregroundStyle(isConnected ? .green : comingSoon ? .secondary : .purple)
                }

                Spacer()

                if comingSoon {
                    Text("Yakında").font(.caption.bold()).foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.secondary, in: Capsule())
                } else if isConnected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.title3)
                } else {
                    Image(systemName: "plus.circle.fill").foregroundStyle(.purple).font(.title3)
                }
            }
            .contentShape(Rectangle())
        }
        .disabled(comingSoon)
        .foregroundStyle(.primary)
    }

    private func sessionRow(_ session: PlatformSession) -> some View {
        HStack(spacing: 14) {
            Image(systemName: platformIcon(session.platform))
                .font(.title3)
                .foregroundStyle(platformColor(session.platform))
                .frame(width: 44, height: 44)
                .background(platformColor(session.platform).opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(session.platform).font(.subheadline.bold())
                if let username = session.username {
                    Text("@\(username)").font(.caption).foregroundStyle(.secondary)
                }
            }

            Spacer()

            Menu {
                Button(role: .destructive) {
                    deleteTarget = session; showDeleteConfirm = true
                } label: {
                    Label("Oturumu Sil", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle").foregroundStyle(.secondary).font(.title3)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Locked

    private var lockedContent: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 52)).foregroundStyle(.purple)
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text("Özel Hesaplar").font(.title2.bold())
                    PremiumBadge()
                }
                Text("Özel hesaplardan içerik indirmek Full üyelik gerektirir.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal)
            }
            Button {
                showSubscription = true
            } label: {
                Label("Full'e Geç", systemImage: "crown.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            Spacer()
        }
        .sheet(isPresented: $showSubscription) { SubscriptionView() }
    }

    // MARK: - Actions

    private func loadSessions() async {
        isLoading = true
        do { sessions = try await APIService.shared.getPrivateSessions() }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    private func deleteSession(_ session: PlatformSession) async {
        do {
            try await APIService.shared.deletePrivateSession(platform: session.platform)
            sessions.removeAll { $0.id == session.id }
        } catch { errorMessage = error.localizedDescription }
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
