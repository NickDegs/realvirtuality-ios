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
                    ProgressView()
                } else if subscriptions.isEmpty {
                    emptyState
                } else {
                    list
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

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.2.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Otomatik indirme yok")
                .font(.headline)
            Text("Bir hesabı takip edin, yeni içerikler otomatik indirilsin")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showAddSheet = true
            } label: {
                Label("Hesap Ekle", systemImage: "plus.circle.fill")
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }

    private var list: some View {
        List {
            ForEach(subscriptions) { sub in
                AutoSubscriptionRow(subscription: sub) {
                    await deleteSubscription(id: sub.id)
                }
            }
            .onDelete { indexSet in
                Task {
                    for i in indexSet {
                        await deleteSubscription(id: subscriptions[i].id)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
    }

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

struct AutoSubscriptionRow: View {
    let subscription: AutoSubscription
    let onDelete: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: subscription.active ? "checkmark.circle.fill" : "pause.circle.fill")
                    .foregroundColor(subscription.active ? .green : .orange)
                Text(subscription.title ?? subscription.url)
                    .font(.subheadline.bold())
                    .lineLimit(1)
            }
            Text(subscription.url)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            HStack {
                Label(frequencyLabel(subscription.frequency), systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let last = subscription.lastChecked {
                    Text("Son: \(formatDate(last))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text("\(subscription.downloadCount) indirme")
                    .font(.caption2)
                    .foregroundColor(.purple)
            }
        }
        .padding(.vertical, 4)
    }

    private func frequencyLabel(_ f: String) -> String {
        switch f {
        case "hourly": return "Saatte bir"
        case "daily": return "Günlük"
        case "weekly": return "Haftalık"
        default: return f
        }
    }

    private func formatDate(_ str: String) -> String {
        let f = ISO8601DateFormatter()
        guard let d = f.date(from: str) else { return str }
        let r = RelativeDateTimeFormatter()
        r.locale = Locale(identifier: "tr")
        return r.localizedString(for: d, relativeTo: Date())
    }
}

struct AddAutoSubscriptionSheet: View {
    let onAdd: (String, String) async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var urlText = ""
    @State private var frequency = "daily"
    @State private var isAdding = false

    let frequencies = [("hourly", "Saatte bir"), ("daily", "Günlük"), ("weekly", "Haftalık")]

    var body: some View {
        NavigationStack {
            Form {
                Section("Hesap / Sayfa URL'si") {
                    TextField("instagram.com/hesap veya youtube.com/kanal", text: $urlText)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Kontrol Sıklığı") {
                    Picker("Sıklık", selection: $frequency) {
                        ForEach(frequencies, id: \.0) { f in
                            Text(f.1).tag(f.0)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section {
                    Text("Seçilen hesapta yeni içerik yayımlandığında otomatik olarak indirilecek.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Hesap Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            isAdding = true
                            await onAdd(urlText, frequency)
                            isAdding = false
                            dismiss()
                        }
                    } label: {
                        if isAdding { ProgressView() } else { Text("Ekle").bold() }
                    }
                    .disabled(urlText.isEmpty || isAdding)
                }
            }
        }
    }
}
