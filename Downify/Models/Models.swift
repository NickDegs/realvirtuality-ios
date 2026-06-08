import Foundation

// MARK: - Subscription

enum SubscriptionTier: String, Codable {
    case free
    case adFree = "ad_free"
    case full

    var displayName: String {
        switch self {
        case .free:   return "Ücretsiz"
        case .adFree: return "Pro"
        case .full:   return "Full"
        }
    }
}

// MARK: - Auth

struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let username: String
    let tier: SubscriptionTier
    let createdAt: Date
}

struct AuthResponse: Codable {
    let accessToken: String
    let tokenType: String
    let user: User
}

// MARK: - Download

struct DownloadResponse: Codable {
    let taskId: String
    let status: String
    let message: String?
}

struct DownloadStatus: Codable {
    let taskId: String
    let status: String
    let progress: Double?
    let downloadUrl: String?
    let filename: String?
    let fileSize: Int?
    let error: String?
}

// MARK: - Bulk

struct BulkDownloadRequest: Codable {
    let url: String
    let limit: Int
}

struct BulkItem: Codable, Identifiable {
    let id: String
    let url: String
    let title: String?
    let thumbnail: String?
    let duration: Int?
}

struct BulkDownloadListResponse: Codable {
    let bulkId: String
    let items: [BulkItem]
    let total: Int
}

struct BulkStartResponse: Codable {
    let taskIds: [String]
}

// MARK: - Clip / GIF

struct ClipRequest: Codable {
    let url: String
    let startTime: Double
    let endTime: Double
    let asGif: Bool
    let fps: Int?
    let quality: String?
}

// MARK: - Subtitles

struct SubtitleTrack: Codable, Identifiable {
    let id: String
    let language: String
    let languageName: String
    let format: String
}

struct SubtitleRequest: Codable {
    let url: String
    let language: String
    let embed: Bool
}

// MARK: - Key Moments

struct VideoChapter: Codable, Identifiable {
    let id: String
    let title: String
    let startTime: Double
    let endTime: Double
    let thumbnailUrl: String?

    var durationText: String {
        let s = Int(endTime - startTime)
        return s >= 60 ? "\(s/60)d \(s%60)s" : "\(s)s"
    }
}

struct VideoInfo: Codable {
    let title: String
    let duration: Double
    let thumbnailUrl: String?
    let platform: String?
    let chapters: [VideoChapter]
    let hasAiChapters: Bool

    var durationText: String {
        let d = Int(duration)
        if d >= 3600 { return "\(d/3600)s \((d%3600)/60)d" }
        if d >= 60   { return "\(d/60)d \(d%60)s" }
        return "\(d)s"
    }
}

// MARK: - Gallery

struct DownloadHistoryItem: Codable, Identifiable {
    let id: String
    let url: String
    let filename: String
    let downloadUrl: String
    let platform: String?
    let thumbnailUrl: String?
    let completedAt: String
    let fileSize: Int?

    var formattedSize: String {
        guard let size = fileSize else { return "" }
        let mb = Double(size) / 1_000_000
        return mb >= 1 ? String(format: "%.1f MB", mb) : "\(size/1000) KB"
    }
}

// MARK: - Auto Download

struct AutoSubscription: Codable, Identifiable {
    let id: String
    let url: String
    let title: String?
    let frequency: String
    let active: Bool
    let lastChecked: String?
    let downloadCount: Int
}

struct AutoSubscribeRequest: Codable {
    let url: String
    let frequency: String
}

// MARK: - Scheduled

struct ScheduledDownload: Codable, Identifiable {
    let id: String
    let url: String
    let scheduledAt: String
    let quality: String
    let status: String
    let title: String?
}

// MARK: - Collections

struct MediaCollection: Codable, Identifiable {
    let id: String
    var name: String
    var itemIds: [String]
    let createdAt: String
}

// MARK: - Private Sessions

struct PlatformSession: Codable, Identifiable {
    let id: String
    let platform: String
    let username: String?
    let connectedAt: String?
}

// MARK: - Subscription Plans

struct SubscriptionPlan: Identifiable {
    let id: String
    let name: String
    let price: String
    let period: String
    let features: [String]
    let tier: SubscriptionTier
    let highlighted: Bool
}

// MARK: - Cloud

enum CloudProvider: String, CaseIterable, Identifiable {
    case files       = "Dosyalar / iCloud"
    case googleDrive = "Google Drive"
    var id: String { rawValue }
}

// MARK: - Download Mode

enum DownloadMode: String, CaseIterable, Identifiable {
    case single      = "Tek Video"
    case clip        = "Klip"
    case gif         = "GIF"
    case subtitles   = "Altyazı"
    case keyMoments  = "Önemli Anlar"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .single:     return "arrow.down.circle.fill"
        case .clip:       return "scissors"
        case .gif:        return "photo.fill"
        case .subtitles:  return "captions.bubble.fill"
        case .keyMoments: return "sparkles"
        }
    }
}
