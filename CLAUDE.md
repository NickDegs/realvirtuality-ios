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

