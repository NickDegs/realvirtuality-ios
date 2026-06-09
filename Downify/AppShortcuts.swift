import AppIntents

enum IntentError: Error, LocalizedError {
    case notFound
    case invalidURL
    var errorDescription: String? {
        switch self {
        case .notFound:    return "Bulunamadı"
        case .invalidURL:  return "Geçersiz URL"
        }
    }
}

// MARK: - Download Video Intent (iOS 16+)

@available(iOS 16.0, *)
struct DownloadVideoIntent: AppIntent {
    static var title: LocalizedStringResource = "Video İndir"
    static var description = IntentDescription(
        "Bir sosyal medya videosunu Downify ile indir",
        categoryName: "İndirme"
    )

    @Parameter(title: "Video URL", description: "İndirilecek videonun bağlantısı")
    var url: String

    @Parameter(title: "Kalite", description: "İndirme kalitesi", default: "best")
    var quality: String

    @Parameter(title: "Sadece Ses (MP3)", description: "Yalnızca sesi indir", default: false)
    var audioOnly: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Downify ile \(\.$url) indir") {
            \.$quality
            \.$audioOnly
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard !url.isEmpty, url.hasPrefix("http") else {
            throw IntentError.notFound
        }

        let result = try await APIService.shared.startDownload(
            url: url,
            quality: quality == "best" ? nil : quality,
            audioOnly: audioOnly,
            noWatermark: true
        )
        return .result(value: "İndirme başlatıldı: \(result.taskId)")
    }
}

// MARK: - App Shortcuts Provider

@available(iOS 16.0, *)
struct DownifyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: DownloadVideoIntent(),
            phrases: [
                "Downify ile indir",
                "\(\.$url) Downify ile indir",
                "Bu videoyu Downify'a gönder"
            ],
            shortTitle: "Video İndir",
            systemImageName: "arrow.down.circle.fill"
        )
    }

    static var shortcutTileColor: ShortcutTileColor { .purple }
}

// MARK: - Check Download Status Intent

@available(iOS 16.0, *)
struct CheckDownloadIntent: AppIntent {
    static var title: LocalizedStringResource = "İndirme Durumunu Gör"
    static var description = IntentDescription("Devam eden Downify indirmelerini göster")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        return .result(value: "Downify'ı açarak galeriyi kontrol et")
    }
}
