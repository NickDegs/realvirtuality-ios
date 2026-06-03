import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Geçersiz URL"
        case .unauthorized: return "Oturum süresi doldu, lütfen tekrar giriş yapın"
        case .serverError(let msg): return msg
        case .decodingError: return "Veri işleme hatası"
        }
    }
}

final class APIService {
    static let shared = APIService()
    private let baseURL = "https://api.realvirtuality.app"
    private let session = URLSession.shared

    private init() {}

    private var token: String? { KeychainService.shared.loadToken() }

    private func request<T: Decodable>(_ path: String, method: String = "GET", body: Encodable? = nil) async throws -> T {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body { req.httpBody = try JSONEncoder().encode(body) }

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.serverError("Bağlantı hatası") }

        if http.statusCode == 401 { throw APIError.unauthorized }
        if http.statusCode >= 400 {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"] ?? "Sunucu hatası"
            throw APIError.serverError(msg)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        guard let result = try? decoder.decode(T.self, from: data) else { throw APIError.decodingError }
        return result
    }

    // MARK: - Auth

    func login(email: String, password: String) async throws -> AuthResponse {
        struct Body: Encodable { let email, password: String }
        return try await request("/auth/login", method: "POST", body: Body(email: email, password: password))
    }

    func register(email: String, username: String, password: String) async throws -> AuthResponse {
        struct Body: Encodable { let email, username, password: String }
        return try await request("/auth/register", method: "POST", body: Body(email: email, username: username, password: password))
    }

    func getMe() async throws -> User {
        return try await request("/auth/me")
    }

    func refreshToken() async throws -> AuthResponse {
        return try await request("/auth/refresh", method: "POST")
    }

    // MARK: - Download

    func startDownload(url: String, quality: String? = nil, audioOnly: Bool = false) async throws -> DownloadResponse {
        let body = DownloadRequest(url: url, quality: quality, audioOnly: audioOnly)
        return try await request("/download/start", method: "POST", body: body)
    }

    func getDownloadStatus(taskId: String) async throws -> DownloadStatus {
        return try await request("/download/status/\(taskId)")
    }

    // MARK: - Subscription

    func getCheckoutURL(plan: String) async throws -> String {
        struct Body: Encodable { let plan: String }
        struct Response: Decodable { let checkoutUrl: String }
        let response: Response = try await request("/subscription/checkout", method: "POST", body: Body(plan: plan))
        return response.checkoutUrl
    }

    func startDownload(url: String, quality: String? = nil, audioOnly: Bool = false, noWatermark: Bool = false) async throws -> DownloadResponse {
        struct Body: Encodable { let url: String; let quality: String?; let audioOnly: Bool?; let noWatermark: Bool? }
        return try await request("/download/start", method: "POST",
            body: Body(url: url, quality: quality, audioOnly: audioOnly, noWatermark: noWatermark))
    }

    // MARK: - Bulk Download

    func fetchBulkItems(url: String, limit: Int = 50) async throws -> BulkDownloadListResponse {
        let body = BulkDownloadRequest(url: url, limit: limit)
        return try await request("/download/bulk/list", method: "POST", body: body)
    }

    func startBulkDownload(bulkId: String, itemIds: [String]) async throws -> BulkStartResponse {
        struct Body: Encodable { let bulkId: String; let itemIds: [String] }
        return try await request("/download/bulk/start", method: "POST",
            body: Body(bulkId: bulkId, itemIds: itemIds))
    }

    // MARK: - Auto Download

    func getAutoSubscriptions() async throws -> [AutoSubscription] {
        return try await request("/download/auto/list")
    }

    func addAutoSubscription(url: String, frequency: String) async throws -> AutoSubscription {
        let body = AutoSubscribeRequest(url: url, frequency: frequency)
        return try await request("/download/auto/subscribe", method: "POST", body: body)
    }

    func deleteAutoSubscription(id: String) async throws {
        struct Empty: Decodable {}
        let _: Empty = try await request("/download/auto/\(id)", method: "DELETE")
    }

    // MARK: - Gallery / History

    func getDownloadHistory(page: Int = 1) async throws -> [DownloadHistoryItem] {
        return try await request("/download/history?page=\(page)")
    }

    // MARK: - Clip / GIF

    func startClip(url: String, startTime: Double, endTime: Double, asGif: Bool = false, quality: String? = nil) async throws -> DownloadResponse {
        let body = ClipRequest(url: url, startTime: startTime, endTime: endTime, asGif: asGif, quality: quality)
        return try await request("/download/clip", method: "POST", body: body)
    }

    // MARK: - Subtitles

    func getSubtitleTracks(url: String) async throws -> [SubtitleTrack] {
        struct Body: Encodable { let url: String }
        return try await request("/download/subtitles/tracks", method: "POST", body: Body(url: url))
    }

    func startSubtitleDownload(url: String, language: String, embed: Bool) async throws -> DownloadResponse {
        let body = SubtitleRequest(url: url, language: language, embed: embed)
        return try await request("/download/subtitles/start", method: "POST", body: body)
    }

    // MARK: - Key Moments

    func getVideoInfo(url: String) async throws -> VideoInfo {
        struct Body: Encodable { let url: String }
        return try await request("/download/info", method: "POST", body: Body(url: url))
    }

    func startChapterDownload(url: String, chapterIds: [String]) async throws -> BulkStartResponse {
        struct Body: Encodable { let url: String; let chapterIds: [String] }
        return try await request("/download/chapters", method: "POST", body: Body(url: url, chapterIds: chapterIds))
    }

    // MARK: - Scheduled

    func getScheduledDownloads() async throws -> [ScheduledDownload] {
        return try await request("/download/scheduled/list")
    }

    func scheduleDownload(url: String, scheduledAt: Date, quality: String) async throws -> ScheduledDownload {
        struct Body: Encodable { let url: String; let scheduledAt: String; let quality: String }
        let formatter = ISO8601DateFormatter()
        return try await request("/download/scheduled/add", method: "POST",
            body: Body(url: url, scheduledAt: formatter.string(from: scheduledAt), quality: quality))
    }

    func deleteScheduledDownload(id: String) async throws {
        struct Empty: Decodable {}
        let _: Empty = try await request("/download/scheduled/\(id)", method: "DELETE")
    }

    // MARK: - Instagram

    func saveInstagramSession(cookies: String) async throws {
        struct Body: Encodable { let cookies: String }
        struct Response: Decodable { let success: Bool }
        let _: Response = try await request("/instagram/session", method: "POST", body: Body(cookies: cookies))
    }
}
