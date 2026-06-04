import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authState: AuthState
    @State private var showSubscription = false
    @AppStorage("defaultQuality") private var defaultQuality = "best"
    @AppStorage("audioOnly") private var audioOnly = false

    var body: some View {
        NavigationStack {
            List {
                downloadSection
                subscriptionSection
                aboutSection
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

    private var downloadSection: some View {
        Section("İndirme") {
            Picker("Kalite", selection: $defaultQuality) {
                Text("En İyi").tag("best")
                Text("1080p").tag("1080")
                Text("720p").tag("720")
                Text("480p").tag("480")
                Text("360p").tag("360")
            }
            Toggle("Yalnızca Ses (MP3)", isOn: $audioOnly)
        }
    }

    private var subscriptionSection: some View {
        Section("Abonelik") {
            Button {
                showSubscription = true
            } label: {
                Label("Planı Yönet", systemImage: "crown.fill")
                    .foregroundColor(.primary)
            }
        }
    }

    private var aboutSection: some View {
        Section("Hakkında") {
            LabeledContent(
                "Versiyon",
                value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            )
            Link(destination: URL(string: "https://downify.app/privacy")!) {
                Label("Gizlilik Politikası", systemImage: "hand.raised.fill")
            }
            Link(destination: URL(string: "https://downify.app/support")!) {
                Label("Destek", systemImage: "questionmark.circle.fill")
            }
            Link(destination: URL(string: "https://downify.app/terms")!) {
                Label("Kullanım Koşulları", systemImage: "doc.text.fill")
            }
        }
    }
}
