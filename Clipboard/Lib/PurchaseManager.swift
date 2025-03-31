import Foundation

/// Spravuje nákupy v aplikácii (In-App Purchase).
/// Obsahuje len testovaciu implementáciu simulácie nákupu PRO verzie pomocou `UserDefaults`.
/// V budúcnosti bude nahradená plnohodnotnou logikou postavenou na `StoreKit`.
/// - Note: Na resetovanie stavu PRO verzie počas vývoja môžeš použiť nasledujúci príkaz v Termináli:
///   ```bash
///   defaults delete com.yourcompany.Clipboard isProUnlocked
///   ```
class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    private let proKey = "isProUnlocked"

    /// Publikovaná hodnota pre automatickú aktualizáciu UI.
    @Published private(set) var isProUnlocked: Bool

    private init() {
        isProUnlocked = UserDefaults.standard.bool(forKey: proKey)
    }

    func simulatePurchase() {
        UserDefaults.standard.set(true, forKey: proKey)
        isProUnlocked = true
        appLog("✅ PRO verzia bola úspešne aktivovaná (simulácia)", level: .info)
    }
}
