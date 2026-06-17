import SwiftUI

struct ShortcutView: View {
    @EnvironmentObject var authState: AuthState
    @State private var showSubscription = false
    @State private var showShareSetup = false
    @State private var showSiriSetup = false

    var isFullTier: Bool { authState.user?.tier == .full }

    var body: some View {
        NavigationStack {
            List {
                if !isFullTier {
                    Section {
                        VStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Text("Kestirmeler")
                                    .font(.title3.bold())
                                PremiumBadge()
                            }
                            Text("İstediğin uygulamadan tek dokunuşla indir. Siri ile sesli komut ver.")
                                .font(.subheadline).foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button {
                                showSubscription = true
                            } label: {
                                Label("Full'e Geç — Kestirmeleri Aç", systemImage: "crown.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.accent)
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Hızlı Erişim") {
                    shortcutRow(
                        icon: "square.and.arrow.up.fill", iconColor: .blue,
                        title: "Paylaşım Menüsü",
                        subtitle: "Herhangi uygulamadan 'Paylaş' → Downify",
                        badge: "En Kolay", badgeColor: .green,
                        isLocked: !isFullTier
                    ) { if isFullTier { showShareSetup = true } else { showSubscription = true } }

                    shortcutRow(
                        icon: "waveform", iconColor: Theme.accent,
                        title: "Siri Komutu",
                        subtitle: "\"Hey Siri, Downify ile indir\" de",
                        badge: "Yeni", badgeColor: Theme.accent,
                        isLocked: !isFullTier
                    ) { if isFullTier { showSiriSetup = true } else { showSubscription = true } }

                    shortcutRow(
                        icon: "apps.iphone", iconColor: .orange,
                        title: "Kısayollar Uygulaması",
                        subtitle: "iOS Kısayollar'a 'Video İndir' aksiyonu ekle",
                        badge: "Güçlü", badgeColor: .orange,
                        isLocked: !isFullTier
                    ) { if isFullTier { openShortcutsApp() } else { showSubscription = true } }

                    shortcutRow(
                        icon: "rectangle.stack.fill", iconColor: .teal,
                        title: "Özel Hesap İndirme",
                        subtitle: "Cookie girmeden özel hesaplardan indir",
                        badge: "Full", badgeColor: .teal,
                        isLocked: !isFullTier
                    ) {
                        if isFullTier { NotificationCenter.default.post(name: .showPrivateAccounts, object: nil) }
                        else { showSubscription = true }
                    }
                }

                if isFullTier {
                    Section("Nasıl Çalışır?") {
                        howToRow(num: "1", text: "Herhangi bir uygulamada video buluyorsun")
                        howToRow(num: "2", text: "'Paylaş' → Downify'ı seçiyorsun")
                        howToRow(num: "3", text: "Downify arka planda indiriyor, bildirim geliyor")
                        howToRow(num: "4", text: "Galeri sekmesinde hazır, paylaş ya da kaydet")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Kestirmeler")
            .sheet(isPresented: $showSubscription) { SubscriptionView() }
            .sheet(isPresented: $showShareSetup) { ShareExtensionSetupView() }
            .sheet(isPresented: $showSiriSetup) { SiriSetupView() }
        }
    }

    private func shortcutRow(icon: String, iconColor: Color, title: String, subtitle: String,
                              badge: String, badgeColor: Color, isLocked: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isLocked ? .secondary : iconColor)
                    .frame(width: 44, height: 44)
                    .background((isLocked ? Color.secondary : iconColor).opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(title).font(.subheadline.bold())
                            .foregroundStyle(isLocked ? .secondary : .primary)
                        Text(badge)
                            .font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(isLocked ? Color.secondary : badgeColor, in: Capsule())
                    }
                    Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }

                Spacer()

                Image(systemName: isLocked ? "lock.fill" : "chevron.right")
                    .font(.caption.bold()).foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .foregroundStyle(.primary)
    }

    private func howToRow(num: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(num)
                .font(.caption.bold()).foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Theme.accent, in: Circle())
            Text(text).font(.subheadline)
        }
        .padding(.vertical, 2)
    }

    private func openShortcutsApp() {
        if let url = URL(string: "shortcuts://") { UIApplication.shared.open(url) }
    }
}

// MARK: - Share Extension Setup

struct ShareExtensionSetupView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.system(size: 52)).foregroundStyle(.blue)
                        Text("Paylaşım Menüsünü Kur").font(.title2.bold())
                        Text("Bir kez ayarla, her zaman kullan").foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

                Section("Adımlar") {
                    setupStep(num: 1, title: "Herhangi bir uygulamayı aç",
                              detail: "Safari, Instagram, Twitter veya YouTube")
                    setupStep(num: 2, title: "Paylaş butonuna bas",
                              detail: "Kare içinde ok işareti olan ikon")
                    setupStep(num: 3, title: "Diğer'e git",
                              detail: "Uygulama listesinin altındaki 'Diğer' seçeneği")
                    setupStep(num: 4, title: "Downify'ı etkinleştir",
                              detail: "Listeyi kaydır, Downify'ı bul ve aç")
                }

                Section {
                    Text("Artık 'Paylaş' menüsünde Downify görünecek.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section {
                    Button("Anladım") { dismiss() }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.insetGrouped)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Kapat") { dismiss() } }
            }
        }
    }

    private func setupStep(num: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(num)").font(.subheadline.bold()).foregroundStyle(.white)
                .frame(width: 26, height: 26).background(Color.blue, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                if !detail.isEmpty {
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Siri Setup

struct SiriSetupView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "waveform")
                            .font(.system(size: 52)).foregroundStyle(Theme.accent)
                        Text("Siri Kısayolu Kur").font(.title2.bold())
                        Text("Sesli komutla indirme başlat").foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

                Section("Örnek Komutlar") {
                    Label("\"Downify ile indir\"", systemImage: "waveform.circle.fill")
                        .foregroundStyle(Theme.accent)
                    Label("\"Bu videoyu Downify'a gönder\"", systemImage: "waveform.circle.fill")
                        .foregroundStyle(Theme.accent)
                    Label("\"Downify ile video indir\"", systemImage: "waveform.circle.fill")
                        .foregroundStyle(Theme.accent)
                }

                Section("Kurulum") {
                    HStack(alignment: .top, spacing: 14) {
                        Text("1").font(.subheadline.bold()).foregroundStyle(.white)
                            .frame(width: 26, height: 26).background(Theme.accent, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ayarlar → Siri ve Arama").font(.subheadline.bold())
                        }
                    }
                    .padding(.vertical, 4)
                    HStack(alignment: .top, spacing: 14) {
                        Text("2").font(.subheadline.bold()).foregroundStyle(.white)
                            .frame(width: 26, height: 26).background(Theme.accent, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Kısayollar → Kısayol Ekle").font(.subheadline.bold())
                            Text("Downify → Video İndir").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    HStack(alignment: .top, spacing: 14) {
                        Text("3").font(.subheadline.bold()).foregroundStyle(.white)
                            .frame(width: 26, height: 26).background(Theme.accent, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Siri komutunu kaydet").font(.subheadline.bold())
                            Text("Yukarıdaki komutlardan birini kullan").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button("Tamam") { dismiss() }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accent)
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.insetGrouped)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Kapat") { dismiss() } }
            }
        }
    }
}

// MARK: - Notification

extension Notification.Name {
    static let showPrivateAccounts = Notification.Name("showPrivateAccounts")
}
