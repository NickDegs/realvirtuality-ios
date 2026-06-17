import SwiftUI

struct DownloadProgressView: View {
    let taskId: String
    let onDismiss: () -> Void

    @State private var status: DownloadStatus?

    var body: some View {
        VStack(spacing: 16) {
            if let status = status {
                switch status.status {
                case "completed": completedView(status)
                case "failed":    failedView(status)
                default:          progressView(status)
                }
            } else {
                HStack(spacing: 12) {
                    ProgressView().tint(Theme.accent)
                    Text("Hazırlanıyor...").foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(20)
        .glassCard()
        .task { await pollStatus() }
    }

    private func progressView(_ status: DownloadStatus) -> some View {
        VStack(spacing: 10) {
            HStack {
                Label("İndiriliyor", systemImage: "arrow.down.circle")
                    .foregroundStyle(Theme.accent).fontWeight(.medium)
                Spacer()
                Text("\(Int((status.progress ?? 0) * 100))%")
                    .font(.subheadline.bold()).foregroundStyle(Theme.accent)
            }
            ProgressView(value: status.progress ?? 0)
                .tint(Theme.accent)
        }
    }

    @ViewBuilder
    private func completedView(_ status: DownloadStatus) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40)).foregroundStyle(.green)
            Text("İndirme tamamlandı!").fontWeight(.semibold)

            if let urlStr = status.downloadUrl, let url = URL(string: urlStr) {
                SaveToGalleryButton(downloadURL: url, filename: status.filename ?? "video.mp4")
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                ShareLink(item: url) {
                    Label("Paylaş / Kaydet", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
            }

            Button("Kapat", action: onDismiss)
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private func failedView(_ status: DownloadStatus) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 40)).foregroundStyle(.red)
            Text("İndirme başarısız").fontWeight(.semibold)
            if let error = status.error {
                Text(error).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            Button("Kapat", action: onDismiss)
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private func pollStatus() async {
        let maxAttempts = 150
        for _ in 0..<maxAttempts {
            do {
                status = try await APIService.shared.getDownloadStatus(taskId: taskId)
                if status?.status == "completed" || status?.status == "failed" { return }
                try await Task.sleep(nanoseconds: 2_000_000_000)
            } catch { return }
        }
        if status == nil || (status?.status != "completed" && status?.status != "failed") {
            status = DownloadStatus(taskId: taskId, status: "failed", progress: nil,
                                    downloadUrl: nil, filename: nil, fileSize: nil, error: "Zaman aşımı")
        }
    }
}
