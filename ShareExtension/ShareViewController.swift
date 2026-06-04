import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        extractURL()
    }

    private func extractURL() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            close()
            return
        }

        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] item, _ in
                    if let url = item as? URL {
                        self?.openMainApp(with: url.absoluteString)
                    } else {
                        self?.close()
                    }
                }
                return
            }

            if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] item, _ in
                    if let text = item as? String, let url = self?.firstURL(in: text) {
                        self?.openMainApp(with: url)
                    } else {
                        self?.close()
                    }
                }
                return
            }
        }
        close()
    }

    private func firstURL(in text: String) -> String? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        return detector?.matches(in: text, range: NSRange(text.startIndex..., in: text)).first?.url?.absoluteString
    }

    private func openMainApp(with urlString: String) {
        guard let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let appURL = URL(string: "mediafy://share?url=\(encoded)") else {
            close()
            return
        }
        var responder: UIResponder? = self
        while let next = responder {
            if let app = next as? UIApplication {
                app.open(appURL)
                break
            }
            responder = next.next
        }
        close()
    }

    private func close() {
        DispatchQueue.main.async {
            self.extensionContext?.completeRequest(returningItems: nil)
        }
    }
}
