import SwiftUI
import UIKit

// MARK: - Editorial design language
// Quiet, formal, high-contrast. Restrained warm-neutral palette + a single accent.
// No emoji anywhere in the UI; SF Symbols only.

enum Theme {
    // Adaptive palette: warm editorial in BOTH appearances. Light = cream paper
    // + dark ink (matches App Store screenshots). Dark = warm charcoal + warm
    // off-white, with a brighter gold accent so controls pop on dark.

    /// Single restrained accent (warm ochre / brighter gold in dark).
    static let accent = adaptive(
        light: (0.61, 0.42, 0.25),    // #9C6B3F
        dark:  (0.83, 0.63, 0.37))    // #D4A05E

    static let ink = adaptive(
        light: (0.11, 0.106, 0.098),  // #1C1B19
        dark:  (0.949, 0.933, 0.902)) // #F2EEE6

    static let paper = adaptive(
        light: (0.957, 0.945, 0.918), // #F4F1EA
        dark:  (0.086, 0.078, 0.059)) // #16140F  warm near-black

    static let muted = adaptive(
        light: (0.43, 0.416, 0.384),  // #6E6A62
        dark:  (0.604, 0.580, 0.533)) // #9A9488

    static let secure = adaptive(
        light: (0.353, 0.459, 0.380), // #5A7561
        dark:  (0.498, 0.647, 0.537)) // #7FA589

    /// Builds a colour that resolves per the active light/dark appearance.
    private static func adaptive(light: (Double, Double, Double),
                                 dark: (Double, Double, Double)) -> Color {
        Color(uiColor: UIColor { trait in
            let c = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
    }
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
