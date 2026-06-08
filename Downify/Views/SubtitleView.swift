import SwiftUI

struct SubtitleView: View {
    @EnvironmentObject var authState: AuthState
    @State private var urlText = ""
    @State private var isFetching = false
    @State private var tracks: [SubtitleTrack] = []
    @State private var selectedLanguage = ""
    @State private var embedInVideo = true
    @State private var isDownloading = false
    @State private var downloadTask: DownloadResponse?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                urlSection
                if isFetching {
                    fetchingIndicator
                } else if !tracks.isEmpty {
                    trackSelection
                    embedToggle
                    downloadButton
                }
                if let task = downloadTask {
                    DownloadProgressView(taskId: task.taskId) { downloadTask = nil }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .alert("Hata", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) { Button("Tamam") { errorMessage = nil } }
        message: { Text(errorMessage ?? "") }
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.brand.opacity(0.14))
                    .frame(width: 52, height: 52)
                Image(systemName: "captions.bubble.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.brand)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Altyazı İndirme").font(.headline)
                Text("Video ile birlikte altyazı dosyasını al")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - URL

    private var urlSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Video URL'si")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            HStack(spacing: 10) {
                TextField("YouTube, TikTok, Instagram...", text: $urlText)
                    .textFieldStyle(.plain)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: urlText) { _ in tracks = [] }
                Button {
                    urlText = UIPasteboard.general.string ?? ""
                } label: {
                    Image(systemName: "doc.on.clipboard").foregroundStyle(.purple)
                }
            }
            .padding(14)
            .glassInput()

            if tracks.isEmpty && !urlText.isEmpty && !isFetching {
                Button {
                    Task { await fetchTracks() }
                } label: {
                    Label("Altyazıları Getir", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    // MARK: - Fetching

    private var fetchingIndicator: some View {
        HStack(spacing: 10) {
            ProgressView().tint(.purple)
            Text("Altyazılar aranıyor...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .glassCard()
    }

    // MARK: - Track Selection

    private var trackSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(tracks.count) altyazı dili bulundu")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(tracks) { track in
                    Button {
                        selectedLanguage = track.language
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .stroke(selectedLanguage == track.language ? Color.brand : Color.white.opacity(0.3), lineWidth: 1.5)
                                    .frame(width: 20, height: 20)
                                if selectedLanguage == track.language {
                                    Circle()
                                        .fill(Color.brand)
                                        .frame(width: 10, height: 10)
                                }
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.languageName).font(.subheadline.bold())
                                Text("\(track.language.uppercased()) • \(track.format.uppercased())")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedLanguage == track.language {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.brand)
                            }
                        }
                        .padding(14)
                        .background(
                            selectedLanguage == track.language ? Color.brand.opacity(0.1) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .glassCard(radius: 12)
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.2), value: selectedLanguage)
                }
            }
        }
    }

    // MARK: - Embed Toggle

    private var embedToggle: some View {
        Toggle(isOn: $embedInVideo) {
            HStack(spacing: 10) {
                Image(systemName: embedInVideo ? "film.fill" : "doc.text.fill")
                    .foregroundStyle(embedInVideo ? Color.brand : .secondary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Videoya Göm").font(.subheadline.bold())
                    Text(embedInVideo ?
                         "Altyazı videoyla birleştirilir (tek dosya)" :
                         "Ayrı .srt dosyası olarak indirilir")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Download

    private var downloadButton: some View {
        Button {
            Task { await startDownload() }
        } label: {
            LoadingLabel(
                isLoading: isDownloading,
                icon: "captions.bubble.fill",
                loadingText: "İndiriliyor...",
                idleText: embedInVideo ? "Video + Altyazı İndir" : "Altyazı Dosyası İndir"
            )
        }
        .buttonStyle(PrimaryButtonStyle(enabled: !selectedLanguage.isEmpty && !isDownloading))
        .disabled(selectedLanguage.isEmpty || isDownloading)
    }

    // MARK: - Actions

    private func fetchTracks() async {
        isFetching = true
        do {
            tracks = try await APIService.shared.getSubtitleTracks(url: urlText)
            if let first = tracks.first { selectedLanguage = first.language }
        } catch {
            errorMessage = error.localizedDescription
        }
        isFetching = false
    }

    private func startDownload() async {
        isDownloading = true
        do {
            downloadTask = try await APIService.shared.startSubtitleDownload(
                url: urlText,
                language: selectedLanguage,
                embed: embedInVideo
            )
        } catch APIError.unauthorized {
            authState.logout()
        } catch {
            errorMessage = error.localizedDescription
        }
        isDownloading = false
    }
}
