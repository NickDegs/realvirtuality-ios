import SwiftUI

struct ShortcutView: View {
    @EnvironmentObject var authState: AuthState
    @State private var showSubscription = false
    @State private var showShareSetup = false
    @State private var showSiriSetup = false
    @State private var shareExtensionAdded = false
    @State private var privateAccountsSetup = false

    var isFullTier: Bool { authState.user?.tier == .full }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        heroSection
                        shortcutCards
                        if isFullTier { howToSection }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Kestirmeler")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showSubscription) { SubscriptionView() }
            .sheet(isPresented: $showShareSetup) { ShareExtensionSetupView() }
            .sheet(isPresented: $showSiriSetup) { SiriSetupView() }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.indigo.opacity(0.15)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .indigo],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text("Kestirmeler")
                        .font(.title2.bold())
                    PremiumBadge()
                }
                Text("İstediğin uygulamadan tek dokunuşla indir. Siri ile sesli komut ver.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if !isFullTier {
                Button {
                    showSubscription = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                        Text("Full'e Geç — Kestirmeleri Aç")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Shortcut Cards

    private var shortcutCards: some View {
        VStack(spacing: 14) {
            ShortcutCard(
                icon: "square.and.arrow.up.fill",
                iconColor: .blue,
                title: "Paylaşım Menüsü",
                subtitle: "Safari, Instagram veya herhangi bir uygulamadan 'Paylaş' → Downify'ı seç",
                badge: "En Kolay",
                badgeColor: .green,
                isLocked: !isFullTier,
                steps: [
                    "Herhangi bir uygulamada video/link bul",
                    "'Paylaş' butonuna bas",
                    "Listeden 'Downify' seç",
                    "Otomatik indirilir"
                ]
            ) {
                if isFullTier { showShareSetup = true }
                else { showSubscription = true }
            }

            ShortcutCard(
                icon: "waveform",
                iconColor: .purple,
                title: "Siri Komutu",
                subtitle: "\"Hey Siri, bu videoyu Downify ile indir\" de, gerisini Siri halleder",
                badge: "Yeni",
                badgeColor: .purple,
                isLocked: !isFullTier,
                steps: [
                    "Siri'ye konuş: 'Downify ile indir'",
                    "URL'yi söyle ya da panoya al",
                    "Siri indirmeyi başlatır",
                    "İndirme tamamlanınca bildirim gelir"
                ]
            ) {
                if isFullTier { showSiriSetup = true }
                else { showSubscription = true }
            }

            ShortcutCard(
                icon: "apps.iphone",
                iconColor: .orange,
                title: "Kısayollar Uygulaması",
                subtitle: "iOS Kısayollar uygulamasına 'Video İndir' aksiyonu ekle, otomasyon kur",
                badge: "Güçlü",
                badgeColor: .orange,
                isLocked: !isFullTier,
                steps: [
                    "Kısayollar uygulamasını aç",
                    "Yeni kısayol oluştur",
                    "Downify → 'Video İndir' aksiyonunu ekle",
                    "URL'yi parametre olarak gönder"
                ]
            ) {
                if isFullTier { openShortcutsApp() }
                else { showSubscription = true }
            }

            ShortcutCard(
                icon: "rectangle.stack.fill",
                iconColor: .teal,
                title: "Özel Hesap İndirme",
                subtitle: "Özel Instagram hesaplarından, gizli içeriklerden cookie girmeden indir",
                badge: "Full",
                badgeColor: .teal,
                isLocked: !isFullTier,
                steps: [
                    "Hesabına giriş yap (bir kere yeterli)",
                    "URL'yi uygulamaya yapıştır",
                    "'Özel Hesap' seçeneğini aç",
                    "İndir"
                ]
            ) {
                if isFullTier {
                    NotificationCenter.default.post(name: .showPrivateAccounts, object: nil)
                } else {
                    showSubscription = true
                }
            }
        }
    }

    // MARK: - How To

    private var howToSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nasıl Çalışır?")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                howToStep(num: "1", text: "Herhangi bir uygulamada video buluyorsun")
                howToStep(num: "2", text: "'Paylaş' butonuna dokunup Downify'ı seçiyorsun")
                howToStep(num: "3", text: "Downify arka planda indiriyor, bildirim geliyor")
                howToStep(num: "4", text: "Galeri sekmesinde hazır, paylaş ya da kaydet")
            }
            .padding(16)
            .glassCard()
        }
    }

    private func howToStep(num: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(num)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.purple, in: Circle())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
    }

    private func openShortcutsApp() {
        if let url = URL(string: "shortcuts://") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Shortcut Card

struct ShortcutCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let badge: String
    let badgeColor: Color
    let isLocked: Bool
    let steps: [String]
    let action: () -> Void

    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(title).font(.subheadline.bold())
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(badgeColor, in: Capsule())
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if !isLocked {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        expanded.toggle()
                    }
                }
            }

            // Expanded Steps
            if expanded && !isLocked {
                Divider().padding(.vertical, 12)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(steps.enumerated()), id: \.0) { i, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(i+1)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .background(iconColor, in: Circle())
                            Text(step)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                }

                Button(action: action) {
                    HStack(spacing: 6) {
                        Image(systemName: icon)
                        Text("Kur")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(iconColor, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }

            // Locked CTA
            if isLocked {
                Divider().padding(.vertical, 10)
                HStack {
                    Image(systemName: "crown.fill").foregroundStyle(.yellow)
                    Text("Full üyelik gerekli")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(action: action) {
                        Text("Aç")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.purple, in: Capsule())
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: expanded)
    }
}

// MARK: - Share Extension Setup

struct ShareExtensionSetupView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                VStack(spacing: 24) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                        .padding(.top, 32)

                    VStack(spacing: 8) {
                        Text("Paylaşım Menüsünü Kur")
                            .font(.title2.bold())
                        Text("Bir kez ayarla, her zaman kullan")
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 16) {
                        SetupStep(
                            num: 1,
                            title: "Herhangi bir uygulamayı aç",
                            detail: "Safari, Instagram, Twitter veya YouTube"
                        )
                        SetupStep(
                            num: 2,
                            title: "Paylaş butonuna bas",
                            detail: "Kare içinde ok işareti olan ikon"
                        )
                        SetupStep(
                            num: 3,
                            title: "Diğer'e git",
                            detail: "Uygulama listesinin altındaki 'Diğer' seçeneği"
                        )
                        SetupStep(
                            num: 4,
                            title: "Downify'ı etkinleştir",
                            detail: "Listeyi aşağı kaydır, Downify'ı bul ve aç"
                        )
                    }
                    .padding(.horizontal)

                    Text("Artık 'Paylaş' menüsünde Downify görünecek. Bir video linkine 'Paylaş' → Downify → anında indirilir.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer()

                    Button("Anladım") { dismiss() }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Siri Setup

struct SiriSetupView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                VStack(spacing: 24) {
                    Image(systemName: "waveform")
                        .font(.system(size: 60))
                        .foregroundStyle(.purple)
                        .padding(.top, 32)

                    VStack(spacing: 8) {
                        Text("Siri Kısayolu Kur")
                            .font(.title2.bold())
                        Text("Sesli komutla indirme başlat")
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        siriPhrase("\"Downify ile indir\"")
                        siriPhrase("\"Bu videoyu indir\"")
                        siriPhrase("\"Videoyu Downify'a gönder\"")
                    }
                    .padding()
                    .glassCard()
                    .padding(.horizontal)

                    VStack(spacing: 14) {
                        SetupStep(num: 1, title: "Ayarlar → Siri ve Arama aç", detail: "")
                        SetupStep(num: 2, title: "Kısayollar → Kısayol Ekle", detail: "Downify → Video İndir")
                        SetupStep(num: 3, title: "Siri komutunu kaydet", detail: "Yukarıdaki komutlardan birini kullan")
                    }
                    .padding(.horizontal)

                    Spacer()

                    Button("Tamam") { dismiss() }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    private func siriPhrase(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform.circle.fill")
                .foregroundStyle(.purple)
            Text(text)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Setup Step

struct SetupStep: View {
    let num: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(num)")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.purple, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                if !detail.isEmpty {
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Notification

extension Notification.Name {
    static let showPrivateAccounts = Notification.Name("showPrivateAccounts")
}
