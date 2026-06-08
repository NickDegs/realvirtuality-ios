import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authState: AuthState
    @State private var showSubscription = false
    @AppStorage("defaultQuality") private var defaultQuality = "best"
    @AppStorage("audioOnly") private var audioOnly = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        downloadSection
                        subscriptionSection
                        aboutSection
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
            .sheet(isPresented: $showSubscription) { SubscriptionView() }
        }
    }

    // MARK: - Download

    private var downloadSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("İndirme")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                HStack {
                    Label("Varsayılan Kalite", systemImage: "slider.horizontal.3")
                        .font(.subheadline)
                    Spacer()
                    Picker("", selection: $defaultQuality) {
                        Text("En İyi").tag("best")
                        Text("1080p").tag("1080")
                        Text("720p").tag("720")
                        Text("480p").tag("480")
                        Text("360p").tag("360")
                    }
                    .labelsHidden()
                }
                .padding(16)

                Divider().padding(.leading, 52)

                Toggle(isOn: $audioOnly) {
                    Label("Yalnızca Ses (MP3)", systemImage: "music.note")
                        .font(.subheadline)
                }
                .padding(16)
            }
            .glassCard()
        }
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Abonelik")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .padding(.bottom, 8)

            Button {
                showSubscription = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "crown.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.yellow)
                        .frame(width: 36, height: 36)
                        .background(Color.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Planı Yönet").font(.subheadline.bold())
                        Text(tierName).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
                }
                .padding(16)
            }
            .buttonStyle(.plain)
            .glassCard()
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Hakkında")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                settingsRow(icon: "info.circle.fill", iconColor: .blue, title: "Versiyon") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider().padding(.leading, 52)

                linkRow(icon: "hand.raised.fill", iconColor: .purple, title: "Gizlilik Politikası", url: "https://downify.app/privacy")

                Divider().padding(.leading, 52)

                linkRow(icon: "questionmark.circle.fill", iconColor: .green, title: "Destek", url: "https://downify.app/support")

                Divider().padding(.leading, 52)

                linkRow(icon: "doc.text.fill", iconColor: .orange, title: "Kullanım Koşulları", url: "https://downify.app/terms")
            }
            .glassCard()
        }
    }

    private func settingsRow<V: View>(icon: String, iconColor: Color, title: String, @ViewBuilder trailing: () -> V) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline.bold())
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            Text(title).font(.subheadline)
            Spacer()
            trailing()
        }
        .padding(16)
    }

    private func linkRow(icon: String, iconColor: Color, title: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.subheadline.bold())
                    .foregroundStyle(iconColor)
                    .frame(width: 36, height: 36)
                    .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                Text(title).font(.subheadline).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
            }
            .padding(16)
        }
    }

    private var tierName: String {
        switch authState.user?.tier {
        case .free:   return "Ücretsiz Plan"
        case .adFree: return "Pro Plan"
        case .full:   return "Full Plan"
        case .none:   return ""
        }
    }
}
