import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authState: AuthState
    @State private var showSubscription = false
    @AppStorage("defaultQuality") private var defaultQuality = "best"
    @AppStorage("audioOnly") private var audioOnly = false

    var body: some View {
        NavigationStack {
            Form {
                Section("İndirme") {
                    HStack {
                        Label("Varsayılan Kalite", systemImage: "slider.horizontal.3")
                        Spacer()
                        Picker("Kalite", selection: $defaultQuality) {
                            Text("En İyi").tag("best")
                            Text("1080p").tag("1080")
                            Text("720p").tag("720")
                            Text("480p").tag("480")
                            Text("360p").tag("360")
                        }
                        .labelsHidden()
                    }
                    Toggle(isOn: $audioOnly) {
                        Label("Yalnızca Ses (MP3)", systemImage: "music.note")
                    }
                    .tint(.purple)
                }

                Section("Abonelik") {
                    Button {
                        showSubscription = true
                    } label: {
                        HStack {
                            Label("Planı Yönet", systemImage: "crown.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(tierName)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption).foregroundStyle(.tertiary)
                        }
                    }
                }

                Section("Hakkında") {
                    LabeledContent("Versiyon") {
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    }
                    Link(destination: URL(string: "https://downify.app/privacy")!) {
                        Label("Gizlilik Politikası", systemImage: "hand.raised.fill")
                            .foregroundStyle(.primary)
                    }
                    Link(destination: URL(string: "https://downify.app/support")!) {
                        Label("Destek", systemImage: "questionmark.circle.fill")
                            .foregroundStyle(.primary)
                    }
                    Link(destination: URL(string: "https://downify.app/terms")!) {
                        Label("Kullanım Koşulları", systemImage: "doc.text.fill")
                            .foregroundStyle(.primary)
                    }
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

    private var tierName: String {
        switch authState.user?.tier {
        case .free:   return "Ücretsiz"
        case .adFree: return "Pro"
        case .full:   return "Full"
        case .none:   return ""
        }
    }
}
