import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var store: StoreManager

    private struct Meta { let title: String; let features: [String]; let highlighted: Bool }

    private let meta: [String: Meta] = [
        "app.downify.pro": Meta(
            title: "Pro",
            features: ["Öncelikli indirme", "Tüm platformlar", "Sınırsız indirme"],
            highlighted: false),
        "app.downify.full.monthly": Meta(
            title: "Full — Aylık",
            features: ["Tüm özellikler", "Kestirme & Siri desteği", "HD kalite"],
            highlighted: true),
        "app.downify.full.yearly": Meta(
            title: "Full — Yıllık",
            features: ["Tüm özellikler", "Yıllık avantaj", "Kestirme & Siri desteği"],
            highlighted: false),
        "app.downify.full.lifetime": Meta(
            title: "Ömür Boyu",
            features: ["Tüm özellikler", "Tek seferlik ödeme", "Kalıcı lisans"],
            highlighted: false),
    ]

    private let termsURL = URL(string: "https://realvirtuality.app/terms.html")!
    private let privacyURL = URL(string: "https://realvirtuality.app/downify-privacy.html")!

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

                if store.products.isEmpty {
                    Section {
                        HStack {
                            Spacer()
                            if store.isLoading { ProgressView() }
                            else { Text("Ürünler yüklenemedi").foregroundStyle(.secondary) }
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)
                }

                ForEach(orderedProducts, id: \.id) { product in
                    Section { planRow(product) }
                }

                if let error = store.error {
                    Section {
                        Text(error).font(.caption).foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                    .listRowBackground(Color.clear)
                }

                Section {
                    Button {
                        Task { await store.restore(); await syncAndMaybeDismiss() }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Satın Alımları Geri Yükle")
                            Spacer()
                        }
                    }
                    .disabled(store.isLoading)
                }

                Section {
                    disclosure
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
            .task {
                if store.products.isEmpty { await store.loadProducts() }
            }
        }
    }

    private var orderedProducts: [Product] {
        let order = StoreManager.productIDs
        return store.products.sorted {
            (order.firstIndex(of: $0.id) ?? 99) < (order.firstIndex(of: $1.id) ?? 99)
        }
    }

    private func planRow(_ product: Product) -> some View {
        let m = meta[product.id]
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(m?.title ?? product.displayName).font(.headline)
                        if m?.highlighted == true {
                            Text("Popüler")
                                .font(.caption2.bold()).foregroundStyle(.white)
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(Theme.accent, in: Capsule())
                        }
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(product.displayPrice).font(.title2.bold()).foregroundStyle(Theme.accent)
                        if let period = periodText(product) {
                            Text(period).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
                Button {
                    Task {
                        if await store.purchase(product) { await syncAndMaybeDismiss() }
                    }
                } label: {
                    if store.purchasing == product.id {
                        ProgressView().frame(width: 76, height: 36)
                    } else {
                        Text("Satın Al")
                            .fontWeight(.semibold)
                            .frame(width: 76, height: 36)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .disabled(store.purchasing != nil)
            }

            if let features = m?.features {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(features, id: \.self) { feature in
                        Label(feature, systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func periodText(_ product: Product) -> String? {
        guard let period = product.subscription?.subscriptionPeriod else { return nil }
        switch period.unit {
        case .day:   return period.value == 7 ? "/ hafta" : "/ \(period.value) gün"
        case .week:  return "/ hafta"
        case .month: return period.value == 1 ? "/ ay" : "/ \(period.value) ay"
        case .year:  return "/ yıl"
        @unknown default: return nil
        }
    }

    // Required auto-renewable subscription disclosure + functional links.
    private var disclosure: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Abonelikler, mevcut dönem bitmeden en az 24 saat önce iptal edilmezse otomatik yenilenir. Ödeme, satın alma onayında Apple Kimliğinize yansıtılır. Aboneliği App Store hesap ayarlarından yönetebilir veya iptal edebilirsiniz.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                Link("Kullanım Koşulları", destination: termsURL)
                Link("Gizlilik Politikası", destination: privacyURL)
            }
            .font(.caption2.bold())
        }
        .padding(.vertical, 4)
    }

    private func syncAndMaybeDismiss() async {
        await authState.refreshUser()
        if authState.tier == .full || store.entitledTier != .free {
            dismiss()
        }
    }
}
