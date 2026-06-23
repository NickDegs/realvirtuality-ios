import Foundation

struct Country: Identifiable, Hashable {
    let iso: String      // ISO 3166-1 alpha-2, ör. "TR"
    let name: String     // Yerelleştirilmiş ad
    let dialCode: String // ör. "+90"

    var id: String { iso }

    /// ISO kodundan bayrak emojisi üretir (regional indicator semboller).
    var flag: String {
        iso.unicodeScalars.reduce("") { acc, scalar in
            acc + String(UnicodeScalar(127397 + scalar.value)!)
        }
    }
}

enum Countries {
    /// Cihaz bölgesine göre varsayılan ülke (bulunamazsa Türkiye).
    static var deviceDefault: Country {
        let region = Locale.current.region?.identifier
            ?? Locale.current.language.region?.identifier
        return all.first { $0.iso == region } ?? all.first { $0.iso == "TR" }!
    }

    static let all: [Country] = [
        Country(iso: "TR", name: "Türkiye", dialCode: "+90"),
        Country(iso: "US", name: "United States", dialCode: "+1"),
        Country(iso: "GB", name: "United Kingdom", dialCode: "+44"),
        Country(iso: "DE", name: "Deutschland", dialCode: "+49"),
        Country(iso: "FR", name: "France", dialCode: "+33"),
        Country(iso: "NL", name: "Nederland", dialCode: "+31"),
        Country(iso: "ES", name: "España", dialCode: "+34"),
        Country(iso: "IT", name: "Italia", dialCode: "+39"),
        Country(iso: "PT", name: "Portugal", dialCode: "+351"),
        Country(iso: "BE", name: "Belgique", dialCode: "+32"),
        Country(iso: "CH", name: "Schweiz", dialCode: "+41"),
        Country(iso: "AT", name: "Österreich", dialCode: "+43"),
        Country(iso: "SE", name: "Sverige", dialCode: "+46"),
        Country(iso: "NO", name: "Norge", dialCode: "+47"),
        Country(iso: "DK", name: "Danmark", dialCode: "+45"),
        Country(iso: "FI", name: "Suomi", dialCode: "+358"),
        Country(iso: "IE", name: "Ireland", dialCode: "+353"),
        Country(iso: "PL", name: "Polska", dialCode: "+48"),
        Country(iso: "CZ", name: "Česko", dialCode: "+420"),
        Country(iso: "GR", name: "Ελλάδα", dialCode: "+30"),
        Country(iso: "RO", name: "România", dialCode: "+40"),
        Country(iso: "HU", name: "Magyarország", dialCode: "+36"),
        Country(iso: "UA", name: "Україна", dialCode: "+380"),
        Country(iso: "RU", name: "Россия", dialCode: "+7"),
        Country(iso: "AZ", name: "Azərbaycan", dialCode: "+994"),
        Country(iso: "GE", name: "საქართველო", dialCode: "+995"),
        Country(iso: "CY", name: "Κύπρος", dialCode: "+357"),
        Country(iso: "BG", name: "България", dialCode: "+359"),
        Country(iso: "RS", name: "Srbija", dialCode: "+381"),
        Country(iso: "HR", name: "Hrvatska", dialCode: "+385"),
        Country(iso: "SA", name: "السعودية", dialCode: "+966"),
        Country(iso: "AE", name: "الإمارات", dialCode: "+971"),
        Country(iso: "QA", name: "قطر", dialCode: "+974"),
        Country(iso: "KW", name: "الكويت", dialCode: "+965"),
        Country(iso: "BH", name: "البحرين", dialCode: "+973"),
        Country(iso: "OM", name: "عُمان", dialCode: "+968"),
        Country(iso: "JO", name: "الأردن", dialCode: "+962"),
        Country(iso: "LB", name: "لبنان", dialCode: "+961"),
        Country(iso: "EG", name: "مصر", dialCode: "+20"),
        Country(iso: "MA", name: "المغرب", dialCode: "+212"),
        Country(iso: "DZ", name: "الجزائر", dialCode: "+213"),
        Country(iso: "TN", name: "تونس", dialCode: "+216"),
        Country(iso: "IL", name: "ישראל", dialCode: "+972"),
        Country(iso: "IR", name: "ایران", dialCode: "+98"),
        Country(iso: "IQ", name: "العراق", dialCode: "+964"),
        Country(iso: "PK", name: "Pakistan", dialCode: "+92"),
        Country(iso: "IN", name: "India", dialCode: "+91"),
        Country(iso: "BD", name: "বাংলাদেশ", dialCode: "+880"),
        Country(iso: "LK", name: "Sri Lanka", dialCode: "+94"),
        Country(iso: "CN", name: "中国", dialCode: "+86"),
        Country(iso: "JP", name: "日本", dialCode: "+81"),
        Country(iso: "KR", name: "대한민국", dialCode: "+82"),
        Country(iso: "ID", name: "Indonesia", dialCode: "+62"),
        Country(iso: "MY", name: "Malaysia", dialCode: "+60"),
        Country(iso: "SG", name: "Singapore", dialCode: "+65"),
        Country(iso: "TH", name: "ไทย", dialCode: "+66"),
        Country(iso: "VN", name: "Việt Nam", dialCode: "+84"),
        Country(iso: "PH", name: "Philippines", dialCode: "+63"),
        Country(iso: "AU", name: "Australia", dialCode: "+61"),
        Country(iso: "NZ", name: "New Zealand", dialCode: "+64"),
        Country(iso: "CA", name: "Canada", dialCode: "+1"),
        Country(iso: "MX", name: "México", dialCode: "+52"),
        Country(iso: "BR", name: "Brasil", dialCode: "+55"),
        Country(iso: "AR", name: "Argentina", dialCode: "+54"),
        Country(iso: "CL", name: "Chile", dialCode: "+56"),
        Country(iso: "CO", name: "Colombia", dialCode: "+57"),
        Country(iso: "PE", name: "Perú", dialCode: "+51"),
        Country(iso: "VE", name: "Venezuela", dialCode: "+58"),
        Country(iso: "ZA", name: "South Africa", dialCode: "+27"),
        Country(iso: "NG", name: "Nigeria", dialCode: "+234"),
        Country(iso: "KE", name: "Kenya", dialCode: "+254"),
        Country(iso: "GH", name: "Ghana", dialCode: "+233"),
        Country(iso: "ET", name: "Ethiopia", dialCode: "+251"),
        Country(iso: "KZ", name: "Қазақстан", dialCode: "+7"),
        Country(iso: "UZ", name: "Oʻzbekiston", dialCode: "+998"),
        Country(iso: "TM", name: "Türkmenistan", dialCode: "+993"),
        Country(iso: "KG", name: "Кыргызстан", dialCode: "+996"),
        Country(iso: "TJ", name: "Тоҷикистон", dialCode: "+992"),
    ]
}
