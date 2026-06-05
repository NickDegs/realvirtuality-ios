import SwiftUI
import AppTrackingTransparency

// AdMob SDK import — etkinleştirildiğinde uncomment:
// import GoogleMobileAds
// import UserMessagingPlatform

class AdManager: ObservableObject {
    static let shared = AdManager()

    // Test reklam birimi ID'leri (gerçek hesap gelince değiştirilecek)
    static let bannerAdUnitID       = "ca-app-pub-3940256099942544/2934735716"
    static let interstitialAdUnitID = "ca-app-pub-3940256099942544/1033173712"
    static let rewardedAdUnitID     = "ca-app-pub-3940256099942544/5224354917"

    @Published var attStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    @Published var consentObtained = false

    private init() {}

    /// Uygulama açılışında çağır — önce UMP consent, sonra ATT, sonra SDK başlat
    func initialize() {
        requestUMPConsent { [weak self] in
            self?.requestATT { [weak self] in
                self?.startAdSDK()
            }
        }
    }

    private func requestUMPConsent(completion: @escaping () -> Void) {
        // Google UMP — GDPR/EEA consent
        // SDK eklenince aşağıdakini aktif et:
        //
        // let params = UMPRequestParameters()
        // params.tagForUnderAgeOfConsent = false
        // UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: params) { error in
        //     guard error == nil else { completion(); return }
        //     let formStatus = UMPConsentInformation.sharedInstance.formStatus
        //     if formStatus == .available {
        //         UMPConsentForm.loadAndPresentIfRequired(from: nil) { _ in
        //             completion()
        //         }
        //     } else {
        //         completion()
        //     }
        // }
        consentObtained = true
        completion()
    }

    private func requestATT(completion: @escaping () -> Void) {
        guard #available(iOS 14, *) else { completion(); return }
        // iOS 26 uyumlu: MainActor üzerinde göster
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    self.attStatus = status
                    completion()
                }
            }
        }
    }

    private func startAdSDK() {
        // GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
}
