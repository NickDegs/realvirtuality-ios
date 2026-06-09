import SwiftUI
import AppTrackingTransparency
import GoogleMobileAds

class AdManager: ObservableObject {
    static let shared = AdManager()

    static let bannerAdUnitID       = "ca-app-pub-3940256099942544/2934735716"
    static let interstitialAdUnitID = "ca-app-pub-3940256099942544/1033173712"
    static let rewardedAdUnitID     = "ca-app-pub-3940256099942544/5224354917"

    @Published var attStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    @Published var consentObtained = false

    private var isInitialized = false
    private init() {}

    func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            GADMobileAds.sharedInstance().start { [weak self] _ in
                DispatchQueue.main.async {
                    self?.consentObtained = true
                    self?.requestATT()
                }
            }
        }
    }

    private func requestATT() {
        guard #available(iOS 14, *) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async { self.attStatus = status }
            }
        }
    }
}
