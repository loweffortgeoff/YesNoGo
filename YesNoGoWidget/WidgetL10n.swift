import Foundation

enum WidgetL10n {
    static func string(_ key: String, fallback: String, comment: String = "") -> String {
        NSLocalizedString(key, bundle: .main, value: fallback, comment: comment)
    }

    static func format(_ key: String, fallback: String, _ arguments: CVarArg..., comment: String = "") -> String {
        let format = string(key, fallback: fallback, comment: comment)
        return String(format: format, locale: Locale.current, arguments: arguments)
    }
}
