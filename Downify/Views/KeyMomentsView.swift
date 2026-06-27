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
            if done { doneView }
            else if let info = videoInfo { momentsView(info) }
            else { inputView }
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
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40)).foregroundStyle(Theme.accent)
                    Text("Önemli Anlar").font(.title2.bold())
                    Text("Video bölümlerini veya AI ile tespit edilen sahneleri indir")
                        .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                HStack(spacing: 10) {
                    TextField("TikTok, YouTube, X…", text: $urlText)
                        .keyboardType(.URL).autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button {
                        urlText = UIPasteboard.general.string ?? ""
                    } label: {
                        Image(systemName: "doc.on.clipboard").foregroundStyle(Theme.accent)
                    }
                }
                .padding(14).glassInput()

                Button {
                    Task { await fetchInfo() }
                } label: {
                    HStack {
                        Spacer()
                        LoadingLabel(isLoading: isFetching, icon: "sparkles",
                                     loadingText: "Analiz ediliyor...", idleText: "Önemli Anları Bul")
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Theme.accent)
                .disabled(urlText.isEmpty || isFetching)

                VStack(alignment: .leading, spacing: 10) {
                    Label("Nasıl Çalışır?", systemImage: "info.circle").font(.caption.bold()).foregroundStyle(.secondary)
                    Label("Videonun chapter (bölüm) bilgileri otomatik getirilir",
                          systemImage: "1.circle.fill").font(.caption).foregroundStyle(.secondary)
                    Label("Bölüm yoksa AI sahne değişimlerini tespit eder",
                          systemImage: "2.circle.fill").font(.caption).foregroundStyle(.secondary)
                    Label("İstediğin anları seç, ayrı klip olarak indir",
                          systemImage: "3.circle.fill").font(.caption).foregroundStyle(.secondary)
                }
                .padding(16).glassCard()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Moments

    private func momentsView(_ info: VideoInfo) -> some View {
        VStack(spacing: 0) {
            videoHeader(info)

            HStack {
                Text("\(info.chapters.count) bölüm").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button(selectedIds.count == info.chapters.count ? "Seçimi Kaldır" : "Tümünü Seç") {
                    if selectedIds.count == info.chapters.count { selectedIds.removeAll() }
                    else { selectedIds = Set(info.chapters.map(\.id)) }
                }
                .font(.caption.bold()).foregroundStyle(Theme.accent)
            }
            .padding(.horizontal).padding(.vertical, 8)

            List(info.chapters) { chapter in
                ChapterRow(chapter: chapter, isSelected: selectedIds.contains(chapter.id))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedIds.contains(chapter.id) { selectedIds.remove(chapter.id) }
                        else { selectedIds.insert(chapter.id) }
                    }
            }
            .listStyle(.plain)

            Divider()
            HStack(spacing: 12) {
                Button {
                    videoInfo = nil; selectedIds = []; urlText = ""
                } label: {
                    Image(systemName: "arrow.uturn.backward").font(.body.bold()).padding(14)
                }
                .frosted(in: RoundedRectangle(cornerRadius: 12))

                Button {
                    Task { await downloadChapters() }
                } label: {
                    HStack {
                        Spacer()
                        LoadingLabel(isLoading: isDownloading, icon: "arrow.down.circle.fill",
                                     loadingText: "İndiriliyor...",
                                     idleText: "\(selectedIds.count) Bölümü İndir")
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Theme.accent)
                .disabled(selectedIds.isEmpty || isDownloading)
            }
            .padding(.horizontal).padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }

    private func videoHeader(_ info: VideoInfo) -> some View {
        HStack(spacing: 12) {
            if let thumb = info.thumbnailUrl, let url = URL(string: thumb) {
                AsyncImage(url: url) { img in img.resizable().scaledToFill() }
                placeholder: { Color(.systemGray5) }
                    .frame(width: 80, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(info.title).font(.subheadline.bold()).lineLimit(2)
                HStack(spacing: 8) {
                    if info.hasAiChapters {
                        Label("AI Tespiti", systemImage: "sparkles").font(.caption2.bold()).foregroundStyle(Theme.accent)
                    } else {
                        Label("Orijinal Bölümler", systemImage: "checkmark.seal.fill")
                            .font(.caption2.bold()).foregroundStyle(.green)
                    }
                    Text("• \(info.durationText)").font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(.regularMaterial)
    }

    // MARK: - Done

    private var doneView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72)).foregroundStyle(.green)
            VStack(spacing: 8) {
                Text("\(taskCount) bölüm indirmeye başladı!").font(.title2.bold())
                Text("Klip olarak kaydediliyor.\nGaleride görünecekler.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            Button("Yeni Video") {
                done = false; videoInfo = nil; urlText = ""
            }
            .buttonStyle(.borderedProminent).tint(Theme.accent)
            Spacer()
        }
        .padding()
    }

    // MARK: - Actions

    private func fetchInfo() async {
        isFetching = true; errorMessage = nil
        do {
            videoInfo = try await APIService.shared.getVideoInfo(url: urlText)
            selectedIds = Set(videoInfo?.chapters.map(\.id) ?? [])
        } catch { errorMessage = error.localizedDescription }
        isFetching = false
    }

    private func downloadChapters() async {
        isDownloading = true
        do {
            let response = try await APIService.shared.startChapterDownload(
                url: urlText, chapterIds: Array(selectedIds))
            taskCount = response.taskIds.count; done = true
        } catch { errorMessage = error.localizedDescription }
        isDownloading = false
    }
}

// MARK: - Chapter Row

struct ChapterRow: View {
    let chapter: VideoChapter
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color.brand : .secondary).font(.title3)
                .animation(.spring(response: 0.2), value: isSelected)

            ZStack {
                RoundedRectangle(cornerRadius: 6).fill(Color(.systemGray5)).frame(width: 70, height: 44)
                if let thumb = chapter.thumbnailUrl, let url = URL(string: thumb) {
                    AsyncImage(url: url) { img in img.resizable().scaledToFill() }
                    placeholder: { Color(.systemGray5) }
                        .frame(width: 70, height: 44).clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Text(formatTime(chapter.startTime)).font(.caption2.bold()).foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(chapter.title).font(.subheadline).lineLimit(2)
                Text("\(formatTime(chapter.startTime)) → \(formatTime(chapter.endTime)) • \(chapter.durationText)")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ s: Double) -> String {
        let h = Int(s) / 3600; let m = (Int(s) % 3600) / 60; let sec = Int(s) % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%d:%02d", m, sec)
    }
}
