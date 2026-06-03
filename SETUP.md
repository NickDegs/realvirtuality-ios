# Real Virtuality — Xcode Kurulum Kılavuzu

## Gereksinimler
- macOS 13.0+
- Xcode 15.0+
- Apple Developer hesabı (yıllık $99)
- iOS 16.0+ cihaz veya simülatör

---

## 1. Xcode'da Yeni Proje Oluştur

1. Xcode → **File → New → Project**
2. **iOS → App** seç
3. Ayarlar:
   - **Product Name**: `RealVirtuality`
   - **Bundle Identifier**: `app.realvirtuality`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Minimum Deployments**: iOS 16.0
4. Projeyi kaydet

---

## 2. Dosyaları Ekle

Xcode'da proje navigatöründe `RealVirtuality` grubuna sağ tıkla → **Add Files to "RealVirtuality"**:

```
RealVirtuality/
├── Models/
│   └── Models.swift
├── Services/
│   ├── KeychainService.swift
│   ├── APIService.swift
│   └── AuthState.swift
├── Views/
│   ├── ContentView.swift
│   ├── HomeView.swift
│   ├── DownloadProgressView.swift
│   ├── AuthView.swift
│   ├── AccountView.swift
│   ├── SubscriptionView.swift
│   ├── SettingsView.swift
│   └── InstagramLoginView.swift
├── Resources/
│   ├── tr.lproj/Localizable.strings
│   ├── en.lproj/Localizable.strings
│   ├── es.lproj/Localizable.strings
│   ├── zh.lproj/Localizable.strings
│   ├── ja.lproj/Localizable.strings
│   ├── ko.lproj/Localizable.strings
│   ├── en-GB.lproj/Localizable.strings
│   ├── az.lproj/Localizable.strings
│   └── kk.lproj/Localizable.strings
└── RealVirtualityApp.swift
```

> Xcode tarafından oluşturulan `ContentView.swift`'i sil, kendi dosyanla değiştir.

---

## 3. Share Extension Ekle

1. **File → New → Target** → **Share Extension**
2. **Product Name**: `ShareExtension`
3. `ShareExtension/` klasöründeki dosyaları hedefe ekle:
   - `ShareViewController.swift` — var olanı sil, dosyayı kopyala
   - `Info.plist` — var olanı değiştir

---

## 4. Info.plist Ayarları

Ana uygulama `Info.plist`'ini sil, bu repodan kopyala. Veya mevcut dosyaya şunu ekle:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>realvirtuality</string>
        </array>
    </dict>
</array>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Videolar ve görseller fotoğraf kütüphanenize kaydedilecek.</string>
```

---

## 5. Entitlements (Keychain + App Group)

1. **Signing & Capabilities** sekmesini aç
2. Ana uygulama için:
   - **+ Capability → Keychain Sharing** ekle
     - Grup: `app.realvirtuality`
   - **+ Capability → App Groups** ekle
     - Grup: `group.app.realvirtuality`
3. ShareExtension için:
   - Aynı App Groups'u ekle: `group.app.realvirtuality`

> `RealVirtuality.entitlements` dosyası otomatik oluşur; doğru değerler için repo dosyasıyla karşılaştır.

---

## 6. Bundle ID & İmzalama

**Project Navigator → RealVirtuality (proje) → Targets:**

| Target | Bundle Identifier |
|--------|-------------------|
| RealVirtuality | `app.realvirtuality` |
| ShareExtension | `app.realvirtuality.share` |

- **Signing Team**: Apple Developer hesabını seç
- **Automatically manage signing**: ✓

---

## 7. Derleme ve Test

```bash
# Simülatörde test
Xcode → Product → Run (⌘R)

# Cihazda test
Cihazı bağla → Scheme menüsünden cihazı seç → Run
```

---

## 8. App Store Connect

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **Apps → +**
2. Bilgiler:
   - **Name**: Real Virtuality
   - **Bundle ID**: `app.realvirtuality`
   - **SKU**: `realvirtuality001`
   - **Primary Language**: Turkish
3. Gerekli URL'ler:
   - **Privacy Policy**: `https://realvirtuality.app/privacy`
   - **Support URL**: `https://realvirtuality.app/support`
   - **Marketing URL**: `https://realvirtuality.app`

---

## 9. Backend Kurulumu (RapidSeedbox)

SSH ile VPS'e bağlan:
```bash
ssh user@your-vps-ip
```

Backend dosyalarını yükle ve çalıştır:
```bash
cd mediadrop-backend/
chmod +x install.sh
./install.sh
```

`.env` dosyasını düzenle:
```env
SECRET_KEY=gizli-jwt-anahtari-buraya
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

---

## 10. Stripe Yapılandırması

[Stripe Dashboard](https://dashboard.stripe.com) → Webhooks:
- Endpoint URL: `https://api.realvirtuality.app/subscription/webhook`
- Events:
  - `checkout.session.completed`
  - `customer.subscription.deleted`

Success URL: `realvirtuality://payment/success`
Cancel URL: `realvirtuality://payment/cancel`

---

## Abonelik Planları

| Plan ID | Açıklama | Fiyat |
|---------|----------|-------|
| `ad_free` | Reklamsız | $3 tek seferlik |
| `full_monthly` | Full Aylık | $5/ay |
| `full_yearly` | Full Yıllık | $30/yıl |
| `full_lifetime` | Ömür Boyu | $50 tek seferlik |

---

## Notlar

- Sıfır üçüncü parti bağımlılık — SPM/CocoaPods kullanılmamıştır
- Stripe ödemesi SFSafariViewController ile hosted checkout kullanır
- Share Extension → Uygulama iletişimi: `realvirtuality://share?url=<encoded>`
- Keychain paylaşımı: `app.realvirtuality` grubu (hem uygulama hem extension erişir)
