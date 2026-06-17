import SwiftUI

// MARK: - Editorial design language
// Quiet, formal, high-contrast. Restrained warm-neutral palette + a single accent.
// No emoji anywhere in the UI; SF Symbols only.

enum Theme {
    /// Single restrained accent (warm ochre). Replaces the old playful purple tint.
    static let accent = Color(red: 0.61, green: 0.42, blue: 0.25)      // #9C6B3F
    static let ink = Color(red: 0.11, green: 0.106, blue: 0.098)       // #1C1B19
    static let paper = Color(red: 0.957, green: 0.945, blue: 0.918)    // #F4F1EA
    static let muted = Color(red: 0.43, green: 0.416, blue: 0.384)     // #6E6A62
    static let secure = Color(red: 0.353, green: 0.459, blue: 0.380)   // #5A7561
}

// MARK: - User-selectable font (premium feature)
// Built on SwiftUI's Font.Design so it works across every language/script
// (Latin, Cyrillic, CJK, Arabic, Devanagari) without bundling font files.
// "System" is the free default and follows the iOS system language/script.

enum AppFontStyle: String, CaseIterable, Identifiable {
    case system      // free / default
    case serif       // Editorial
    case rounded
    case monospaced

    var id: String { rawValue }

    /// Whether this style requires a Full (paid) subscription.
    var isPremium: Bool { self != .system }

    var design: Font.Design {
        switch self {
        case .system:     return .default
        case .serif:      return .serif
        case .rounded:    return .rounded
        case .monospaced: return .monospaced
        }
    }

    /// Localized display name (auto-translated via Localizable.strings).
    var titleKey: LocalizedStringKey {
        switch self {
        case .system:     return "Sistem (Varsayılan)"
        case .serif:      return "Editorial (Serif)"
        case .rounded:    return "Yuvarlak"
        case .monospaced: return "Daktilo"
        }
    }
}

// MARK: - Font manager
// Persists the user's choice. Defaults to .system so the app follows the
// iOS 26 system language/font out of the box.

final class FontManager: ObservableObject {
    @AppStorage("appFontStyle") private var stored: String = AppFontStyle.system.rawValue

    var style: AppFontStyle {
        get { AppFontStyle(rawValue: stored) ?? .system }
        set { stored = newValue.rawValue; objectWillChange.send() }
    }

    var design: Font.Design { style.design }
}
