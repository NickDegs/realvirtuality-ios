import SwiftUI

struct AutoDownloadView: View {
    @EnvironmentObject var authState: AuthState
    @State private var subscriptions: [AutoSubscription] = []
    @State private var isLoading = false
    @State private var showAddSheet = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                Group {
                    if isLoading && subscriptions.isEmpty {
                        VStack(spacing: 14) {
                            ProgressView().tint(.purple)
                            Text("Yükleniyor...").font(.caption).foregroundStyle(.secondary)
                        }
                    } else if subscriptions.isEmpty {
                        emptyState
                    } else {
                        subscriptionList
                    }
                }
            }
            .navigationTitle("Otomatik İndirme")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task { await load() }
            .sheet(isPresented: $showAddSheet) {
                AddAutoSubscriptionSheet { url, frequency in
                    await addSubscription(url: url, frequency: frequency)
                }
            }
            .alert("Hata", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) { Button("Tamam") { errorMessage = nil } }
            message: { Text(errorMessage ?? "") }
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        EmptyStateView(
            icon: "clock.arrow.2.circlepath",
            title: "Otomatik indirme yok",
            subtitle: "Bir hesabı takip edin, yeni içerikler otomatik indirilsin",
            action: { showAddSheet = true },
            actionLabel: "Hesap Ekle"
        )
    }

    // MARK: - List

    private var subscriptionList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(subscriptions) { sub in
                    AutoSubscriptionRow(subscription: sub) {
                        await deleteSubscription(id: sub.id)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .refreshable { await load() }
    }

    // MARK: - Actions

    private func load() async {
        isLoading = true
        do {
            subscriptions = try await APIService.shared.getAutoSubscriptions()
        } catch APIError.unauthorized {
            authState.logout()
        } catch {}
        isLoading = false
    }

    private func addSubscription(url: String, frequency: String) async {
        do {
            let sub = try await APIService.shared.addAutoSubscription(url: url, frequency: frequency)
            subscriptions.append(sub)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteSubscription(id: String) async {
        do {
            try await APIService.shared.deleteAutoSubscription(id: id)
            subscriptions.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Subscription Row

struct AutoSubscriptionRow: View {
    let subscription: AutoSubscription
    let onDelete: () async -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(subscription.active ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: subscription.active ? "checkmark.circle.fill" : "pause.circle.fill")
                    .foregroundStyle(subscription.active ? .green : .orange)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.title ?? subscription.url)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(subscription.url)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Label(frequencyLabel(subscription.frequency), systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if subscription.downloadCount > 0 {
                        Text("• \(subscription.downloadCount) indirme")
                            .font(.caption2)
                            .foregroundStyle(Color.brand.opacity(0.8))
                    }
                }
            }

            Spacer()

            if let last = subscription.lastChecked {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Son")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(relativeDate(last))
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .glassCard()
        .contextMenu {
            Button(role: .destructive) {
                Task { await onDelete() }
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
    }

    private func frequencyLabel(_ f: String) -> String {
        switch f {
        case "hourly": return "Saatte bir"
        case "daily":  return "Günlük"
        case "weekly": return "Haftalık"
        default:       return f
        }
    }

    private func relativeDate(_ str: String) -> String {
        let f = ISO8601DateFormatter()
        guard let d = f.date(from: str) else { return str }
        let r = RelativeDateTimeFormatter()
        r.locale = Locale(identifier: "tr")
        return r.localizedString(for: d, relativeTo: Date())
    }
}

// MARK: - Add Sheet

struct AddAutoSubscriptionSheet: View {
    let onAdd: (String, String) async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var urlText = ""
    @State private var frequency = "daily"
    @State private var isAdding = false

    let frequencies = [("hourly", "Saatte bir"), ("daily", "Günlük"), ("weekly", "Haftalık")]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Hesap / Sayfa URL'si")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            HStack {
                                TextField("instagram.com/hesap veya youtube.com/kanal", text: $urlText)
                                    .textFieldStyle(.plain)
                                    .keyboardType(.URL)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                Button {
                                    urlText = UIPasteboard.general.string ?? ""
                                } label: {
                                    Image(systemName: "doc.on.clipboard").foregroundStyle(.purple)
                                }
                            }
                            .padding(14)
                            .glassInput()
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Kontrol Sıklığı")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            VStack(spacing: 8) {
                                ForEach(frequencies, id: \.0) { f in
                                    Button {
                                        frequency = f.0
                                    } label: {
                                        HStack {
                                            ZStack {
                                                Circle()
                                                    .stroke(frequency == f.0 ? Color.brand : Color.white.opacity(0.3), lineWidth: 1.5)
                                                    .frame(width: 20, height: 20)
                                                if frequency == f.0 {
                                                    Circle().fill(Color.brand).frame(width: 10, height: 10)
                                                }
                                            }
                                            Text(f.1).font(.subheadline)
                                            Spacer()
                                        }
                                        .padding(14)
                                        .glassCard()
                                    }
                                    .buttonStyle(.plain)
                                    .animation(.spring(response: 0.2), value: frequency)
                                }
                            }
                        }

                        Text("Seçilen hesapta yeni içerik yayımlandığında otomatik indirilecek.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            Task {
                                isAdding = true
                                await onAdd(urlText, frequency)
                                isAdding = false
                                dismiss()
                            }
                        } label: {
                            LoadingLabel(
                                isLoading: isAdding,
                                icon: "plus.circle.fill",
                                loadingText: "Ekleniyor...",
                                idleText: "Hesap Ekle"
                            )
                        }
                        .buttonStyle(PrimaryButtonStyle(enabled: !urlText.isEmpty && !isAdding))
                        .disabled(urlText.isEmpty || isAdding)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Hesap Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
        }
    }
}
