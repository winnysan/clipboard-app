import SwiftUI

/// Správca okna "O aplikácii".
/// Používa jednotný vizuálny štýl definovaný v `BaseWindowManager`.
class AboutWindowManager: BaseWindowManager {
    /// Zdieľaná singleton inštancia.
    static let shared = AboutWindowManager()

    /// Privátny inicializátor – nastavuje veľkosť okna.
    private init() {
        super.init(size: NSSize(width: 580, height: 680))
    }

    /// Otvorí okno s informáciami o aplikácii.
    func openWindow() {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        show { _ in
            AboutView(version: appVersion)
        }
    }
}
