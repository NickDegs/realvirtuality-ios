import SwiftUI

struct ScheduledDownloadView: View {
    @EnvironmentObject var authState: AuthState
    @State private var scheduled: [ScheduledDownload] = []
    @State private var isLoading = false
    @State private var showAddSheet = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                Group {
                    if isLoading && scheduled.isEmpty {
                        VStack(spacing: 14) {
                            ProgressView().tint(.purple)
                            Text("Yükleniyor...").font(.caption).foregroundStyle(.secondary)
                        }
                    } else if scheduled.isEmpty {
                        emptyState
                    } else {
                        scheduledList
                    }
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

    // MARK: - Empty

    private var emptyState: some View {
        EmptyStateView(
            icon: "calendar.badge.clock",
            title: "Planlı İndirme Yok",
            subtitle: "Belirli bir saatte otomatik indirilmesini istediğin videoları ekle",
            action: { showAddSheet = true },
            actionLabel: "İndirme Planla"
        )
    }

    // MARK: - List

    private var scheduledList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(scheduled) { item in
                    ScheduledRow(item: item) {
                        await deleteItem(id: item.id)
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
            scheduled = try await APIService.shared.getScheduledDownloads()
        } catch APIError.unauthorized {
            authState.logout()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func deleteItem(id: String) async {
        scheduled.removeAll { $0.id == id }
        try? await APIService.shared.deleteScheduledDownload(id: id)
    }
}

// MARK: - Scheduled Row

struct ScheduledRow: View {
    let item: ScheduledDownload
    let onDelete: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                statusBadge
                Spacer()
                Label(formattedDate(item.scheduledAt), systemImage: "calendar")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let title = item.title {
                Text(title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
            }

            Text(item.url)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack(spacing: 4) {
                Image(systemName: "slider.horizontal.3").font(.caption2)
                Text(item.quality == "best" ? "En İyi Kalite" : "\(item.quality)p").font(.caption2)
            }
            .foregroundStyle(.secondary)
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

    private var statusBadge: some View {
        let (color, label, icon): (Color, String, String) = {
            switch item.status {
            case "pending":   return (.orange, "Bekliyor", "clock.fill")
            case "completed": return (.green, "Tamamlandı", "checkmark.circle.fill")
            case "failed":    return (.red, "Başarısız", "xmark.circle.fill")
            default:          return (.secondary, item.status, "circle")
            }
        }()
        return HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(label).font(.caption2.bold())
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15), in: Capsule())
    }

    private func formattedDate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = f.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) else { return iso }
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        df.locale = Locale(identifier: "tr_TR")
        return df.string(from: date)
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
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Video URL'si")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            HStack {
                                TextField("Instagram, TikTok, YouTube...", text: $urlText)
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
                            Text("İndirme Zamanı")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            DatePicker(
                                "Tarih ve Saat",
                                selection: $scheduledDate,
                                in: Date()...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.graphical)
                            .padding(14)
                            .glassCard()
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Kalite")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            Picker("Kalite", selection: $quality) {
                                Text("En İyi").tag("best")
                                Text("1080p").tag("1080")
                                Text("720p").tag("720")
                                Text("480p").tag("480")
                            }
                            .pickerStyle(.segmented)
                        }

                        Button {
                            Task { await save() }
                        } label: {
                            LoadingLabel(
                                isLoading: isSaving,
                                icon: "calendar.badge.plus",
                                loadingText: "Planlanıyor...",
                                idleText: "İndirmeyi Planla"
                            )
                        }
                        .buttonStyle(PrimaryButtonStyle(enabled: !urlText.isEmpty && !isSaving))
                        .disabled(urlText.isEmpty || isSaving)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
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
