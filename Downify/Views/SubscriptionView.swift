import SwiftUI
import SafariServices

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authState: AuthState
    @State private var isLoading = false
    @State private var safariURL: URL?
    @State private var showSafari = false
    @State private var errorMessage: String?

    let plans: [SubscriptionPlan] = [
        SubscriptionPlan(id: "ad_free", name: "Pro", price: "$3", period: "tek seferlik",
                         features: ["Öncelikli indirme", "Temel indirme", "Tüm platformlar"], tier: .adFree),
        SubscriptionPlan(id: "full_monthly", name: "Full — Aylık", price: "$5", period: "/ ay",
                         features: ["Tüm özellikler", "Kestirme & Siri desteği", "Özel hesap indirme", "HD kalite"], tier: .full, highlighted: true),
        SubscriptionPlan(id: "full_yearly", name: "Full — Yıllık", price: "$30", period: "/ yıl",
                         features: ["Tüm özellikler", "Kestirme & Siri desteği", "Özel hesap indirme", "%50 tasarruf"], tier: .full),
        SubscriptionPlan(id: "full_lifetime", name: "Ömür Boyu", price: "$50", period: "tek seferlik",
                         features: ["Tüm özellikler", "Sınırsız indirme", "Kalıcı lisans"], tier: .full),
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.yellow)
                        Text("Premium'a Geç").font(.title2.bold())
                        Text("Tüm platformlardan sınırsız indirme")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                ForEach(plans) { plan in
                    Section {
                        planRow(plan)
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error).font(.caption).foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
            .sheet(isPresented: $showSafari) {
                if let url = safariURL { SafariView(url: url) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .paymentResult)) { notification in
                if let success = notification.object as? Bool, success {
                    Task { await authState.refreshUser(); dismiss() }
                }
            }
        }
    }

    private func planRow(_ plan: SubscriptionPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(plan.name).font(.headline)
                        if plan.highlighted {
                            Text("Popüler")
                                .font(.caption2.bold()).foregroundStyle(.white)
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(Theme.accent, in: Capsule())
                        }
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(plan.price).font(.title2.bold()).foregroundStyle(Theme.accent)
                        Text(plan.period).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button {
                    Task { await purchase(plan: plan.id) }
                } label: {
                    if isLoading {
                        ProgressView().frame(width: 76, height: 36)
                    } else {
                        Text("Satın Al")
                            .fontWeight(.semibold)
                            .frame(width: 76, height: 36)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .disabled(isLoading)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(plan.features, id: \.self) { feature in
                    Label(feature, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func purchase(plan: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let urlString = try await APIService.shared.getCheckoutURL(plan: plan)
            if let url = URL(string: urlString) { safariURL = url; showSafari = true }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
