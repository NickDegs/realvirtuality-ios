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
                    ProgressView("Yükleniyor...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "rectangle.stack.fill")
                .font(.system(size: 64))
                .foregroundStyle(LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom))
            Text("Koleksiyon Yok")
                .font(.title2.bold())
            Text("Galerindeki videoları düzenlemek için koleksiyonlar oluştur")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button { showCreate = true } label: {
                Label("Koleksiyon Oluştur", systemImage: "plus")
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
                        Button(role: .destructive) {
                            deleteCollection(col)
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
        .refreshable { await load() }
    }

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
        let stored = UserDefaults.standard.data(forKey: "rv_collections")
        guard let data = stored else { return [] }
        return (try? JSONDecoder().decode([MediaCollection].self, from: data)) ?? []
    }

    private func saveCollections() {
        let data = try? JSONEncoder().encode(collections)
        UserDefaults.standard.set(data, forKey: "rv_collections")
    }

    private func deleteCollection(_ col: MediaCollection) {
        collections.removeAll { $0.id == col.id }
        saveCollections()
    }
}

struct CollectionCard: View {
    let collection: MediaCollection
    let items: [DownloadHistoryItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if items.isEmpty {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5))
                        .aspectRatio(16/9, contentMode: .fit)
                    Image(systemName: "photo.stack.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                } else {
                    thumbnailGrid
                }
            }
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(collection.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text("\(collection.itemIds.count) video")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var thumbnailGrid: some View {
        let thumb = items.first?.thumbnailUrl
        return Group {
            if let urlStr = thumb, let url = URL(string: urlStr) {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Color(.systemGray5)
                }
                .aspectRatio(16/9, contentMode: .fill)
                .clipped()
            } else {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color(.systemGray4))
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        Image(systemName: "photo.stack.fill")
                            .foregroundColor(.secondary)
                    )
            }
        }
    }
}

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
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "photo.stack")
                            .font(.system(size: 56))
                            .foregroundColor(.secondary)
                        Text("Bu koleksiyon boş")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
                            ForEach(items) { item in
                                Group {
                                    if let urlStr = item.thumbnailUrl, let url = URL(string: urlStr) {
                                        AsyncImage(url: url) { img in
                                            img.resizable().scaledToFill()
                                        } placeholder: {
                                            Color(.systemGray5)
                                        }
                                    } else {
                                        Color(.systemGray5)
                                            .overlay(Image(systemName: "video.fill").foregroundColor(.secondary))
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

struct CreateCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let existingHistory: [DownloadHistoryItem]
    @State private var name = ""
    @State private var selectedIds: Set<String> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Koleksiyon Adı") {
                    TextField("Örn: En Sevdiklerim", text: $name)
                }

                if !existingHistory.isEmpty {
                    Section("Video Ekle (\(selectedIds.count) seçili)") {
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
                                            .cornerRadius(6)
                                    } else {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(.systemGray5))
                                            .frame(width: 56, height: 36)
                                    }
                                    Text(item.filename)
                                        .font(.subheadline)
                                        .lineLimit(2)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedIds.contains(item.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.purple)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
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
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.semibold)
                }
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
