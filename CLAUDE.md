# Proje Kuralları

## GitHub Actions Versiyon Kuralları (ZORUNLU — crash önleme)

Workflow yazarken YALNIZCA bu versiyonları kullan. Yanlış versiyon = workflow anında crash.

| Action | Doğru | Yanlış |
|---|---|---|
| actions/checkout | @v4 | ~~@v5 @v6~~ |
| actions/setup-java | @v4 | ~~@v5~~ |
| actions/upload-artifact | @v4 | ~~@v5 @v6 @v7~~ |
| actions/download-artifact | @v4 | ~~@v5~~ |
| softprops/action-gh-release | @v2 | ~~@v3~~ |
| subosito/flutter-action | @v2 | — |
| ruby/setup-ruby | @v1 | — |
| r0adkll/upload-google-play | @v1 | — |

Her workflow dosyasına ekle (jobs bloğu üstüne):
```yaml
env:
  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true
```

iOS Codemagic: `xcrun altool` Xcode 16da kaldırıldı.
Upload için `publishing.app_store_connect` bloğunu kullan, manuel altool adımı EKLEME.


## Mobil Uygulama Crash Önleme Kuralları (ZORUNLU — açılınca kapanmasın)

TestFlight/Play Store sonrası uygulama HEMEN kapanıyorsa (startup crash) önce bu listeye bak.

### Capacitor + @capacitor-community/admob + Xcode 26
Belirti: AdMob'lu Capacitor app TestFlight'ta açılınca hemen kapanır.
Kök neden: ConsentExecutor.swift iOS 26 SDK ile uyumsuz → startup crash.
Çözüm — CI workflow'a ekle (build sırasında dosyayı stub ile değiştir, commit etme):
```yaml
- name: AdMob Consent stub (Xcode 26)
  run: |
    F="node_modules/@capacitor-community/admob/ios/Sources/AdMobPlugin/Consent/ConsentExecutor.swift"
    [ -f "$F" ] && printf 'import Foundation; import Capacitor; import GoogleMobileAds\nclass ConsentExecutor: NSObject {\n    weak var plugin: AdMobPlugin?\n    func requestConsentInfo(_ call: CAPPluginCall, _ a: Int, _ b: [String], _ c: Bool) { call.resolve(["status":"NOT_REQUIRED","isConsentFormAvailable":false]) }\n    func showConsentForm(_ call: CAPPluginCall) { call.resolve(["status":"NOT_REQUIRED"]) }\n    func resetConsentInfo(_ call: CAPPluginCall) { call.resolve() }\n}' > "$F"
```

### React Native — @rnmapbox/maps 10.3.x + New Architecture
Belirti: Harita kullanan RN app TestFlight'ta hemen kapanır (RNMBXStyle.swift bridge! crash).
Çözüm:
  - package.json: "@rnmapbox/maps": "10.2.10"  (10.3.x DEĞİL)
  - app.json: "newArchEnabled": false

### React Native — react-native-reanimated sürüm kayması
Çözüm: package.json'da EXACT pin yazılacak: "react-native-reanimated": "3.16.1"  (^ veya ~ yok)

### Flutter — google_mobile_ads v8 consentStatus
v8'de consentStatus getter kaldırıldı → crash.
Çözüm: consentStatus kullanan tüm satırları koddan temizle.

### Genel iOS — IPHONEOS_DEPLOYMENT_TARGET tutarsızlığı
Çözüm (CI'da): sed ile tüm target'larda 16.4 zorla:
  sed -i -E "s/IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;/IPHONEOS_DEPLOYMENT_TARGET = 16.4;/g" ios/App/App.xcodeproj/project.pbxproj
