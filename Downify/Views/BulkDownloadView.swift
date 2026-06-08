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
            ZStack {
                AppBackground()
                Group {
                    if done {
                        doneView
                    } else if let bulk = bulkResponse {
                        itemListView(bulk)
                    } else {
                        inputView
                    }
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
        ScrollView {
            VStack(spacing: 20) {
                heroSection

                VStack(alignment: .leading, spacing: 10) {
                    Text("Profil veya Playlist URL'si")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    HStack(spacing: 10) {
                        TextField("instagram.com/kullanici ya da youtube.com/playlist", text: $urlText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        Button {
                            urlText = UIPasteboard.general.string ?? ""
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                                .foregroundStyle(.purple)
                        }
                    }
                    .padding(14)
                    .glassInput()
                }

                Button {
                    Task { await fetchItems() }
                } label: {
                    LoadingLabel(
                        isLoading: isFetching,
                        icon: "list.bullet",
                        loadingText: "Getiriliyor...",
                        idleText: "İçerikleri Listele"
                    )
                }
                .buttonStyle(PrimaryButtonStyle(enabled: !urlText.isEmpty && !isFetching))
                .disabled(urlText.isEmpty || isFetching)

                supportedSourcesCard
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    private var heroSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.brand.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(LinearGradient.brand)
            }
            Text("Toplu İndirme")
                .font(.title3.bold())
            Text("Profil veya playlist URL'si gir, içerikleri listele ve istediğin videoları seç")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }

    private var supportedSourcesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Desteklenen Kaynaklar")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            VStack(spacing: 0) {
                sourceRow(icon: "camera.fill", color: .pink, title: "Instagram", subtitle: "Profil gönderileri")
                Divider().padding(.leading, 48)
                sourceRow(icon: "play.rectangle.fill", color: .red, title: "YouTube", subtitle: "Kanal & Playlist")
                Divider().padding(.leading, 48)
                sourceRow(icon: "music.note", color: .black, title: "TikTok", subtitle: "Kullanıcı videoları")
                Divider().padding(.leading, 48)
                sourceRow(icon: "bird.fill", color: Color(red: 0.11, green: 0.63, blue: 0.95), title: "Twitter / X", subtitle: "Kullanıcı medyaları")
            }
        }
        .padding(16)
        .glassCard()
    }

    private func sourceRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }

    // MARK: - Item List

    private func itemListView(_ bulk: BulkDownloadListResponse) -> some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Text("\(bulk.total)")
                        .font(.subheadline.bold())
                    Text("içerik bulundu")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(selectedIds.count == bulk.items.count ? "Seçimi Kaldır" : "Tümünü Seç") {
                    if selectedIds.count == bulk.items.count {
                        selectedIds.removeAll()
                    } else {
                        selectedIds = Set(bulk.items.map(\.id))
                    }
                }
                .font(.subheadline.bold())
                .foregroundStyle(.purple)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            if !selectedIds.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.purple)
                    Text("\(selectedIds.count) seçili")
                        .font(.caption.bold())
                        .foregroundStyle(.purple)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }

            List(bulk.items) { item in
                BulkItemRow(item: item, isSelected: selectedIds.contains(item.id))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedIds.contains(item.id) { selectedIds.remove(item.id) }
                        else { selectedIds.insert(item.id) }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(.white.opacity(0.1))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)

            VStack(spacing: 0) {
                Divider().opacity(0.2)
                Button {
                    Task { await startDownloads(bulkId: bulk.bulkId) }
                } label: {
                    LoadingLabel(
                        isLoading: isDownloading,
                        icon: "arrow.down.circle.fill",
                        loadingText: "Başlatılıyor...",
                        idleText: "\(selectedIds.count) İçeriği İndir"
                    )
                }
                .buttonStyle(PrimaryButtonStyle(enabled: !selectedIds.isEmpty && !isDownloading))
                .disabled(selectedIds.isEmpty || isDownloading)
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(.regularMaterial)
        }
    }

    // MARK: - Done

    private var doneView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.green)
            }
            VStack(spacing: 8) {
                Text("İndirmeler Başlatıldı!")
                    .font(.title2.bold())
                Text("\(taskIds.count) içerik arka planda indiriliyor.\nTamamlananlar galeride görünecek.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Yeni İndirme") {
                done = false
                bulkResponse = nil
                urlText = ""
                selectedIds = []
                taskIds = []
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
            Spacer()
        }
        .padding()
    }

    // MARK: - Actions

    private func fetchItems() async {
        isFetching = true
        errorMessage = nil
        do {
            bulkResponse = try await APIService.shared.fetchBulkItems(url: urlText)
            selectedIds = Set(bulkResponse?.items.map(\.id) ?? [])
        } catch {
            errorMessage = error.localizedDescription
        }
        isFetching = false
    }

    private func startDownloads(bulkId: String) async {
        isDownloading = true
        do {
            let response = try await APIService.shared.startBulkDownload(
                bulkId: bulkId,
                itemIds: Array(selectedIds)
            )
            taskIds = response.taskIds
            done = true
        } catch {
            errorMessage = error.localizedDescription
        }
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
                .foregroundStyle(isSelected ? Color.brand : .secondary)
                .font(.title3)
                .animation(.spring(response: 0.2), value: isSelected)

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 64, height: 42)

                if let thumb = item.thumbnail, let url = URL(string: thumb) {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "play.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .frame(width: 64, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "play.fill")
                        .foregroundStyle(.tertiary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title ?? item.url)
                    .font(.caption.bold())
                    .lineLimit(2)
                if let duration = item.duration {
                    Text(formatDuration(duration))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }

    private func formatDuration(_ seconds: Int) -> String {
        if seconds >= 3600 {
            return String(format: "%d:%02d:%02d", seconds/3600, (seconds%3600)/60, seconds%60)
        }
        return String(format: "%d:%02d", seconds/60, seconds%60)
    }
}
