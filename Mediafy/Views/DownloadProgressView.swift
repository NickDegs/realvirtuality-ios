import SwiftUI

struct DownloadProgressView: View {
    let taskId: String
    let onDismiss: () -> Void

    @State private var status: DownloadStatus?

    var body: some View {
        VStack(spacing: 16) {
            if let status = status {
                switch status.status {
                case "completed":
                    completedView(status)
                case "failed":
                    failedView(status)
                default:
                    progressView(status)
                }
            } else {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Hazırlanıyor...")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .task { await pollStatus() }
    }

    private func progressView(_ status: DownloadStatus) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("İndiriliyor")
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int((status.progress ?? 0) * 100))%")
                    .foregroundColor(.secondary)
            }
            ProgressView(value: status.progress ?? 0)
                .tint(.purple)
        }
    }

    @ViewBuilder
    private func completedView(_ status: DownloadStatus) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.green)
            Text("İndirme tamamlandı!")
                .fontWeight(.semibold)
            if let urlStr = status.downloadUrl, let url = URL(string: urlStr) {
                ShareLink(item: url) {
                    Label("Paylaş / Kaydet", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            Button("Kapat", action: onDismiss)
                .foregroundColor(.secondary)
        }
    }

    private func failedView(_ status: DownloadStatus) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "xmark.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text("İndirme başarısız")
                .fontWeight(.semibold)
            if let error = status.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Kapat", action: onDismiss)
                .foregroundColor(.secondary)
        }
    }

    private func pollStatus() async {
        while true {
            do {
                status = try await APIService.shared.getDownloadStatus(taskId: taskId)
                if status?.status == "completed" || status?.status == "failed" { break }
                try await Task.sleep(nanoseconds: 2_000_000_000)
            } catch {
                break
            }
        }
    }
}
