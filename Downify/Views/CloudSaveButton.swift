import SwiftUI
import UniformTypeIdentifiers

struct CloudSaveButton: View {
    let downloadURL: URL
    let filename: String
    @State private var isDownloading = false
    @State private var localURL: URL?
    @State private var showPicker = false
    @State private var errorMessage: String?

    var body: some View {
        Button {
            Task { await downloadAndSave() }
        } label: {
            HStack {
                if isDownloading { ProgressView().tint(.primary) }
                else { Image(systemName: "icloud.and.arrow.up") }
                Text(isDownloading ? "Hazırlanıyor..." : "Files / iCloud'a Kaydet")
            }
            .frame(maxWidth: .infinity)
        }
        .disabled(isDownloading)
        .frosted(in: RoundedRectangle(cornerRadius: 14))
        .fileExporter(
            isPresented: $showPicker,
            document: localURL.map { VideoFile(url: $0) },
            contentType: .movie,
            defaultFilename: filename
        ) { result in
            localURL = nil
            if case .failure(let e) = result { errorMessage = e.localizedDescription }
        }
        .alert("Hata", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) { Button("Tamam") { errorMessage = nil } }
        message: { Text(errorMessage ?? "") }
    }

    private func downloadAndSave() async {
        isDownloading = true
        do {
            let (tempURL, _) = try await URLSession.shared.download(from: downloadURL)
            let destURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(filename.isEmpty ? "video.mp4" : filename)
            try? FileManager.default.removeItem(at: destURL)
            try FileManager.default.moveItem(at: tempURL, to: destURL)
            localURL = destURL
            showPicker = true
        } catch { errorMessage = error.localizedDescription }
        isDownloading = false
    }
}

struct VideoFile: FileDocument {
    static var readableContentTypes: [UTType] { [.movie, .video, .mpeg4Movie] }
    let url: URL
    init(url: URL) { self.url = url }
    init(configuration: ReadConfiguration) throws {
        url = FileManager.default.temporaryDirectory.appendingPathComponent("video.mp4")
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try FileWrapper(url: url)
    }
}
