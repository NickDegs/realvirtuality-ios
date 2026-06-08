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
            ZStack {
                AppBackground()
                Group {
                    if isLoading && items.isEmpty {
                        VStack(spacing: 14) {
                            ProgressView().tint(.purple)
                            Text("Yükleniyor...").font(.caption).foregroundStyle(.secondary)
                        }
                    } else if items.isEmpty {
                        EmptyStateView(
                            icon: "photo.stack",
                            title: "Henüz indirme yok",
                            subtitle: "İndirdiğiniz içerikler burada görünecek"
                        )
                    } else {
                        contentGrid
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

    private var contentGrid: some View {
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
            .padding(.horizontal)
            .padding(.top, 8)

            if isLoading {
                ProgressView().tint(.purple).padding()
            }
        }
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

// MARK: - Gallery Item Card

struct GalleryItemCard: View {
    let item: DownloadHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .aspectRatio(16/9, contentMode: .fit)

                if let thumb = item.thumbnailUrl, let url = URL(string: thumb) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "play.rectangle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "play.rectangle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if let platform = item.platform {
                    Text(platform)
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(LinearGradient.brand, in: Capsule())
                        .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.filename)
                    .font(.caption.bold())
                    .lineLimit(2)
                HStack(spacing: 4) {
                    Text(formatDate(item.completedAt))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if !item.formattedSize.isEmpty {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(item.formattedSize)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .glassCard(radius: 14)
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

// MARK: - Gallery Detail

struct GalleryDetailView: View {
    let item: DownloadHistoryItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        if let thumb = item.thumbnailUrl, let url = URL(string: thumb) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .overlay(ProgressView().tint(.purple))
                            }
                            .frame(maxHeight: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            InfoRow(label: "Dosya", value: item.filename)
                            if !item.formattedSize.isEmpty {
                                Divider()
                                InfoRow(label: "Boyut", value: item.formattedSize)
                            }
                            if let platform = item.platform {
                                Divider()
                                InfoRow(label: "Platform", value: platform)
                            }
                        }
                        .padding(16)
                        .glassCard()

                        if let url = URL(string: item.downloadUrl) {
                            VStack(spacing: 12) {
                                ShareLink(item: url) {
                                    Label("Paylaş / Kaydet", systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(PrimaryButtonStyle())

                                CloudSaveButton(downloadURL: url, filename: item.filename)
                            }
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Detay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}
