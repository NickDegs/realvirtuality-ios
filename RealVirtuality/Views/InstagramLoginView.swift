import SwiftUI
import WebKit

struct InstagramLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false
    @State private var saved = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                InstagramWebView { cookies in
                    Task { await saveCookies(cookies) }
                }
                if isSaving {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("Kaydediliyor...")
                        .padding(24)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                }
            }
            .navigationTitle("Instagram Girişi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }
                }
            }
            .alert("Başarılı!", isPresented: $saved) {
                Button("Tamam") { dismiss() }
            } message: {
                Text("Instagram oturumunuz kaydedildi. Artık özel içerikleri indirebilirsiniz.")
            }
            .alert("Hata", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Tamam") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func saveCookies(_ cookies: String) async {
        isSaving = true
        do {
            try await APIService.shared.saveInstagramSession(cookies: cookies)
            saved = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

struct InstagramWebView: UIViewRepresentable {
    let onCookiesExtracted: (String) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.navigationDelegate = context.coordinator
        let url = URL(string: "https://www.instagram.com/accounts/login/")!
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCookiesExtracted: onCookiesExtracted)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let onCookiesExtracted: (String) -> Void

        init(onCookiesExtracted: @escaping (String) -> Void) {
            self.onCookiesExtracted = onCookiesExtracted
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let urlStr = webView.url?.absoluteString,
                  urlStr.contains("instagram.com"),
                  !urlStr.contains("login"),
                  !urlStr.contains("accounts") else { return }

            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                let instagramCookies = cookies
                    .filter { $0.domain.contains("instagram.com") }
                    .map { "\($0.name)=\($0.value)" }
                    .joined(separator: "; ")
                guard !instagramCookies.isEmpty else { return }
                DispatchQueue.main.async {
                    self.onCookiesExtracted(instagramCookies)
                }
            }
        }
    }
}
