import Foundation

/// Správa nákupov v aplikácii (In-App Purchase).
/// Zatiaľ obsahuje iba testovaciu hodnotu, neskôr bude nahradená reálnou StoreKit logikou.
class PurchaseManager {
    static let shared = PurchaseManager()

    /// Príznak, či používateľ odomkol Pro verziu (platí jednorazový nákup).
    /// Tento flag bude neskôr nahradený reálnou validáciou cez StoreKit.
    var isProUnlocked: Bool {
        return false // <- nastavené na `true` počas vývoja
    }

    private init() {}
}
