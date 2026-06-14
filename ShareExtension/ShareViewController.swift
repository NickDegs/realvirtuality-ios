import UIKit
import UniformTypeIdentifiers
import Photos

// MARK: - Config
private let kAPIBase = "https://realvirtuality.app/downify-api"
private let kToken   = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI5M2VhN2E0OC04MjZjLTQwNGUtYTJjNC0zMzY2Y2Q0ZmMzYmQiLCJleHAiOjE4MTI5MDU3MTN9.PI5vbjqHDb0HpV-IijwM98XM4x_7RIjQM2ykO9jEW5g"

// MARK: - Colors
private extension UIColor {
    static let brand      = UIColor(red: 0.49, green: 0.23, blue: 0.93, alpha: 1)
    static let surface    = UIColor(red: 0.10, green: 0.10, blue: 0.18, alpha: 1)
    static let background = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1)
    static let border     = UIColor(red: 0.18, green: 0.18, blue: 0.31, alpha: 1)
}

// MARK: - ShareViewController
class ShareViewController: UIViewController {

    // UI
    private let card        = UIView()
    private let handleBar   = UIView()
    private let iconLabel   = UILabel()
    private let titleLabel  = UILabel()
    private let subtitleLabel = UILabel()
    private let spinner     = UIActivityIndicatorView(style: .medium)
    private let videoBtn    = UIButton(type: .system)
    private let audioBtn    = UIButton(type: .system)
    private let progressBar = UIProgressView(progressViewStyle: .default)
    private let statusLabel = UILabel()
    private let cancelBtn   = UIButton(type: .system)

    private var sharedURL: String = ""
    private var mediaType: String = "video"
    private var pollTimer: Timer?
    private var taskID: String?
    private var downloadURL: String?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        extractURL()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tappedBackground))
        view.addGestureRecognizer(tap)

        // Card
        card.backgroundColor = .surface
        card.layer.cornerRadius = 24
        card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        card.clipsToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        // Handle bar
        handleBar.backgroundColor = .border
        handleBar.layer.cornerRadius = 2
        handleBar.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(handleBar)

        // Icon
        iconLabel.text = "⬇️"
        iconLabel.font = .systemFont(ofSize: 36)
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(iconLabel)

        // Title
        titleLabel.text = "Downify"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        // Subtitle
        subtitleLabel.text = "Tespit ediliyor..."
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = UIColor(white: 0.6, alpha: 1)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(subtitleLabel)

        // Spinner
        spinner.color = .white
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(spinner)

        // Video button
        videoBtn.setTitle("🎬  Video İndir", for: .normal)
        videoBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        videoBtn.setTitleColor(.white, for: .normal)
        videoBtn.backgroundColor = .brand
        videoBtn.layer.cornerRadius = 14
        videoBtn.isHidden = true
        videoBtn.translatesAutoresizingMaskIntoConstraints = false
        videoBtn.addTarget(self, action: #selector(downloadVideo), for: .touchUpInside)
        card.addSubview(videoBtn)

        // Audio button
        audioBtn.setTitle("🎵  Ses Olarak İndir (MP3)", for: .normal)
        audioBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        audioBtn.setTitleColor(UIColor(red: 0.67, green: 0.55, blue: 1, alpha: 1), for: .normal)
        audioBtn.backgroundColor = .border
        audioBtn.layer.cornerRadius = 14
        audioBtn.isHidden = true
        audioBtn.translatesAutoresizingMaskIntoConstraints = false
        audioBtn.addTarget(self, action: #selector(downloadAudio), for: .touchUpInside)
        card.addSubview(audioBtn)

        // Progress bar
        progressBar.progressTintColor = .brand
        progressBar.trackTintColor = .border
        progressBar.layer.cornerRadius = 3
        progressBar.clipsToBounds = true
        progressBar.isHidden = true
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(progressBar)

        // Status label
        statusLabel.text = ""
        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textColor = UIColor(white: 0.6, alpha: 1)
        statusLabel.textAlignment = .center
        statusLabel.isHidden = true
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(statusLabel)

        // Cancel
        cancelBtn.setTitle("İptal", for: .normal)
        cancelBtn.titleLabel?.font = .systemFont(ofSize: 15)
        cancelBtn.setTitleColor(UIColor(white: 0.5, alpha: 1), for: .normal)
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        cancelBtn.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        card.addSubview(cancelBtn)

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            handleBar.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            handleBar.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            handleBar.widthAnchor.constraint(equalToConstant: 40),
            handleBar.heightAnchor.constraint(equalToConstant: 4),

            iconLabel.topAnchor.constraint(equalTo: handleBar.bottomAnchor, constant: 20),
            iconLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            titleLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),

            spinner.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            spinner.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            videoBtn.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            videoBtn.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            videoBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            videoBtn.heightAnchor.constraint(equalToConstant: 52),

            audioBtn.topAnchor.constraint(equalTo: videoBtn.bottomAnchor, constant: 10),
            audioBtn.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            audioBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            audioBtn.heightAnchor.constraint(equalToConstant: 52),

            progressBar.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 28),
            progressBar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            progressBar.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            progressBar.heightAnchor.constraint(equalToConstant: 6),

            statusLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),

            cancelBtn.topAnchor.constraint(equalTo: audioBtn.bottomAnchor, constant: 12),
            cancelBtn.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            cancelBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            cancelBtn.heightAnchor.constraint(equalToConstant: 44),
        ])

        card.transform = CGAffineTransform(translationX: 0, y: 400)
    }

    private func animateIn() {
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
            self.card.transform = .identity
        }
    }

    // MARK: - URL Extraction
    private func extractURL() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments else { close(); return }

        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] item, _ in
                    DispatchQueue.main.async {
                        if let url = item as? URL {
                            self?.didGetURL(url.absoluteString)
                        } else { self?.close() }
                    }
                }
                return
            }
            if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] item, _ in
                    DispatchQueue.main.async {
                        if let text = item as? String,
                           let url = self?.firstURL(in: text) {
                            self?.didGetURL(url)
                        } else { self?.close() }
                    }
                }
                return
            }
        }
        close()
    }

    private func firstURL(in text: String) -> String? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        return detector?.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))?.url?.absoluteString
    }

    private func didGetURL(_ urlString: String) {
        sharedURL = urlString
        // Trim to readable form for subtitle
        let host = URL(string: urlString)?.host ?? urlString
        subtitleLabel.text = host
        detectMediaType()
    }

    // MARK: - API
    private func api<T: Decodable>(_ path: String, method: String = "GET",
                                    body: [String: Any]? = nil,
                                    completion: @escaping (T?) -> Void) {
        guard let url = URL(string: kAPIBase + path) else { completion(nil); return }
        var req = URLRequest(url: url, timeoutInterval: 30)
        req.httpMethod = method
        req.setValue("Bearer \(kToken)", forHTTPHeaderField: "Authorization")
        if let body = body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data,
                  let result = try? JSONDecoder().decode(T.self, from: data) else {
                completion(nil); return
            }
            completion(result)
        }.resume()
    }

    // MARK: - Detect
    private struct DetectResponse: Decodable {
        let media_type: String
        let title: String?
    }

    private func detectMediaType() {
        api("/download/detect", method: "POST", body: ["url": sharedURL]) { [weak self] (resp: DetectResponse?) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.spinner.stopAnimating()
                self.mediaType = resp?.media_type ?? "video"
                let title = resp?.title.flatMap { $0.isEmpty ? nil : $0 } ?? ""
                if !title.isEmpty {
                    self.subtitleLabel.text = String(title.prefix(60))
                }
                switch self.mediaType {
                case "image":
                    self.subtitleLabel.text = (self.subtitleLabel.text ?? "") + "\n🖼️ Görsel"
                    self.startDownload(audioOnly: false)
                case "audio":
                    self.startDownload(audioOnly: true)
                default: // video
                    self.showFormatButtons()
                }
            }
        }
    }

    private func showFormatButtons() {
        videoBtn.isHidden = false
        audioBtn.isHidden = false
        // Fix cancel button constraints for format selection state
        cancelBtn.topAnchor.constraint(equalTo: audioBtn.bottomAnchor, constant: 12).isActive = true
    }

    // MARK: - Actions
    @objc private func downloadVideo() { startDownload(audioOnly: false) }
    @objc private func downloadAudio() { startDownload(audioOnly: true) }

    // MARK: - Download
    private struct StartResponse: Decodable { let task_id: String }
    private struct StatusResponse: Decodable {
        let status: String
        let progress: Int?
        let download_url: String?
        let error: String?
        let title: String?
    }

    private func startDownload(audioOnly: Bool) {
        videoBtn.isHidden = true
        audioBtn.isHidden = true
        progressBar.isHidden = false
        statusLabel.isHidden = false
        spinner.startAnimating()
        subtitleLabel.text = audioOnly ? "🎵 Ses ayıklanıyor..." : "⬇️ İndiriliyor..."
        progressBar.setProgress(0.05, animated: true)

        api("/download/start", method: "POST",
            body: ["url": sharedURL, "audio_only": audioOnly, "quality": "best"]) { [weak self] (resp: StartResponse?) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.spinner.stopAnimating()
                guard let taskID = resp?.task_id else {
                    self.showError("İndirme başlatılamadı")
                    return
                }
                self.taskID = taskID
                self.startPolling()
            }
        }
    }

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.checkStatus()
        }
    }

    private func checkStatus() {
        guard let taskID = taskID else { return }
        api("/download/status/\(taskID)") { [weak self] (resp: StatusResponse?) in
            DispatchQueue.main.async {
                guard let self = self, let resp = resp else { return }
                let progress = Float(resp.progress ?? 0) / 100.0
                self.progressBar.setProgress(max(0.05, progress), animated: true)
                self.statusLabel.text = "\(resp.progress ?? 0)%  •  \(resp.title ?? "")"

                switch resp.status {
                case "completed":
                    self.pollTimer?.invalidate()
                    self.progressBar.setProgress(1.0, animated: true)
                    self.statusLabel.text = "✅ Hazır, kaydediliyor..."
                    if let urlStr = resp.download_url {
                        self.downloadFile(urlStr)
                    }
                case "failed":
                    self.pollTimer?.invalidate()
                    self.showError(resp.error ?? "İndirme başarısız")
                default:
                    break
                }
            }
        }
    }

    // MARK: - File Download & Save
    private func downloadFile(_ urlString: String) {
        guard let url = URL(string: urlString) else { showError("Geçersiz dosya URL"); return }
        var req = URLRequest(url: url, timeoutInterval: 300)
        req.setValue("Bearer \(kToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.downloadTask(with: req) { [weak self] tmpURL, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let tmpURL = tmpURL else { self.showError("Dosya indirilemedi"); return }

                let filename = (response as? HTTPURLResponse)?
                    .value(forHTTPHeaderField: "Content-Disposition")
                    .flatMap { self.extractFilename(from: $0) }
                    ?? url.lastPathComponent

                let ext = (filename as NSString).pathExtension.lowercased()
                let isAudio = ["mp3", "m4a", "aac", "opus", "flac", "wav"].contains(ext)
                let isImage = ["jpg", "jpeg", "png", "webp", "gif", "heic"].contains(ext)

                if isAudio {
                    self.saveAudioToFiles(tmpURL, filename: filename)
                } else if isImage {
                    self.saveImageToPhotos(tmpURL)
                } else {
                    self.saveVideoToPhotos(tmpURL)
                }
            }
        }
        task.resume()
    }

    private func extractFilename(from disposition: String) -> String? {
        let parts = disposition.components(separatedBy: ";")
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("filename=") {
                return trimmed
                    .replacingOccurrences(of: "filename=", with: "")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
        }
        return nil
    }

    private func saveVideoToPhotos(_ tmpURL: URL) {
        let destURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mp4")
        try? FileManager.default.moveItem(at: tmpURL, to: destURL)

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { self?.showError("Fotoğraf erişimi reddedildi") }
                return
            }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: destURL)
            } completionHandler: { success, _ in
                DispatchQueue.main.async {
                    if success { self?.showSuccess("📹 Video kaydedildi!") }
                    else { self?.showError("Video kaydedilemedi") }
                    try? FileManager.default.removeItem(at: destURL)
                }
            }
        }
    }

    private func saveImageToPhotos(_ tmpURL: URL) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { self?.showError("Fotoğraf erişimi reddedildi") }
                return
            }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: tmpURL)
            } completionHandler: { success, _ in
                DispatchQueue.main.async {
                    if success { self?.showSuccess("🖼️ Görsel kaydedildi!") }
                    else { self?.showError("Görsel kaydedilemedi") }
                }
            }
        }
    }

    private func saveAudioToFiles(_ tmpURL: URL, filename: String) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dest = docs.appendingPathComponent(filename.isEmpty ? "audio.mp3" : filename)
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.moveItem(at: tmpURL, to: dest)
            DispatchQueue.main.async { self.showSuccess("🎵 Ses Dosyalar'a kaydedildi!") }
        } catch {
            DispatchQueue.main.async { self.showError("Ses kaydedilemedi") }
        }
    }

    // MARK: - State
    private func showError(_ msg: String) {
        spinner.stopAnimating()
        progressBar.isHidden = true
        iconLabel.text = "❌"
        titleLabel.text = "Hata"
        subtitleLabel.text = msg
        subtitleLabel.textColor = UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 1)
        statusLabel.isHidden = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.close() }
    }

    private func showSuccess(_ msg: String) {
        spinner.stopAnimating()
        progressBar.isHidden = true
        statusLabel.isHidden = true
        iconLabel.text = "✅"
        titleLabel.text = "Tamamlandı"
        subtitleLabel.text = msg
        subtitleLabel.textColor = UIColor(red: 0.3, green: 0.85, blue: 0.4, alpha: 1)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.close() }
    }

    // MARK: - Dismiss
    @objc private func tappedBackground(_ gesture: UITapGestureRecognizer) {
        if !card.frame.contains(gesture.location(in: view)) { cancel() }
    }

    @objc private func cancel() {
        pollTimer?.invalidate()
        close()
    }

    private func close() {
        UIView.animate(withDuration: 0.25) {
            self.card.transform = CGAffineTransform(translationX: 0, y: 400)
            self.view.alpha = 0
        } completion: { _ in
            self.extensionContext?.completeRequest(returningItems: nil)
        }
    }
}
