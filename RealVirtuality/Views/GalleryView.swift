import SwiftUI

struct GalleryView: View {
    @EnvironmentObject var authState: AuthState
    @State private var items: [DownloadHistoryItem] = []
    @State private var isLoading = false
    @State private var page = 1
    @State private var hasMore = true
    @State private var selectedItem: DownloadHistoryItem?

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && items.isEmpty {
                    ProgressView()
                } else if items.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(items) { item in
                                GalleryItemCard(item: item)
                                    .onTapGesture { selectedItem = item }
                                    .onAppear {
                                        if item.id == items.last?.id && hasMore {
                                            Task { await loadMore() }
                                        }
                                    }
                            }
                        }
                        .padding()
                        if isLoading {
                            ProgressView().padding()
                        }
                    }
                }
            }
            .navigationTitle("Galeri")
            .task { await load() }
            .refreshable { await refresh() }
            .sheet(item: $selectedItem) { item in
                GalleryDetailView(item: item)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Henüz indirme yok")
                .font(.headline)
            Text("İndirdiğiniz içerikler burada görünecek")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func load() async {
        isLoading = true
        do {
            items = try await APIService.shared.getDownloadHistory(page: 1)
            hasMore = items.count >= 20
            page = 1
        } catch APIError.unauthorized {
            authState.logout()
        } catch {}
        isLoading = false
    }

    private func refresh() async {
        page = 1
        hasMore = true
        await load()
    }

    private func loadMore() async {
        guard !isLoading else { return }
        isLoading = true
        page += 1
        do {
            let more = try await APIService.shared.getDownloadHistory(page: page)
            items.append(contentsOf: more)
            hasMore = more.count >= 20
        } catch {}
        isLoading = false
    }
}

struct GalleryItemCard: View {
    let item: DownloadHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray5))
                    .aspectRatio(16/9, contentMode: .fit)

                if let thumb = item.thumbnailUrl, let url = URL(string: thumb) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "play.rectangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "play.rectangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                }

                if let platform = item.platform {
                    Text(platform)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(6)
                }
            }

            Text(item.filename)
                .font(.caption)
                .lineLimit(2)
                .foregroundColor(.primary)

            Text(formatDate(item.completedAt))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func formatDate(_ str: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: str) else { return str }
        let display = DateFormatter()
        display.dateStyle = .short
        display.timeStyle = .none
        return display.string(from: date)
    }
}

struct GalleryDetailView: View {
    let item: DownloadHistoryItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let thumb = item.thumbnailUrl, let url = URL(string: thumb) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Rectangle().fill(Color(.systemGray5))
                    }
                    .frame(maxHeight: 250)
                    .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(item.filename)
                        .font(.headline)
                    if let size = item.fileSize {
                        Text(formatSize(size))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                VStack(spacing: 12) {
                    if let url = URL(string: item.downloadUrl) {
                        ShareLink(item: url) {
                            Label("Paylaş / Kaydet", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        CloudSaveButton(downloadURL: url, filename: item.filename)
                            .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Detay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    private func formatSize(_ bytes: Int) -> String {
        let mb = Double(bytes) / 1_000_000
        return String(format: "%.1f MB", mb)
    }
}
