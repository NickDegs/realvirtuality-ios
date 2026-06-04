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
                    ProgressView().tint(.purple)
                    Text("Hazırlanıyor...")
                        .foregroundStyle(.secondary)
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
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle")
                        .foregroundStyle(.purple)
                    Text("İndiriliyor")
                        .fontWeight(.medium)
                }
                Spacer()
                Text("\(Int((status.progress ?? 0) * 100))%")
                    .font(.subheadline.bold())
                    .foregroundStyle(.purple)
            }
            ProgressView(value: status.progress ?? 0)
                .tint(.purple)
                .scaleEffect(y: 1.4)
        }
    }

    @ViewBuilder
    private func completedView(_ status: DownloadStatus) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.green)
            }
            Text("İndirme tamamlandı!")
                .fontWeight(.semibold)

            if let urlStr = status.downloadUrl, let url = URL(string: urlStr) {
                ShareLink(item: url) {
                    Label("Paylaş / Kaydet", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PrimaryButtonStyle())
            }

            Button("Kapat", action: onDismiss)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func failedView(_ status: DownloadStatus) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.red)
            }
            Text("İndirme başarısız")
                .fontWeight(.semibold)
            if let error = status.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Kapat", action: onDismiss)
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
