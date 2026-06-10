import SwiftUI

struct ClipView: View {
    var startAsGif: Bool = false
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
            VStack(spacing: 16) {
                modeHeader
                    .onAppear { if startAsGif { asGif = true } }
                urlSection
                timeSection
                gifToggle
                if asGif { gifOptions }
                downloadButtonView
                if let task = downloadTask {
                    DownloadProgressView(taskId: task.taskId) { downloadTask = nil }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .alert("Hata", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) { Button("Tamam") { errorMessage = nil } }
        message: { Text(errorMessage ?? "") }
    }

    // MARK: - Header

    private var modeHeader: some View {
        HStack(spacing: 14) {
            Image(systemName: asGif ? "photo.fill" : "scissors")
                .font(.system(size: 22))
                .foregroundStyle(asGif ? Color.orange : Color.brand)
                .frame(width: 52, height: 52)
                .background((asGif ? Color.orange : Color.brand).opacity(0.14),
                            in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text(asGif ? "GIF Oluşturucu" : "Klip Kesici").font(.headline)
                Text(asGif ? "Seçilen kısımdan animasyonlu GIF üret" : "Videonun istediğin bölümünü indir")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - URL

    private var urlSection: some View {
        HStack(spacing: 10) {
            TextField("Instagram, TikTok, YouTube...", text: $urlText)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button {
                urlText = UIPasteboard.general.string ?? ""
            } label: {
                Image(systemName: "doc.on.clipboard").foregroundStyle(.purple)
            }
        }
        .padding(14)
        .glassInput()
    }

    // MARK: - Time

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Zaman Aralığı")
                .font(.caption.bold()).foregroundStyle(.secondary).padding(.horizontal, 4)

            HStack(spacing: 12) {
                timeInput(label: "Başlangıç", minutes: $startMinutes, seconds: $startSeconds)
                Image(systemName: "arrow.right").foregroundStyle(.secondary).padding(.bottom, 8)
                timeInput(label: "Bitiş", minutes: $endMinutes, seconds: $endSeconds)
            }

            if endTime <= startTime {
                Label("Bitiş zamanı başlangıçtan büyük olmalı", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(.orange)
            } else {
                let duration = endTime - startTime
                Label("Süre: \(Int(duration))s (\(String(format: "%.1f", duration/60)) dk)",
                      systemImage: "clock")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .glassCard()
    }

    private func timeInput(label: String, minutes: Binding<Int>, seconds: Binding<Int>) -> some View {
        VStack(spacing: 6) {
            Text(label).font(.caption.bold()).foregroundStyle(.secondary)
            HStack(spacing: 2) {
                Picker("", selection: minutes) {
                    ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                }
                .frame(width: 55).clipped()
                Text(":").font(.title3.bold()).foregroundStyle(.secondary)
                Picker("", selection: seconds) {
                    ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                }
                .frame(width: 55).clipped()
            }
            .pickerStyle(.wheel)
            .frame(height: 80)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - GIF Toggle

    private var gifToggle: some View {
        Toggle(isOn: $asGif.animation()) {
            HStack(spacing: 10) {
                Image(systemName: "photo.fill").foregroundStyle(.orange).frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("GIF olarak oluştur").font(.subheadline.bold())
                    Text("Video yerine animasyonlu GIF üret")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .tint(.orange)
        .padding(16)
        .glassCard()
    }

    // MARK: - GIF Options

    private var gifOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GIF Ayarları").font(.caption.bold()).foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Text("FPS").font(.subheadline.bold()).frame(width: 30)
                Slider(value: .init(get: { Double(gifFps) }, set: { gifFps = Int($0) }),
                       in: 5...24, step: 1)
                    .tint(.orange)
                Text("\(gifFps)").font(.subheadline.bold()).foregroundStyle(.orange).frame(width: 28, alignment: .trailing)
            }
            Text("Düşük FPS → küçük dosya • Yüksek FPS → akıcı animasyon")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Download Button

    private var downloadButtonView: some View {
        Button {
            Task { await startClip() }
        } label: {
            HStack {
                Spacer()
                LoadingLabel(isLoading: isDownloading,
                             icon: asGif ? "photo.fill" : "scissors",
                             loadingText: "Hazırlanıyor...",
                             idleText: asGif ? "GIF Oluştur" : "Klibi İndir")
                Spacer()
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(asGif ? .orange : .purple)
        .disabled(!isValid || isDownloading)
    }

    private func startClip() async {
        isDownloading = true; errorMessage = nil
        do {
            downloadTask = try await APIService.shared.startClip(
                url: urlText, startTime: startTime, endTime: endTime,
                asGif: asGif, quality: quality == "best" ? nil : quality)
        } catch APIError.unauthorized { authState.logout() }
        catch { errorMessage = error.localizedDescription }
        isDownloading = false
    }
}
