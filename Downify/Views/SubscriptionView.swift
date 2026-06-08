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
        SubscriptionPlan(
            id: "ad_free",
            name: "Pro",
            price: "$3",
            period: "tek seferlik",
            features: ["Öncelikli indirme", "Temel indirme", "Tüm platformlar"],
            tier: .adFree
        ),
        SubscriptionPlan(
            id: "full_monthly",
            name: "Full — Aylık",
            price: "$5",
            period: "/ ay",
            features: ["Tüm özellikler", "⚡ Kestirme & Siri desteği", "🔒 Özel hesap indirme", "Öncelikli indirme", "HD kalite"],
            tier: .full
        ),
        SubscriptionPlan(
            id: "full_yearly",
            name: "Full — Yıllık",
            price: "$30",
            period: "/ yıl",
            features: ["Tüm özellikler", "⚡ Kestirme & Siri desteği", "🔒 Özel hesap indirme", "Öncelikli indirme", "HD kalite", "%50 tasarruf"],
            tier: .full
        ),
        SubscriptionPlan(
            id: "full_lifetime",
            name: "Ömür Boyu",
            price: "$50",
            period: "tek seferlik",
            features: ["Tüm özellikler", "⚡ Kestirme & Siri desteği", "🔒 Özel hesap indirme", "Sınırsız indirme", "Kalıcı lisans"],
            tier: .full
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        headerSection
                        ForEach(plans) { plan in
                            PlanCard(plan: plan, isLoading: isLoading) {
                                Task { await purchase(plan: plan.id) }
                            }
                        }
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
            .sheet(isPresented: $showSafari) {
                if let url = safariURL {
                    SafariView(url: url)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .paymentResult)) { notification in
                if let success = notification.object as? Bool, success {
                    Task {
                        await authState.refreshUser()
                        dismiss()
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.system(size: 52))
                .foregroundColor(.yellow)
            Text("Premium'a Geç")
                .font(.title2.bold())
            Text("Tüm platformlardan sınırsız indirme")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }

    private func purchase(plan: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let urlString = try await APIService.shared.getCheckoutURL(plan: plan)
            if let url = URL(string: urlString) {
                safariURL = url
                showSafari = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name).font(.headline)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(plan.price)
                            .font(.title2.bold())
                            .foregroundStyle(Color.brand)
                        Text(plan.period)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button(action: action) {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Satın Al").fontWeight(.semibold).foregroundStyle(.white)
                        }
                    }
                    .frame(width: 76, height: 36)
                    .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isLoading)
            }

            Divider().opacity(0.2)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(plan.features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(Color.brand)
                        Text(feature)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
