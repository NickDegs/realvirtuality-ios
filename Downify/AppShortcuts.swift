import AppIntents
import Foundation
import Photos

enum IntentError: Error, LocalizedError {
    case notFound
    case invalidURL
    case noPermission
    case failed(String)
    var errorDescription: String? {
        switch self {
        case .notFound:        return "Medya bulunamadı"
        case .invalidURL:      return "Geçersiz URL"
        case .noPermission:    return "Galeriye kaydetmek için Fotoğraflar izni gerekli (Ayarlar > Downify)."
        case .failed(let m):   return m
        }
    }
}

// MARK: - Download Video Intent (iOS 16+)
// Kestirmeler uygulamasında OTOMATİK görünür (import/imza yok). Linki bizim sunucu
// (proxy + IG burner) çözer → dosyayı indirir → galeriye kaydeder. Tek dokunuş.

@available(iOS 16.0, *)
struct DownloadVideoIntent: AppIntent {
    static var title: LocalizedStringResource = "Video İndir"
    static var description = IntentDescription(
        "Bir sosyal medya videosunu/medyasını Downify ile indir ve galeriye kaydet",
        categoryName: "İndirme"
    )

    @Parameter(title: "Video URL", description: "İndirilecek medyanın bağlantısı")
    var url: String

    @Parameter(title: "Kalite", description: "best / 1080 / 720 / 480 ...", default: "best")
    var quality: String

    @Parameter(title: "Sadece Ses (MP3)", description: "Yalnızca sesi indir", default: false)
    var audioOnly: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$url) indir") {
            \.$quality
            \.$audioOnly
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard !url.isEmpty, url.hasPrefix("http") else { throw IntentError.invalidURL }

        // 1) İndirmeyi başlat (sunucu: proxy + IG burner ile çözer)
        let start = try await APIService.shared.startDownload(
            url: url,
            quality: (quality == "best" || quality.isEmpty) ? nil : quality,
            audioOnly: audioOnly,
            noWatermark: true
        )
        let taskId = start.taskId

        // 2) Tamamlanana kadar bekle (~120sn)
        // AppIntent süre limiti var → en fazla ~30sn bekle (kısa video/IG biter); uzunsa çökmeden çık.
        var fileURLString: String?
        var filename = ""
        for _ in 0..<12 {
            try await Task.sleep(nanoseconds: 2_500_000_000)
            let st = try? await APIService.shared.getDownloadStatus(taskId: taskId)
            guard let st else { continue }
            if st.status == "completed", let dl = st.downloadUrl, !dl.isEmpty {
                fileURLString = dl; filename = st.filename ?? ""; break
            }
            if st.status == "failed" { return .result(value: "İndirme başarısız: \(st.error ?? "")") }
        }
        guard let fileURLString, let fileURL = URL(string: fileURLString) else {
            return .result(value: "İndirme sürüyor — birazdan galeride/Downify'da olur. Uzun videoda Paylaş→Downify kullan.")
        }

        // 3) Dosyayı indir (auth gerekmez — UUID tahmin edilemez)
        let (tempURL, _) = try await URLSession.shared.download(from: fileURL)
        var ext = (filename as NSString).pathExtension
        if ext.isEmpty { ext = fileURL.pathExtension }
        if ext.isEmpty { ext = audioOnly ? "mp3" : "mp4" }
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("downify-\(UUID().uuidString).\(ext)")
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.moveItem(at: tempURL, to: dest)
        defer { try? FileManager.default.removeItem(at: dest) }

        // 4) Ses Fotoğraflar'a kaydedilemez → ses için Downify uygulamasını kullan.
        let audioExts: Set<String> = ["mp3", "m4a", "aac", "wav", "opus"]
        if audioExts.contains(ext.lowercased()) {
            return .result(value: "Ses indirildi ✓ — ses dosyası için Downify uygulamasını kullan.")
        }

        let auth = await withCheckedContinuation { (c: CheckedContinuation<PHAuthorizationStatus, Never>) in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { c.resume(returning: $0) }
        }
        guard auth == .authorized || auth == .limited else { throw IntentError.noPermission }

        let imageExts: Set<String> = ["jpg", "jpeg", "png", "heic", "heif", "webp", "gif"]
        let resType: PHAssetResourceType = imageExts.contains(ext.lowercased()) ? .photo : .video
        try await PHPhotoLibrary.shared().performChanges {
            let req = PHAssetCreationRequest.forAsset()
            req.addResource(with: resType, fileURL: dest, options: nil)
        }
        return .result(value: "İndirildi ve galeriye kaydedildi ✓")
    }
}

// MARK: - App Shortcuts Provider

@available(iOS 16.0, *)
struct DownifyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: DownloadVideoIntent(),
            phrases: [
                "\(.applicationName) ile indir",
                "\(.applicationName) ile video indir",
                "Bu videoyu \(.applicationName)'a gönder"
            ],
            shortTitle: "Video İndir",
            systemImageName: "arrow.down.circle.fill"
        )
    }

    static var shortcutTileColor: ShortcutTileColor { .purple }
}
