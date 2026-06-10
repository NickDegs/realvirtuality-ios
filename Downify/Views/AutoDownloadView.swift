import SwiftUI

struct AutoDownloadView: View {
    @EnvironmentObject var authState: AuthState
    @State private var subscriptions: [AutoSubscription] = []
    @State private var isLoading = false
    @State private var showAddSheet = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && subscriptions.isEmpty {
                    ProgressView().tint(.purple)
                } else if subscriptions.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.2.circlepath",
                        title: "Otomatik indirme yok",
                        subtitle: "Bir hesabı takip edin, yeni içerikler otomatik indirilsin",
                        action: { showAddSheet = true },
                        actionLabel: "Hesap Ekle"
                    )
                } else {
                    List {
                        ForEach(subscriptions) { sub in
                            autoSubRow(sub)
                        }
                        .onDelete { indexSet in
                            for i in indexSet {
                                Task { await deleteSubscription(id: subscriptions[i].id) }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await load() }
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

    private func autoSubRow(_ sub: AutoSubscription) -> some View {
        HStack(spacing: 12) {
            Image(systemName: sub.active ? "checkmark.circle.fill" : "pause.circle.fill")
                .foregroundStyle(sub.active ? .green : .orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(sub.title ?? sub.url)
                    .font(.subheadline.bold()).lineLimit(1)
                Text(sub.url).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                HStack(spacing: 8) {
                    Label(frequencyLabel(sub.frequency), systemImage: "clock")
                        .font(.caption2).foregroundStyle(.secondary)
                    if sub.downloadCount > 0 {
                        Text("• \(sub.downloadCount) indirme")
                            .font(.caption2).foregroundStyle(.purple)
                    }
                }
            }

            Spacer()

            if let last = sub.lastChecked {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Son").font(.caption2).foregroundStyle(.secondary)
                    Text(relativeDate(last)).font(.caption2.bold()).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
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

    private func load() async {
        isLoading = true
        do { subscriptions = try await APIService.shared.getAutoSubscriptions() }
        catch APIError.unauthorized { authState.logout() }
        catch {}
        isLoading = false
    }

    private func addSubscription(url: String, frequency: String) async {
        do {
            let sub = try await APIService.shared.addAutoSubscription(url: url, frequency: frequency)
            subscriptions.append(sub)
        } catch { errorMessage = error.localizedDescription }
    }

    private func deleteSubscription(id: String) async {
        do {
            try await APIService.shared.deleteAutoSubscription(id: id)
            subscriptions.removeAll { $0.id == id }
        } catch { errorMessage = error.localizedDescription }
    }
}

// MARK: - Add Sheet

struct AddAutoSubscriptionSheet: View {
    let onAdd: (String, String) async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var urlText = ""
    @State private var frequency = "daily"
    @State private var isAdding = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Hesap / Sayfa URL'si") {
                    HStack {
                        TextField("instagram.com/hesap veya youtube.com/kanal", text: $urlText)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        Button {
                            urlText = UIPasteboard.general.string ?? ""
                        } label: {
                            Image(systemName: "doc.on.clipboard").foregroundStyle(.purple)
                        }
                    }
                }

                Section("Kontrol Sıklığı") {
                    Picker("Sıklık", selection: $frequency) {
                        Text("Saatte bir").tag("hourly")
                        Text("Günlük").tag("daily")
                        Text("Haftalık").tag("weekly")
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section {
                    Text("Seçilen hesapta yeni içerik yayımlandığında otomatik indirilecek.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        Task {
                            isAdding = true
                            await onAdd(urlText, frequency)
                            isAdding = false
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            LoadingLabel(isLoading: isAdding, icon: "plus.circle.fill",
                                         loadingText: "Ekleniyor...", idleText: "Hesap Ekle")
                            Spacer()
                        }
                    }
                    .disabled(urlText.isEmpty || isAdding)
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
