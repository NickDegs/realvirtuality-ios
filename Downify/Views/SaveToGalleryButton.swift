import SwiftUI
import Photos

/// Downloads a (public) media file and saves it straight into the device
/// Photos library / gallery. Used both right after a download and when
/// re-saving a past item from the download history.
struct SaveToGalleryButton: View {
    let downloadURL: URL
    let filename: String

    @State private var state: SaveState = .idle

    enum SaveState: Equatable {
        case idle, working, done
        case failed(String)
    }

    private var isBusy: Bool { state == .working }

    var body: some View {
        Button {
            Task { await save() }
        } label: {
            HStack {
                switch state {
                case .working:
                    ProgressView().tint(.primary)
                case .done:
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                default:
                    Image(systemName: "square.and.arrow.down")
                }
                Text(labelText)
            }
            .frame(maxWidth: .infinity)
        }
        .disabled(isBusy || state == .done)
        .glassEffect(in: RoundedRectangle(cornerRadius: 14))
        .alert("Hata", isPresented: .init(
            get: { if case .failed = state { return true } else { return false } },
            set: { if !$0 { state = .idle } }
        )) {
            Button("Tamam") { state = .idle }
        } message: {
            if case .failed(let msg) = state { Text(msg) }
        }
    }

    private var labelText: LocalizedStringKey {
        switch state {
        case .working: return "Kaydediliyor..."
        case .done:    return "Galeriye kaydedildi"
        default:       return "Galeriye Kaydet"
        }
    }

    private func save() async {
        state = .working
        do {
            // Add-only Photos permission (NSPhotoLibraryAddUsageDescription).
            let status = await requestAddAuthorization()
            guard status == .authorized || status == .limited else {
                state = .failed("Galeriye kaydetmek için Fotoğraflar izni gerekli. Ayarlar’dan izin verebilirsin.")
                return
            }

            // Download to a temp file with a sensible extension.
            let (tempURL, _) = try await URLSession.shared.download(from: downloadURL)
            let ext = fileExtension()
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent("downify-\(UUID().uuidString).\(ext)")
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: tempURL, to: dest)
            defer { try? FileManager.default.removeItem(at: dest) }

            let resourceType: PHAssetResourceType = isImageExtension(ext) ? .photo : .video
            try await PHPhotoLibrary.shared().performChanges {
                let req = PHAssetCreationRequest.forAsset()
                req.addResource(with: resourceType, fileURL: dest, options: nil)
            }
            state = .done
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func requestAddAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { cont in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { cont.resume(returning: $0) }
        }
    }

    private func fileExtension() -> String {
        let fromName = (filename as NSString).pathExtension
        if !fromName.isEmpty { return fromName }
        let fromURL = downloadURL.pathExtension
        if !fromURL.isEmpty { return fromURL }
        return "mp4"
    }

    private func isImageExtension(_ ext: String) -> Bool {
        ["jpg", "jpeg", "png", "heic", "heif", "gif", "webp", "tiff"].contains(ext.lowercased())
    }
}
