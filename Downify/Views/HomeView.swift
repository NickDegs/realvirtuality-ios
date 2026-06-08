import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authState: AuthState
    @State private var selectedTab = 0
    @State private var showSubscription = false

    var body: some View {
        TabView(selection: $selectedTab) {
            DownloadTab()
                .tabItem { Label("İndir", systemImage: "arrow.down.circle.fill") }
                .tag(0)

            BulkDownloadView()
                .tabItem { Label("Toplu", systemImage: "square.stack.3d.down.right.fill") }
                .tag(1)

            GalleryView()
                .tabItem { Label("Galeri", systemImage: "photo.stack.fill") }
                .tag(2)

            ShortcutView()
                .tabItem { Label("Kestirme", systemImage: "bolt.fill") }
                .tag(3)

            AccountView()
                .tabItem { Label("Hesap", systemImage: "person.circle.fill") }
                .tag(4)
        }
        .tint(.purple)
        .sheet(isPresented: $showSubscription) { SubscriptionView() }
        .onReceive(NotificationCenter.default.publisher(for: .startDownloadFromShare)) { notification in
            if let url = notification.object as? String {
                NotificationCenter.default.post(name: .pendingShareURL, object: url)
                selectedTab = 0
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
}

// MARK: - Notification Names

extension Notification.Name {
    static let pendingShareURL = Notification.Name("pendingShareURL")
}

// MARK: - Download Tab

struct DownloadTab: View {
    @EnvironmentObject var authState: AuthState
    @State private var urlText = ""
    @State private var isDownloading = false
    @State private var downloadTask: DownloadResponse?
    @State private var errorMessage: String?
    @State private var downloadMode: DownloadMode = .single
    @State private var showSettings = false
    @State private var showSubscription = false
    @State private var detectedPlatform: String?

    @AppStorage("removeWatermark") private var removeWatermark = true
    @AppStorage("defaultQuality") private var defaultQuality = "best"
    @AppStorage("audioOnly") private var audioOnly = false
    @AppStorage("usePrivateAccount") private var usePrivateAccount = false

    var isFullTier: Bool { authState.user?.tier == .full }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 0) {
                        urlInputSection
                            .padding(.horizontal)
                            .padding(.top, 8)

                        modeSelector
                            .padding(.top, 16)

                        modeContent
                            .padding(.horizontal)
                            .padding(.top, 12)

                        if downloadMode == .single {
                            platformSupportSection
                                .padding(.horizontal)
                                .padding(.top, 20)
                        }
                    }
                    .padding(.bottom, 32)
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
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showSubscription) { SubscriptionView() }
            .alert("Hata", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Tamam") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onReceive(NotificationCenter.default.publisher(for: .pendingShareURL)) { notification in
                if let url = notification.object as? String {
                    urlText = url
                    downloadMode = .single
                    detectPlatform(url)
                    Task { await startDownload() }
                }
            }
        }
    }

    // MARK: - URL Input Section

    private var urlInputSection: some View {
        VStack(spacing: 12) {
            // URL Field
            HStack(spacing: 10) {
                platformIcon
                    .frame(width: 28)

                TextField("Instagram, TikTok, YouTube...", text: $urlText)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: urlText) { detectPlatform($0) }

                if urlText.isEmpty {
                    Button {
                        if let str = UIPasteboard.general.string {
                            withAnimation { urlText = str }
                            detectPlatform(str)
                        }
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                            .foregroundStyle(.purple)
                    }
                } else {
                    Button {
                        withAnimation {
                            urlText = ""
                            detectedPlatform = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(14)
            .glassInput()

            // Options
            optionsRow

            // Download Button
            Button {
                Task { await startDownload() }
            } label: {
                HStack(spacing: 8) {
                    if isDownloading {
                        ProgressView().tint(.white).scaleEffect(0.85)
                    } else {
                        Image(systemName: "arrow.down.circle.fill").font(.body.bold())
                    }
                    Text(isDownloading ? "İndiriliyor..." : "İndir")
                }
            }
            .buttonStyle(PrimaryButtonStyle(enabled: !urlText.isEmpty && !isDownloading))
            .disabled(urlText.isEmpty || isDownloading)

            // Progress
            if let task = downloadTask {
                DownloadProgressView(taskId: task.taskId) {
                    downloadTask = nil
                    urlText = ""
                    detectedPlatform = nil
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(16)
        .glassCard()
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: downloadTask != nil)
    }

    @ViewBuilder
    private var platformIcon: some View {
        Group {
            if let p = detectedPlatform {
                Image(systemName: platformSFSymbol(p))
                    .foregroundStyle(platformColor(p))
                    .font(.title3)
                    .transition(.scale.combined(with: .opacity))
                    .id(p)
            } else {
                Image(systemName: "link")
                    .foregroundStyle(.purple)
                    .font(.title3)
            }
        }
        .animation(.spring(response: 0.25), value: detectedPlatform)
    }

    // MARK: - Options Row

    private var optionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
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

                privateToggle

                qualityMenu
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private var privateToggle: some View {
        Button {
            if !isFullTier {
                showSubscription = true
            } else {
                withAnimation { usePrivateAccount.toggle() }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: usePrivateAccount && isFullTier ? "lock.fill" : "lock.open")
                    .font(.caption.bold())
                Text("Özel Hesap")
                    .font(.caption.bold())
                if !isFullTier {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.yellow)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(usePrivateAccount && isFullTier ? .white : .secondary)
            .background(.thinMaterial, in: Capsule())
            .background {
                if usePrivateAccount && isFullTier {
                    Color.purple.clipShape(Capsule())
                }
            }
            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.6))
            .shadow(color: Color.purple.opacity(usePrivateAccount && isFullTier ? 0.3 : 0), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: usePrivateAccount)
    }

    private var qualityMenu: some View {
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
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.6))
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
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Mode Content

    @ViewBuilder
    private var modeContent: some View {
        switch downloadMode {
        case .single:     EmptyView()
        case .clip:       ClipView(startAsGif: false)
        case .gif:        ClipView(startAsGif: true)
        case .subtitles:  SubtitleView()
        case .keyMoments: KeyMomentsView()
        }
    }

    // MARK: - Platform Support

    private var platformSupportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Desteklenen Platformlar")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(supportedPlatforms, id: \.name) { p in
                        HStack(spacing: 5) {
                            Image(systemName: p.icon)
                                .font(.caption.bold())
                                .foregroundStyle(p.color)
                            Text(p.name)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(p.color.opacity(0.3), lineWidth: 0.7))
                    }
                    Text("1000+ platform")
                        .font(.caption.bold())
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(Color.purple.opacity(0.25), lineWidth: 0.7))
                }
            }
        }
    }

    // MARK: - Platform Data

    private struct PlatformInfo {
        let name: String; let icon: String; let color: Color
    }

    private let supportedPlatforms: [PlatformInfo] = [
        .init(name: "Instagram",  icon: "camera.fill",          color: .pink),
        .init(name: "TikTok",     icon: "music.note",           color: .primary),
        .init(name: "YouTube",    icon: "play.rectangle.fill",  color: .red),
        .init(name: "Twitter/X",  icon: "bird.fill",            color: .blue),
        .init(name: "Facebook",   icon: "f.circle.fill",        color: Color(red: 0.2, green: 0.4, blue: 0.8)),
        .init(name: "Reddit",     icon: "arrow.up.circle.fill", color: .orange),
        .init(name: "Twitch",     icon: "tv.fill",              color: .purple),
        .init(name: "Vimeo",      icon: "play.circle.fill",     color: Color(red: 0.1, green: 0.6, blue: 0.8)),
    ]

    private func platformSFSymbol(_ platform: String) -> String {
        supportedPlatforms.first { $0.name.lowercased().contains(platform.lowercased()) }?.icon ?? "link"
    }

    private func platformColor(_ platform: String) -> Color {
        supportedPlatforms.first { $0.name.lowercased().contains(platform.lowercased()) }?.color ?? .purple
    }

    private func detectPlatform(_ url: String) {
        let lower = url.lowercased()
        let detected: String?
        if lower.contains("instagram.com")                  { detected = "Instagram" }
        else if lower.contains("tiktok.com")                { detected = "TikTok" }
        else if lower.contains("youtu")                     { detected = "YouTube" }
        else if lower.contains("twitter.com") || lower.contains("x.com") { detected = "Twitter/X" }
        else if lower.contains("facebook.com")              { detected = "Facebook" }
        else if lower.contains("reddit.com")                { detected = "Reddit" }
        else if lower.contains("twitch.tv")                 { detected = "Twitch" }
        else if lower.contains("vimeo.com")                 { detected = "Vimeo" }
        else if url.isEmpty                                  { detected = nil }
        else                                                 { detected = nil }
        withAnimation(.easeInOut(duration: 0.2)) { detectedPlatform = detected }
    }

    // MARK: - Action

    private func startDownload() async {
        guard !urlText.isEmpty else { return }
        isDownloading = true
        errorMessage = nil
        do {
            downloadTask = try await APIService.shared.startDownload(
                url: urlText,
                quality: defaultQuality == "best" ? nil : defaultQuality,
                audioOnly: audioOnly,
                noWatermark: removeWatermark,
                usePrivateSession: usePrivateAccount && isFullTier
            )
        } catch APIError.unauthorized {
            authState.logout()
        } catch {
            errorMessage = error.localizedDescription
        }
        isDownloading = false
    }
}
