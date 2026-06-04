import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authState: AuthState
    @State private var urlText = ""
    @State private var isDownloading = false
    @State private var downloadTask: DownloadResponse?
    @State private var showSubscription = false
    @State private var showSettings = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    @State private var downloadMode: DownloadMode = .single

    @AppStorage("removeWatermark") private var removeWatermark = true
    @AppStorage("defaultQuality") private var defaultQuality = "best"
    @AppStorage("audioOnly") private var audioOnly = false

    var body: some View {
        TabView(selection: $selectedTab) {
            downloadTab
                .tabItem { Label("İndir", systemImage: "arrow.down.circle.fill") }
                .tag(0)

            BulkDownloadView()
                .tabItem { Label("Toplu", systemImage: "square.stack.3d.down.right.fill") }
                .tag(1)

            GalleryView()
                .tabItem { Label("Galeri", systemImage: "photo.stack.fill") }
                .tag(2)

            moreTab
                .tabItem { Label("Daha Fazla", systemImage: "ellipsis.circle.fill") }
                .tag(3)

            AccountView()
                .tabItem { Label("Hesap", systemImage: "person.circle.fill") }
                .tag(4)
        }
        .tint(.purple)
        .sheet(isPresented: $showSubscription) { SubscriptionView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .onReceive(NotificationCenter.default.publisher(for: .startDownloadFromShare)) { notification in
            if let url = notification.object as? String {
                urlText = url
                downloadMode = .single
                selectedTab = 0
                Task { await startDownload() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showSubscription)) { _ in
            showSubscription = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .paymentResult)) { notification in
            if let success = notification.object as? Bool, success {
                Task { await authState.refreshUser() }
            }
        }
    }

    // MARK: - Download Tab

    private var downloadTab: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    modeSelector
                    modeContent
                }
                .padding()
            }
            .navigationTitle("Mediafy")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }

    // MARK: - Mode Selector

    private var modeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(DownloadMode.allCases) { mode in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            downloadMode = mode
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.caption.bold())
                            Text(mode.rawValue)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(downloadMode == mode ? Color.purple : Color(.systemGray6))
                        .foregroundColor(downloadMode == mode ? .white : .secondary)
                        .cornerRadius(20)
                    }
                }
            }
        }
    }

    // MARK: - Mode Content

    @ViewBuilder
    private var modeContent: some View {
        switch downloadMode {
        case .single:
            singleDownloadSection
        case .clip:
            ClipView()
        case .gif:
            ClipView()
        case .subtitles:
            SubtitleView()
        case .keyMoments:
            KeyMomentsView()
        }
    }

    // MARK: - Single Download

    private var singleDownloadSection: some View {
        VStack(spacing: 20) {
            urlInputSection
            optionsBar
            if let task = downloadTask {
                DownloadProgressView(taskId: task.taskId) {
                    downloadTask = nil
                    urlText = ""
                }
            }
            platformChips
        }
        .alert("Hata", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("Tamam") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var urlInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Medya URL'si")
                .font(.headline)

            HStack(spacing: 8) {
                TextField("Instagram, TikTok, YouTube...", text: $urlText)
                    .textFieldStyle(.plain)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                Button {
                    urlText = UIPasteboard.general.string ?? ""
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
            }

            Button {
                Task { await startDownload() }
            } label: {
                HStack {
                    if isDownloading {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                    }
                    Text(isDownloading ? "İndiriliyor..." : "İndir")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(urlText.isEmpty ? Color.gray : Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(urlText.isEmpty || isDownloading)
        }
    }

    private var optionsBar: some View {
        HStack(spacing: 12) {
            Button { removeWatermark.toggle() } label: {
                HStack(spacing: 4) {
                    Image(systemName: removeWatermark ? "checkmark.seal.fill" : "seal")
                        .foregroundColor(removeWatermark ? .purple : .secondary)
                    Text("Watermark'sız")
                        .font(.caption.bold())
                        .foregroundColor(removeWatermark ? .purple : .secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(removeWatermark ? Color.purple.opacity(0.1) : Color(.systemGray6))
                .cornerRadius(8)
            }

            Button { audioOnly.toggle() } label: {
                HStack(spacing: 4) {
                    Image(systemName: audioOnly ? "music.note" : "video")
                        .foregroundColor(audioOnly ? .purple : .secondary)
                    Text(audioOnly ? "MP3" : "Video")
                        .font(.caption.bold())
                        .foregroundColor(audioOnly ? .purple : .secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(audioOnly ? Color.purple.opacity(0.1) : Color(.systemGray6))
                .cornerRadius(8)
            }

            Spacer()

            Menu {
                ForEach(["best", "1080", "720", "480"], id: \.self) { q in
                    Button(q == "best" ? "En İyi" : "\(q)p") { defaultQuality = q }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "slider.horizontal.3")
                    Text(defaultQuality == "best" ? "En İyi" : "\(defaultQuality)p")
                }
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }

    private var platformChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Desteklenen Platformlar")
                .font(.caption)
                .foregroundColor(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["Instagram", "TikTok", "YouTube", "Twitter/X", "Facebook",
                             "Reddit", "Twitch", "Vimeo", "Pinterest", "1000+"], id: \.self) { platform in
                        Text(platform)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }

    // MARK: - More Tab

    private var moreTab: some View {
        NavigationStack {
            List {
                NavigationLink {
                    AutoDownloadView()
                } label: {
                    Label("Otomatik İndirme", systemImage: "clock.arrow.2.circlepath")
                }
                NavigationLink {
                    ScheduledDownloadView()
                } label: {
                    Label("Planlı İndirmeler", systemImage: "calendar.badge.clock")
                }
                NavigationLink {
                    CollectionView()
                } label: {
                    Label("Koleksiyonlar", systemImage: "rectangle.stack.fill")
                }
            }
            .navigationTitle("Daha Fazla")
        }
    }

    // MARK: - Actions

    private func startDownload() async {
        guard !urlText.isEmpty else { return }
        isDownloading = true
        errorMessage = nil
        do {
            downloadTask = try await APIService.shared.startDownload(
                url: urlText,
                quality: defaultQuality == "best" ? nil : defaultQuality,
                audioOnly: audioOnly,
                noWatermark: removeWatermark
            )
        } catch APIError.unauthorized {
            authState.logout()
        } catch {
            errorMessage = error.localizedDescription
        }
        isDownloading = false
    }
}
