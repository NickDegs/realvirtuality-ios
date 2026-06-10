import SwiftUI

struct BulkDownloadView: View {
    @EnvironmentObject var authState: AuthState
    @State private var urlText = ""
    @State private var isFetching = false
    @State private var bulkResponse: BulkDownloadListResponse?
    @State private var selectedIds: Set<String> = []
    @State private var isDownloading = false
    @State private var taskIds: [String] = []
    @State private var errorMessage: String?
    @State private var done = false

    var body: some View {
        NavigationStack {
            Group {
                if done {
                    doneView
                } else if let bulk = bulkResponse {
                    itemListView(bulk)
                } else {
                    inputView
                }
            }
            .navigationTitle("Toplu İndirme")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Hata", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) { Button("Tamam") { errorMessage = nil } }
            message: { Text(errorMessage ?? "") }
        }
    }

    // MARK: - Input

    private var inputView: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.purple)
                    Text("Toplu İndirme").font(.title3.bold())
                    Text("Profil veya playlist URL'si gir, içerikleri listele ve istediğin videoları seç")
                        .font(.caption).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("URL") {
                HStack {
                    TextField("instagram.com/kullanici ya da youtube.com/playlist",
                              text: $urlText, axis: .vertical)
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

            Section {
                Button {
                    Task { await fetchItems() }
                } label: {
                    HStack {
                        Spacer()
                        LoadingLabel(isLoading: isFetching, icon: "list.bullet",
                                     loadingText: "Getiriliyor...", idleText: "İçerikleri Listele")
                        Spacer()
                    }
                }
                .disabled(urlText.isEmpty || isFetching)
            }

            Section("Desteklenen Kaynaklar") {
                Label("Instagram — Profil gönderileri", systemImage: "camera.fill")
                    .foregroundStyle(.pink)
                Label("YouTube — Kanal & Playlist", systemImage: "play.rectangle.fill")
                    .foregroundStyle(.red)
                Label("TikTok — Kullanıcı videoları", systemImage: "music.note")
                    .foregroundStyle(.primary)
                Label("Twitter / X — Kullanıcı medyaları", systemImage: "bird.fill")
                    .foregroundStyle(Color(red: 0.11, green: 0.63, blue: 0.95))
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Item List

    private func itemListView(_ bulk: BulkDownloadListResponse) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(bulk.total) içerik bulundu")
                    .font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Button(selectedIds.count == bulk.items.count ? "Seçimi Kaldır" : "Tümünü Seç") {
                    if selectedIds.count == bulk.items.count { selectedIds.removeAll() }
                    else { selectedIds = Set(bulk.items.map(\.id)) }
                }
                .font(.subheadline.bold()).foregroundStyle(.purple)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            List(bulk.items) { item in
                BulkItemRow(item: item, isSelected: selectedIds.contains(item.id))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedIds.contains(item.id) { selectedIds.remove(item.id) }
                        else { selectedIds.insert(item.id) }
                    }
            }
            .listStyle(.plain)

            Divider()
            Button {
                Task { await startDownloads(bulkId: bulk.bulkId) }
            } label: {
                HStack {
                    Spacer()
                    LoadingLabel(isLoading: isDownloading, icon: "arrow.down.circle.fill",
                                 loadingText: "Başlatılıyor...", idleText: "\(selectedIds.count) İçeriği İndir")
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.purple)
            .disabled(selectedIds.isEmpty || isDownloading)
            .padding()
        }
    }

    // MARK: - Done

    private var doneView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
            VStack(spacing: 8) {
                Text("İndirmeler Başlatıldı!").font(.title2.bold())
                Text("\(taskIds.count) içerik arka planda indiriliyor.\nTamamlananlar galeride görünecek.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Yeni İndirme") {
                done = false; bulkResponse = nil; urlText = ""; selectedIds = []; taskIds = []
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            Spacer()
        }
        .padding()
    }

    // MARK: - Actions

    private func fetchItems() async {
        isFetching = true; errorMessage = nil
        do {
            bulkResponse = try await APIService.shared.fetchBulkItems(url: urlText)
            selectedIds = Set(bulkResponse?.items.map(\.id) ?? [])
        } catch { errorMessage = error.localizedDescription }
        isFetching = false
    }

    private func startDownloads(bulkId: String) async {
        isDownloading = true
        do {
            let response = try await APIService.shared.startBulkDownload(
                bulkId: bulkId, itemIds: Array(selectedIds))
            taskIds = response.taskIds; done = true
        } catch { errorMessage = error.localizedDescription }
        isDownloading = false
    }
}

// MARK: - Bulk Item Row

struct BulkItemRow: View {
    let item: BulkItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color.purple : .secondary)
                .font(.title3)
                .animation(.spring(response: 0.2), value: isSelected)

            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray5))
                    .frame(width: 64, height: 42)
                if let thumb = item.thumbnail, let url = URL(string: thumb) {
                    AsyncImage(url: url) { img in img.resizable().scaledToFill() }
                    placeholder: { Image(systemName: "play.fill").foregroundStyle(.tertiary) }
                        .frame(width: 64, height: 42)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "play.fill").foregroundStyle(.tertiary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title ?? item.url).font(.caption.bold()).lineLimit(2)
                if let duration = item.duration {
                    Text(formatDuration(duration)).font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ seconds: Int) -> String {
        if seconds >= 3600 {
            return String(format: "%d:%02d:%02d", seconds/3600, (seconds%3600)/60, seconds%60)
        }
        return String(format: "%d:%02d", seconds/60, seconds%60)
    }
}
