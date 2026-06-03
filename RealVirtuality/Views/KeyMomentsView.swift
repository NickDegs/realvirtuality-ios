import SwiftUI

struct KeyMomentsView: View {
    @EnvironmentObject var authState: AuthState
    @State private var urlText = ""
    @State private var isFetching = false
    @State private var videoInfo: VideoInfo?
    @State private var selectedIds: Set<String> = []
    @State private var isDownloading = false
    @State private var done = false
    @State private var taskCount = 0
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            if done {
                doneView
            } else if let info = videoInfo {
                momentsView(info)
            } else {
                inputView
            }
        }
        .alert("Hata", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) { Button("Tamam") { errorMessage = nil } }
        message: { Text(errorMessage ?? "") }
    }

    // MARK: - Input

    private var inputView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundStyle(LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom))
                    Text("Önemli Anlar")
                        .font(.title2.bold())
                    Text("Video chapter'larını veya yapay zeka ile tespit edilen önemli sahneleri listele, istediğin kısımları indir")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Video URL'si")
                        .font(.headline)
                    TextField("YouTube, TikTok, Instagram...", text: $urlText)
                        .textFieldStyle(.plain)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }

                Button {
                    Task { await fetchInfo() }
                } label: {
                    HStack {
                        if isFetching { ProgressView().tint(.white) }
                        else { Image(systemName: "sparkles") }
                        Text(isFetching ? "Analiz ediliyor..." : "Önemli Anları Bul")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(urlText.isEmpty ? Color.gray : Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(urlText.isEmpty || isFetching)

                infoCard
            }
            .padding()
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Nasıl Çalışır?", systemImage: "info.circle")
                .font(.subheadline.bold())
            VStack(alignment: .leading, spacing: 8) {
                bulletRow(icon: "1.circle.fill", text: "Videonun chapter (bölüm) bilgileri otomatik getirilir")
                bulletRow(icon: "2.circle.fill", text: "Bölüm yoksa yapay zeka sahne değişimlerini tespit eder")
                bulletRow(icon: "3.circle.fill", text: "İstediğin anları seç, ayrı ayrı klip olarak indir")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func bulletRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).foregroundColor(.purple).font(.caption)
            Text(text).font(.caption).foregroundColor(.secondary)
        }
    }

    // MARK: - Moments List

    private func momentsView(_ info: VideoInfo) -> some View {
        VStack(spacing: 0) {
            // Video header
            HStack(spacing: 12) {
                if let thumb = info.thumbnailUrl, let url = URL(string: thumb) {
                    AsyncImage(url: url) { img in img.resizable().scaledToFill() }
                        placeholder: { Color(.systemGray5) }
                        .frame(width: 80, height: 50)
                        .cornerRadius(8)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(info.title).font(.subheadline.bold()).lineLimit(2)
                    HStack {
                        if info.hasAiChapters {
                            Label("AI Tespiti", systemImage: "sparkles")
                                .font(.caption2)
                                .foregroundColor(.purple)
                        } else {
                            Label("Orijinal Bölümler", systemImage: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        Text("• \(formatDuration(info.duration))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))

            // Selection bar
            HStack {
                Text("\(info.chapters.count) bölüm")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(selectedIds.count == info.chapters.count ? "Seçimi Kaldır" : "Tümünü Seç") {
                    if selectedIds.count == info.chapters.count {
                        selectedIds.removeAll()
                    } else {
                        selectedIds = Set(info.chapters.map(\.id))
                    }
                }
                .font(.caption.bold())
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            List(info.chapters) { chapter in
                ChapterRow(
                    chapter: chapter,
                    isSelected: selectedIds.contains(chapter.id)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedIds.contains(chapter.id) { selectedIds.remove(chapter.id) }
                    else { selectedIds.insert(chapter.id) }
                }
            }
            .listStyle(.plain)

            // Download bar
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    Button {
                        videoInfo = nil
                        selectedIds = []
                        urlText = ""
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }

                    Button {
                        Task { await downloadChapters() }
                    } label: {
                        HStack {
                            if isDownloading { ProgressView().tint(.white) }
                            else { Image(systemName: "arrow.down.circle.fill") }
                            Text(isDownloading ? "İndiriliyor..." : "\(selectedIds.count) Bölümü İndir")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedIds.isEmpty ? Color.gray : Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(selectedIds.isEmpty || isDownloading)
                }
                .padding()
            }
        }
    }

    // MARK: - Done

    private var doneView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.green)
            Text("\(taskCount) bölüm indirmeye başladı!")
                .font(.title2.bold())
            Text("Klip olarak kaydediliyor.\nGaleride görünecekler.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button { done = false; videoInfo = nil; urlText = "" } label: {
                Text("Yeni Video")
                    .foregroundColor(.purple)
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - Actions

    private func fetchInfo() async {
        isFetching = true
        errorMessage = nil
        do {
            videoInfo = try await APIService.shared.getVideoInfo(url: urlText)
            selectedIds = Set(videoInfo?.chapters.map(\.id) ?? [])
        } catch {
            errorMessage = error.localizedDescription
        }
        isFetching = false
    }

    private func downloadChapters() async {
        guard let info = videoInfo else { return }
        isDownloading = true
        do {
            let response = try await APIService.shared.startChapterDownload(
                url: urlText,
                chapterIds: Array(selectedIds)
            )
            taskCount = response.taskIds.count
            done = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isDownloading = false
    }

    private func formatDuration(_ seconds: Double) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }
}

struct ChapterRow: View {
    let chapter: VideoChapter
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .purple : .secondary)
                .font(.title3)

            if let thumb = chapter.thumbnailUrl, let url = URL(string: thumb) {
                AsyncImage(url: url) { img in img.resizable().scaledToFill() }
                    placeholder: { Color(.systemGray5) }
                    .frame(width: 70, height: 44)
                    .cornerRadius(6)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(width: 70, height: 44)
                    .overlay(
                        Text(formatTime(chapter.startTime))
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(chapter.title)
                    .font(.subheadline)
                    .lineLimit(2)
                Text("\(formatTime(chapter.startTime)) → \(formatTime(chapter.endTime)) • \(formatDuration(chapter.endTime - chapter.startTime))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ s: Double) -> String {
        let h = Int(s) / 3600
        let m = (Int(s) % 3600) / 60
        let sec = Int(s) % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%d:%02d", m, sec)
    }

    private func formatDuration(_ s: Double) -> String {
        if s < 60 { return "\(Int(s))s" }
        return "\(Int(s/60))dk"
    }
}
