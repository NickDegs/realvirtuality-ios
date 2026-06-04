import SwiftUI

@main
struct MediafyApp: App {
    @StateObject private var authState = AuthState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authState)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "mediafy" else { return }
        switch url.host {
        case "payment":
            let success = url.pathComponents.contains("success")
            NotificationCenter.default.post(name: .paymentResult, object: success)
        case "share":
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let urlParam = components.queryItems?.first(where: { $0.name == "url" })?.value {
                NotificationCenter.default.post(name: .startDownloadFromShare, object: urlParam)
            }
        default:
            break
        }
    }
}

extension Notification.Name {
    static let paymentResult = Notification.Name("rv.paymentResult")
    static let startDownloadFromShare = Notification.Name("rv.startDownloadFromShare")
    static let showSubscription = Notification.Name("rv.showSubscription")
}
