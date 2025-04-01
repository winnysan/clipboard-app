import SwiftUI

/// Správca pre okno s nákupom PRO verzie.
/// Využíva jednotnú základňu `BaseWindowManager` pre vzhľad a ovládanie.
class PurchaseWindowManager: BaseWindowManager {
    /// Zdieľaná singleton inštancia.
    static let shared = PurchaseWindowManager()

    /// Privátny inicializátor nastavuje veľkosť okna a inicializuje základný správca.
    private init() {
        super.init(size: NSSize(width: 300, height: 400))
    }

    /// Zobrazí okno s nákupom PRO verzie.
    func showWindow() {
        show { [weak self] close in
            PurchaseView(onClose: {
                self?.forceClose() // Zavolá metódu forceClose() z BaseWindowManager
            })
        }
    }
}
