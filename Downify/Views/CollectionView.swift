import SwiftUI

struct CollectionView: View {
    @EnvironmentObject var authState: AuthState
    @State private var collections: [MediaCollection] = []
    @State private var history: [DownloadHistoryItem] = []
    @State private var isLoading = false
    @State private var showCreate = false
    @State private var selectedCollection: MediaCollection?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && collections.isEmpty {
                    VStack(spacing: 14) {
                        ProgressView().tint(Theme.accent)
                        Text("Yükleniyor...").font(.caption).foregroundStyle(.secondary)
                    }
                } else if collections.isEmpty {
                    emptyState
                } else {
                    collectionGrid
                }
            }
            .navigationTitle("Koleksiyonlar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreate = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreate, onDismiss: { Task { await load() } }) {
                CreateCollectionSheet(existingHistory: history)
            }
            .sheet(item: $selectedCollection) { col in
                CollectionDetailView(collection: col, allHistory: history)
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
            icon: "rectangle.stack.fill",
            title: "Koleksiyon Yok",
            subtitle: "Galerindeki videoları düzenlemek için koleksiyonlar oluştur",
            action: { showCreate = true },
            actionLabel: "Koleksiyon Oluştur"
        )
    }

    // MARK: - Grid

    private var collectionGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(collections) { col in
                    CollectionCard(
                        collection: col,
                        items: history.filter { col.itemIds.contains($0.id) }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { selectedCollection = col }
                    .contextMenu {
                        Button(role: .destructive) { deleteCollection(col) } label: {
                            Label("Sil", systemImage: "trash")
                        }
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
            async let cols = loadCollections()
            async let hist = APIService.shared.getDownloadHistory()
            collections = try await cols
            history = try await hist
        } catch APIError.unauthorized {
            authState.logout()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loadCollections() async throws -> [MediaCollection] {
        guard let data = UserDefaults.standard.data(forKey: "rv_collections") else { return [] }
        return (try? JSONDecoder().decode([MediaCollection].self, from: data)) ?? []
    }

    private func saveCollections() {
        UserDefaults.standard.set(try? JSONEncoder().encode(collections), forKey: "rv_collections")
    }

    private func deleteCollection(_ col: MediaCollection) {
        collections.removeAll { $0.id == col.id }
        saveCollections()
    }
}

// MARK: - Collection Card

struct CollectionCard: View {
    let collection: MediaCollection
    let items: [DownloadHistoryItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .aspectRatio(16/9, contentMode: .fit)

                if let urlStr = items.first?.thumbnailUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { img in img.resizable().scaledToFill() }
                        placeholder: { Color(.systemGray5) }
                        .aspectRatio(16/9, contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "photo.stack.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                }

                VStack {
                    HStack {
                        Spacer()
                        Text("\(collection.itemIds.count)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.55), in: Capsule())
                            .padding(8)
                    }
                    Spacer()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(collection.name)
                .font(.caption.bold())
                .lineLimit(1)
                .padding(.horizontal, 4)
        }
        .padding(10)
        .glassCard(radius: 16)
    }
}

// MARK: - Collection Detail

struct CollectionDetailView: View {
    let collection: MediaCollection
    let allHistory: [DownloadHistoryItem]
    @Environment(\.dismiss) private var dismiss

    var items: [DownloadHistoryItem] {
        allHistory.filter { collection.itemIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    EmptyStateView(
                        icon: "photo.stack",
                        title: "Bu koleksiyon boş",
                        subtitle: "Galeri'den video ekleyebilirsin"
                    )
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 2
                        ) {
                            ForEach(items) { item in
                                Group {
                                    if let urlStr = item.thumbnailUrl, let url = URL(string: urlStr) {
                                        AsyncImage(url: url) { img in img.resizable().scaledToFill() }
                                            placeholder: { Color(.systemGray5) }
                                    } else {
                                        Color(.systemGray5)
                                            .overlay(Image(systemName: "video.fill").foregroundStyle(.secondary))
                                    }
                                }
                                .aspectRatio(1, contentMode: .fill)
                                .clipped()
                            }
                        }
                    }
                }
            }
            .navigationTitle(collection.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Create Sheet

struct CreateCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let existingHistory: [DownloadHistoryItem]
    @State private var name = ""
    @State private var selectedIds: Set<String> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Koleksiyon Adı")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            TextField("Örn: En Sevdiklerim", text: $name)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .glassInput()
                        }

                        if !existingHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Video Ekle")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                    if selectedIds.count > 0 {
                                        Text("(\(selectedIds.count) seçili)")
                                            .font(.caption.bold())
                                            .foregroundStyle(Color.brand)
                                    }
                                }
                                .padding(.horizontal, 4)

                                VStack(spacing: 8) {
                                    ForEach(existingHistory.prefix(50)) { item in
                                        Button {
                                            if selectedIds.contains(item.id) { selectedIds.remove(item.id) }
                                            else { selectedIds.insert(item.id) }
                                        } label: {
                                            HStack(spacing: 12) {
                                                if let urlStr = item.thumbnailUrl, let url = URL(string: urlStr) {
                                                    AsyncImage(url: url) { img in img.resizable().scaledToFill() }
                                                        placeholder: { Color(.systemGray5) }
                                                        .frame(width: 56, height: 36)
                                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                                } else {
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(Color(.systemGray5))
                                                        .frame(width: 56, height: 36)
                                                }
                                                Text(item.filename)
                                                    .font(.caption)
                                                    .lineLimit(2)
                                                    .foregroundStyle(.primary)
                                                Spacer()
                                                Image(systemName: selectedIds.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                                    .foregroundStyle(selectedIds.contains(item.id) ? Color.brand : .secondary)
                                            }
                                            .padding(12)
                                            .glassCard(radius: 12)
                                        }
                                        .buttonStyle(.plain)
                                        .animation(.spring(response: 0.2), value: selectedIds.contains(item.id))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Koleksiyon Oluştur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Oluştur") { create() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.brand)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
    }

    private func create() {
        let col = MediaCollection(
            id: UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespaces),
            itemIds: Array(selectedIds),
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        var existing = (try? JSONDecoder().decode(
            [MediaCollection].self,
            from: UserDefaults.standard.data(forKey: "rv_collections") ?? Data()
        )) ?? []
        existing.append(col)
        UserDefaults.standard.set(try? JSONEncoder().encode(existing), forKey: "rv_collections")
        dismiss()
    }
}
