import SwiftUI

struct ClipView: View {
    @EnvironmentObject var authState: AuthState
    @State private var urlText = ""
    @State private var startMinutes = 0
    @State private var startSeconds = 0
    @State private var endMinutes = 0
    @State private var endSeconds = 30
    @State private var asGif = false
    @State private var gifFps = 15
    @State private var isDownloading = false
    @State private var downloadTask: DownloadResponse?
    @State private var errorMessage: String?
    @AppStorage("defaultQuality") private var quality = "best"

    var startTime: Double { Double(startMinutes * 60 + startSeconds) }
    var endTime: Double { Double(endMinutes * 60 + endSeconds) }
    var isValid: Bool { !urlText.isEmpty && endTime > startTime }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                modeHeader
                urlSection
                timeSection
                gifToggle
                if asGif { gifOptions }
                downloadButton
                if let task = downloadTask {
                    DownloadProgressView(taskId: task.taskId) {
                        downloadTask = nil
                    }
                }
            }
            .padding()
        }
        .alert("Hata", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) { Button("Tamam") { errorMessage = nil } }
        message: { Text(errorMessage ?? "") }
    }

    private var modeHeader: some View {
        HStack(spacing: 16) {
            Image(systemName: asGif ? "photo.fill" : "scissors")
                .font(.system(size: 32))
                .foregroundColor(.purple)
            VStack(alignment: .leading, spacing: 2) {
                Text(asGif ? "GIF Oluşturucu" : "Klip Kesici")
                    .font(.title3.bold())
                Text(asGif ? "Seçilen kısımdan animasyonlu GIF üret" : "Videonun istediğin bölümünü indir")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var urlSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Video URL'si").font(.headline)
            HStack {
                TextField("Instagram, TikTok, YouTube...", text: $urlText)
                    .textFieldStyle(.plain)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button {
                    urlText = UIPasteboard.general.string ?? ""
                } label: {
                    Image(systemName: "doc.on.clipboard")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Zaman Aralığı").font(.headline)

            HStack(spacing: 16) {
                timeInput(label: "Başlangıç", minutes: $startMinutes, seconds: $startSeconds)
                Image(systemName: "arrow.right").foregroundColor(.secondary)
                timeInput(label: "Bitiş", minutes: $endMinutes, seconds: $endSeconds)
            }

            if endTime <= startTime {
                Label("Bitiş zamanı başlangıçtan büyük olmalı", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                let duration = endTime - startTime
                Label("Süre: \(Int(duration))s (\(String(format: "%.1f", duration/60)) dk)", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func timeInput(label: String, minutes: Binding<Int>, seconds: Binding<Int>) -> some View {
        VStack(spacing: 6) {
            Text(label).font(.caption).foregroundColor(.secondary)
            HStack(spacing: 4) {
                Picker("", selection: minutes) {
                    ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                }
                .frame(width: 55)
                .clipped()
                Text(":").font(.title3.bold())
                Picker("", selection: seconds) {
                    ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                }
                .frame(width: 55)
                .clipped()
            }
            .pickerStyle(.wheel)
            .frame(height: 80)
        }
    }

    private var gifToggle: some View {
        Toggle(isOn: $asGif) {
            Label("GIF olarak oluştur", systemImage: "photo.fill")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var gifOptions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GIF Ayarları").font(.subheadline.bold())
            HStack {
                Text("FPS: \(gifFps)")
                Slider(value: .init(
                    get: { Double(gifFps) },
                    set: { gifFps = Int($0) }
                ), in: 5...24, step: 1)
            }
            Text("Düşük FPS → küçük dosya, yüksek FPS → akıcı animasyon")
                .font(.caption2).foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var downloadButton: some View {
        Button {
            Task { await startClip() }
        } label: {
            HStack {
                if isDownloading { ProgressView().tint(.white) }
                else { Image(systemName: asGif ? "photo.fill" : "scissors") }
                Text(isDownloading ? "Hazırlanıyor..." : asGif ? "GIF Oluştur" : "Klibi İndir")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(!isValid || isDownloading ? Color.gray : Color.purple)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!isValid || isDownloading)
    }

    private func startClip() async {
        isDownloading = true
        errorMessage = nil
        do {
            downloadTask = try await APIService.shared.startClip(
                url: urlText,
                startTime: startTime,
                endTime: endTime,
                asGif: asGif,
                quality: quality == "best" ? nil : quality
            )
        } catch APIError.unauthorized {
            authState.logout()
        } catch {
            errorMessage = error.localizedDescription
        }
        isDownloading = false
    }
}
