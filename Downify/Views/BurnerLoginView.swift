import SwiftUI
import WebKit

// Burner hesapla app içinden giriş → çerezi OTOMATİK yakala → sunucuya burner olarak bağla.
// Kullanıcının ANA hesabı değil; feda-etmelik hesap. Private içerik bu hesapla çözülür.
struct BurnerLoginView: View {
    @State private var platform = "instagram"
    @State private var status = ""
    @State private var busy = false
    @State private var reloadToken = UUID()

    private let platforms = ["instagram", "facebook", "twitter", "youtube", "tiktok"]
    private let loginURL: [String: String] = [
        "instagram": "https://www.instagram.com/accounts/login/",
        "facebook":  "https://m.facebook.com/login/",
        "twitter":   "https://x.com/i/flow/login",
        "youtube":   "https://accounts.google.com/ServiceLogin?service=youtube",
        "tiktok":    "https://www.tiktok.com/login/phone-or-email/email"
    ]
    private let domains: [String: [String]] = [
        "instagram": ["instagram.com"],
        "facebook":  ["facebook.com"],
        "twitter":   ["x.com", "twitter.com"],
        "youtube":   ["google.com", "youtube.com"],
        "tiktok":    ["tiktok.com"]
    ]
    private let apiBase = "https://realvirtuality.app/downify-api"
    private let secret = "YImRtthz9zh_lnd1yYRqKKb8wr_gxJXk"

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $platform) {
                ForEach(platforms, id: \.self) { Text($0.capitalized).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(10)
            .onChange(of: platform) { _ in reloadToken = UUID(); status = "" }

            BurnerWebView(urlString: loginURL[platform] ?? "https://instagram.com", reloadToken: reloadToken)

            VStack(spacing: 8) {
                if !status.isEmpty {
                    Text(status).font(.footnote).multilineTextAlignment(.center)
                        .foregroundStyle(status.hasPrefix("✅") ? .green : (status.hasPrefix("❌") ? .red : .secondary))
                }
                Text("Önce burner hesaba giriş yap, sonra bas. (Ana hesabını kullanma.)")
                    .font(.caption2).foregroundStyle(.secondary)
                Button {
                    captureAndSave()
                } label: {
                    HStack {
                        if busy { ProgressView().tint(.white) }
                        Text("Çerezi Yakala ve Bağla").fontWeight(.semibold)
                    }.frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .controlSize(.large)
                .disabled(busy)
            }
            .padding(12)
        }
        .navigationTitle("Burner Giriş")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func captureAndSave() {
        busy = true; status = "Çerez okunuyor..."
        let wantedDomains = domains[platform] ?? []
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
            let relevant = cookies.filter { c in wantedDomains.contains { c.domain.contains($0) } }
            guard !relevant.isEmpty else {
                DispatchQueue.main.async { busy = false; status = "❌ Çerez yok. Önce giriş yap." }
                return
            }
            var lines = ["# Netscape HTTP Cookie File"]
            for c in relevant {
                let dom = c.domain.hasPrefix(".") ? c.domain : "." + c.domain
                let exp = Int((c.expiresDate ?? Date().addingTimeInterval(86400 * 180)).timeIntervalSince1970)
                let secure = c.isSecure ? "TRUE" : "FALSE"
                lines.append([dom, "TRUE", c.path, secure, String(exp), c.name, c.value].joined(separator: "\t"))
            }
            postBurner(cookies: lines.joined(separator: "\n") + "\n")
        }
    }

    private func postBurner(cookies: String) {
        guard let url = URL(string: "\(apiBase)/burner/\(secret)/cookies") else {
            busy = false; status = "❌ URL hatası"; return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["platform": platform, "cookies": cookies])
        URLSession.shared.dataTask(with: req) { data, resp, _ in
            DispatchQueue.main.async {
                busy = false
                if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                    status = "✅ \(platform.capitalized) bağlandı! Artık bu hesapla private iniyor."
                } else {
                    let msg = (data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }?["detail"] as? String) ?? "Bağlanamadı"
                    status = "❌ \(msg)"
                }
            }
        }.resume()
    }
}

struct BurnerWebView: UIViewRepresentable {
    let urlString: String
    let reloadToken: UUID

    func makeUIView(context: Context) -> WKWebView {
        let wv = WKWebView()
        wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        if let u = URL(string: urlString) { wv.load(URLRequest(url: u)) }
        return wv
    }
    func updateUIView(_ wv: WKWebView, context: Context) {
        if context.coordinator.last != reloadToken {
            context.coordinator.last = reloadToken
            if let u = URL(string: urlString) { wv.load(URLRequest(url: u)) }
        }
    }
    func makeCoordinator() -> Coord { Coord() }
    class Coord { var last: UUID? }
}
