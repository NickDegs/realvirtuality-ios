import SwiftUI

struct BulkDownloadView: View {
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) private var dismiss
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }
                }
            }
            .alert("Hata", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) { Button("Tamam") { errorMessage = nil } }
            message: { Text(errorMessage ?? "") }
        }
    }

    // MARK: - Input

    private var inputView: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Profil veya Playlist URL'si")
                    .font(.headline)
                Text("Instagram profil, YouTube playlist, TikTok kullanıcı sayfası gibi URL'leri destekler")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            TextField("instagram.com/kullanici veya youtube.com/playlist...", text: $urlText, axis: .vertical)
                .textFieldStyle(.plain)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

            Button {
                Task { await fetchItems() }
            } label: {
                HStack {
                    if isFetching { ProgressView().tint(.white) }
                    else { Image(systemName: "list.bullet") }
                    Text(isFetching ? "Getiriliyor..." : "İçerikleri Listele")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(urlText.isEmpty ? Color.gray : Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(urlText.isEmpty || isFetching)

            Spacer()
        }
        .padding()
    }

    // MARK: - Item List

    private func itemListView(_ bulk: BulkDownloadListResponse) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(bulk.total) içerik bulundu")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button(selectedIds.count == bulk.items.count ? "Seçimi Kaldır" : "Tümünü Seç") {
                    if selectedIds.count == bulk.items.count {
                        selectedIds.removeAll()
                    } else {
                        selectedIds = Set(bulk.items.map(\.id))
                    }
                }
                .font(.subheadline)
            }
            .padding()

            List(bulk.items) { item in
                HStack(spacing: 12) {
                    Image(systemName: selectedIds.contains(item.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selectedIds.contains(item.id) ? .purple : .secondary)
                        .font(.title3)

                    if let thumb = item.thumbnail, let url = URL(string: thumb) {
                        AsyncImage(url: url) { img in img.resizable().scaledToFill() }
                            placeholder: { Color(.systemGray5) }
                            .frame(width: 60, height: 40)
                            .cornerRadius(6)
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                            .frame(width: 60, height: 40)
                            .overlay(Image(systemName: "play.fill").foregroundColor(.secondary))
                    }

                    Text(item.title ?? item.url)
                        .font(.caption)
                        .lineLimit(2)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedIds.contains(item.id) { selectedIds.remove(item.id) }
                    else { selectedIds.insert(item.id) }
                }
            }
            .listStyle(.plain)

            VStack(spacing: 0) {
                Divider()
                Button {
                    Task { await startDownloads(bulkId: bulk.bulkId) }
                } label: {
                    HStack {
                        if isDownloading { ProgressView().tint(.white) }
                        else { Image(systemName: "arrow.down.circle.fill") }
                        Text(isDownloading ? "Başlatılıyor..." : "\(selectedIds.count) İçeriği İndir")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedIds.isEmpty ? Color.gray : Color.purple)
                    .foregroundColor(.white)
                }
                .disabled(selectedIds.isEmpty || isDownloading)
                .padding()
            }
        }
    }

    // MARK: - Done

    private var doneView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.green)
            Text("İndirmeler Başlatıldı!")
                .font(.title2.bold())
            Text("\(taskIds.count) içerik arka planda indiriliyor.\nTamamlananlar galeride görünecek.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("Kapat") { dismiss() }
                .font(.headline)
                .foregroundColor(.purple)
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
