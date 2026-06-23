import SwiftUI

struct ScheduledDownloadView: View {
    @EnvironmentObject var authState: AuthState
    @State private var scheduled: [ScheduledDownload] = []
    @State private var isLoading = false
    @State private var showAddSheet = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && scheduled.isEmpty {
                    ProgressView().tint(Theme.accent)
                } else if scheduled.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.clock",
                        title: "Planlı İndirme Yok",
                        subtitle: "Belirli bir saatte otomatik indirilmesini istediğin videoları ekle",
                        action: { showAddSheet = true },
                        actionLabel: "İndirme Planla"
                    )
                } else {
                    List {
                        ForEach(scheduled) { item in
                            scheduledRow(item)
                        }
                        .onDelete { indexSet in
                            for i in indexSet {
                                Task { await deleteItem(id: scheduled[i].id) }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await load() }
                }
            }
            .navigationTitle("Planlı İndirmeler")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddSheet = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAddSheet, onDismiss: { Task { await load() } }) {
                AddScheduledSheet()
            }
            .alert("Hata", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) { Button("Tamam") { errorMessage = nil } }
            message: { Text(errorMessage ?? "") }
        }
        .task { await load() }
    }

    private func scheduledRow(_ item: ScheduledDownload) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                statusBadge(for: item.status)
                Spacer()
                Label(formattedDate(item.scheduledAt), systemImage: "calendar")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            if let title = item.title {
                Text(title).font(.subheadline.bold()).lineLimit(1)
            }
            Text(item.url).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            Label(item.quality == "best" ? "En İyi Kalite" : "\(item.quality)p",
                  systemImage: "slider.horizontal.3")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(for status: String) -> some View {
        let (color, label, icon): (Color, String, String) = {
            switch status {
            case "pending":   return (.orange, "Bekliyor", "clock.fill")
            case "completed": return (.green, "Tamamlandı", "checkmark.circle.fill")
            case "failed":    return (.red, "Başarısız", "xmark.circle.fill")
            default:          return (.secondary, status, "circle")
            }
        }()
        return HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(label).font(.caption2.bold())
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(color.opacity(0.15), in: Capsule())
    }

    private func formattedDate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = f.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) else { return iso }
        let df = DateFormatter()
        df.dateStyle = .medium; df.timeStyle = .short
        df.locale = Locale(identifier: "tr_TR")
        return df.string(from: date)
    }

    private func load() async {
        isLoading = true
        do { scheduled = try await APIService.shared.getScheduledDownloads() }
        catch APIError.unauthorized { authState.logout() }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    private func deleteItem(id: String) async {
        scheduled.removeAll { $0.id == id }
        try? await APIService.shared.deleteScheduledDownload(id: id)
    }
}

// MARK: - Add Sheet

struct AddScheduledSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authState: AuthState
    @State private var urlText = ""
    @State private var scheduledDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var quality = "best"
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Video URL'si") {
                    HStack {
                        TextField("Instagram, TikTok, X…", text: $urlText)
                            .keyboardType(.URL).autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        Button {
                            urlText = UIPasteboard.general.string ?? ""
                        } label: {
                            Image(systemName: "doc.on.clipboard").foregroundStyle(Theme.accent)
                        }
                    }
                }

                Section("İndirme Zamanı") {
                    DatePicker("Tarih ve Saat", selection: $scheduledDate,
                               in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                }

                Section("Kalite") {
                    Picker("Kalite", selection: $quality) {
                        Text("En İyi").tag("best")
                        Text("1080p").tag("1080")
                        Text("720p").tag("720")
                        Text("480p").tag("480")
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                }

                Section {
                    Button {
                        Task { await save() }
                    } label: {
                        HStack {
                            Spacer()
                            LoadingLabel(isLoading: isSaving, icon: "calendar.badge.plus",
                                         loadingText: "Planlanıyor...", idleText: "İndirmeyi Planla")
                            Spacer()
                        }
                    }
                    .disabled(urlText.isEmpty || isSaving)
                }
            }
            .navigationTitle("İndirme Planla")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
            .alert("Hata", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) { Button("Tamam") { errorMessage = nil } }
            message: { Text(errorMessage ?? "") }
        }
    }

    private func save() async {
        isSaving = true
        do {
            _ = try await APIService.shared.scheduleDownload(
                url: urlText, scheduledAt: scheduledDate, quality: quality)
            dismiss()
        } catch APIError.unauthorized { authState.logout() }
        catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}
