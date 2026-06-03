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
            VStack(spacing: 20) {
                header
                urlSection

                if !tracks.isEmpty {
                    trackSelection
                    embedToggle
                    downloadButton
                } else if isFetching {
                    HStack {
                        ProgressView()
                        Text("Altyazılar aranıyor...")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if !urlText.isEmpty {
                    fetchButton
                }

                if let task = downloadTask {
                    DownloadProgressView(taskId: task.taskId) {
                        downloadTask = nil
                    }
                }
            }
            .padding()
        }
        .alert("Hata", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) { Button("Tamam") { errorMessage = nil } }
        message: { Text(errorMessage ?? "") }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Image(systemName: "captions.bubble.fill")
                .font(.system(size: 32))
                .foregroundColor(.purple)
            VStack(alignment: .leading, spacing: 2) {
                Text("Altyazı İndirme").font(.title3.bold())
                Text("Video ile birlikte altyazı dosyasını al")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var urlSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Video URL'si").font(.headline)
            HStack {
                TextField("YouTube, TikTok, Instagram...", text: $urlText)
                    .textFieldStyle(.plain)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: urlText) { _ in tracks = [] }
                Button {
                    urlText = UIPasteboard.general.string ?? ""
                } label: {
                    Image(systemName: "doc.on.clipboard")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)

            if tracks.isEmpty && !urlText.isEmpty {
                Button { Task { await fetchTracks() } } label: {
                    Label("Altyazıları Getir", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
    }

    private var fetchButton: some View {
        EmptyView()
    }

    private var trackSelection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(tracks.count) altyazı dili bulundu")
                .font(.subheadline.bold())
            ForEach(tracks) { track in
                Button {
                    selectedLanguage = track.language
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.languageName).font(.subheadline)
                            Text("\(track.language.uppercased()) • \(track.format.uppercased())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selectedLanguage == track.language {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.purple)
                        }
                    }
                    .padding()
                    .background(selectedLanguage == track.language ?
                        Color.purple.opacity(0.1) : Color(.systemGray6))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var embedToggle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $embedInVideo) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Videoya Göm")
                    Text(embedInVideo ?
                        "Altyazı videoyla birleştirilir (tek dosya)" :
                        "Ayrı .srt dosyası olarak indirilir")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var downloadButton: some View {
        Button {
            Task { await startDownload() }
        } label: {
            HStack {
                if isDownloading { ProgressView().tint(.white) }
                else { Image(systemName: "captions.bubble.fill") }
                Text(isDownloading ? "İndiriliyor..." : embedInVideo ? "Video + Altyazı İndir" : "Altyazı Dosyası İndir")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedLanguage.isEmpty || isDownloading ? Color.gray : Color.purple)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(selectedLanguage.isEmpty || isDownloading)
    }

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
