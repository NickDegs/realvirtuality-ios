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
                    ProgressView("Yükleniyor...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if scheduled.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(scheduled) { item in
                            ScheduledRow(item: item)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.plain)
                    .refreshable { await load() }
                }
            }
            .navigationTitle("Planlı İndirmeler")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
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

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundStyle(LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom))
            Text("Planlı İndirme Yok")
                .font(.title2.bold())
            Text("Belirli bir saatte otomatik indirilmesini istediğin videoları ekle")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button { showAddSheet = true } label: {
                Label("İndirme Planla", systemImage: "plus")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            Spacer()
        }
    }

    private func load() async {
        isLoading = true
        do {
            scheduled = try await APIService.shared.getScheduledDownloads()
        } catch APIError.unauthorized {
            authState.logout()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func deleteItems(at offsets: IndexSet) {
        let ids = offsets.map { scheduled[$0].id }
        scheduled.remove(atOffsets: offsets)
        Task {
            for id in ids {
                try? await APIService.shared.deleteScheduledDownload(id: id)
            }
        }
    }
}

struct ScheduledRow: View {
    let item: ScheduledDownload

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                statusBadge
                Spacer()
                Text(formattedDate(item.scheduledAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let title = item.title {
                Text(title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
            }
            Text(item.url)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
            HStack(spacing: 4) {
                Image(systemName: "slider.horizontal.3")
                    .font(.caption2)
                Text(item.quality == "best" ? "En İyi Kalite" : "\(item.quality)p")
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        let (color, label): (Color, String) = {
            switch item.status {
            case "pending": return (.orange, "Bekliyor")
            case "completed": return (.green, "Tamamlandı")
            case "failed": return (.red, "Başarısız")
            default: return (.secondary, item.status)
            }
        }()
        return Text(label)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(6)
    }

    private func formattedDate(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) else {
            return iso
        }
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        df.locale = Locale(identifier: "tr_TR")
        return df.string(from: date)
    }
}

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
                        TextField("Instagram, TikTok, YouTube...", text: $urlText)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        Button {
                            urlText = UIPasteboard.general.string ?? ""
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                                .foregroundColor(.purple)
                        }
                    }
                }

                Section("İndirme Zamanı") {
                    DatePicker(
                        "Tarih ve Saat",
                        selection: $scheduledDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section("Kalite") {
                    Picker("Kalite", selection: $quality) {
                        Text("En İyi").tag("best")
                        Text("1080p").tag("1080")
                        Text("720p").tag("720")
                        Text("480p").tag("480")
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button {
                        Task { await save() }
                    } label: {
                        HStack {
                            if isSaving { ProgressView().tint(.white) }
                            else { Image(systemName: "calendar.badge.plus") }
                            Text(isSaving ? "Planlanıyor..." : "İndirmeyi Planla")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundColor(.white)
                    }
                    .listRowBackground(urlText.isEmpty || isSaving ? Color.gray : Color.purple)
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
                url: urlText,
                scheduledAt: scheduledDate,
                quality: quality
            )
            dismiss()
        } catch APIError.unauthorized {
            authState.logout()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
