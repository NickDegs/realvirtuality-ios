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
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        modeSelector
                        modeContent
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Downify")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.purple)
                            .padding(8)
                            .glassInput(radius: 10)
                    }
                }
            }
        }
    }

    // MARK: - Mode Selector

    private var modeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DownloadMode.allCases) { mode in
                    GlassPill(
                        mode.rawValue,
                        icon: mode.icon,
                        isSelected: downloadMode == mode
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            downloadMode = mode
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Mode Content

    @ViewBuilder
    private var modeContent: some View {
        switch downloadMode {
        case .single:    singleDownloadSection
        case .clip:      ClipView()
        case .gif:       ClipView()
        case .subtitles: SubtitleView()
        case .keyMoments: KeyMomentsView()
        }
    }

    // MARK: - Single Download

    private var singleDownloadSection: some View {
        VStack(spacing: 16) {
            urlInputCard
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

    private var urlInputCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "link")
                    .foregroundStyle(.purple)
                    .frame(width: 20)

                TextField("Instagram, TikTok, YouTube...", text: $urlText)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                if !urlText.isEmpty {
                    Button {
                        withAnimation { urlText = "" }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button {
                        urlText = UIPasteboard.general.string ?? ""
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                            .foregroundStyle(.purple)
                    }
                }
            }
            .padding(14)
            .glassInput()

            Button {
                Task { await startDownload() }
            } label: {
                HStack(spacing: 8) {
                    if isDownloading {
                        ProgressView().tint(.white).scaleEffect(0.85)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.body.bold())
                    }
                    Text(isDownloading ? "İndiriliyor..." : "İndir")
                }
            }
            .buttonStyle(PrimaryButtonStyle(enabled: !urlText.isEmpty && !isDownloading))
            .disabled(urlText.isEmpty || isDownloading)
        }
        .padding(16)
        .glassCard()
    }

    private var optionsBar: some View {
        HStack(spacing: 8) {
            GlassPill("Watermark'sız",
                      icon: removeWatermark ? "checkmark.seal.fill" : "seal",
                      isSelected: removeWatermark) {
                removeWatermark.toggle()
            }

            GlassPill(audioOnly ? "MP3" : "Video",
                      icon: audioOnly ? "music.note" : "video",
                      isSelected: audioOnly) {
                audioOnly.toggle()
            }

            Spacer()

            Menu {
                ForEach(["best", "1080", "720", "480"], id: \.self) { q in
                    Button(q == "best" ? "En İyi" : "\(q)p") { defaultQuality = q }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "slider.horizontal.3")
                    Text(defaultQuality == "best" ? "En İyi" : "\(defaultQuality)p")
                }
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.thinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.6))
            }
        }
    }

    private var platformChips: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Desteklenen Platformlar")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["Instagram", "TikTok", "YouTube", "Twitter/X",
                             "Facebook", "Reddit", "Twitch", "Vimeo",
                             "Pinterest", "1000+"], id: \.self) { platform in
                        Text(platform)
                            .font(.caption.bold())
                            .foregroundStyle(.purple)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(.thinMaterial, in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.purple.opacity(0.25), lineWidth: 0.7)
                            )
                    }
                }
            }
        }
    }

    // MARK: - More Tab

    private var moreTab: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                List {
                    NavigationLink {
                        AutoDownloadView()
                    } label: {
                        Label("Otomatik İndirme", systemImage: "clock.arrow.2.circlepath")
                            .foregroundStyle(.primary)
                    }
                    NavigationLink {
                        ScheduledDownloadView()
                    } label: {
                        Label("Planlı İndirmeler", systemImage: "calendar.badge.clock")
                            .foregroundStyle(.primary)
                    }
                    NavigationLink {
                        CollectionView()
                    } label: {
                        Label("Koleksiyonlar", systemImage: "rectangle.stack.fill")
                            .foregroundStyle(.primary)
                    }
                }
                .scrollContentBackground(.hidden)
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
