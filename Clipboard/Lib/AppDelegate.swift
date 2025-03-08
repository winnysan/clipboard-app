import Cocoa

/// Hlavný delegát aplikácie, ktorý inicializuje a spravuje jej životný cyklus.
/// Zodpovedá za požiadanie oprávnení, spustenie sledovania klávesových skratiek,
/// inicializáciu hlavného okna aplikácie (`WindowManager`) a správu stavovej lišty (`StatusBarManager`).
class AppDelegate: NSObject, NSApplicationDelegate {
    /// Správca sledovania klávesových skratiek.
    private var keyboardManager: KeyboardManager?

    /// Správca systémových oprávnení.
    private let systemPermissionManager = SystemPermissionManager()

    /// Volá sa pri spustení aplikácie a inicializuje potrebné služby.
    /// - Parameter aNotification: Systémová notifikácia pri štarte aplikácie.
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Inicializácia a konfigurácia hlavného okna aplikácie.
        WindowManager.shared.configureWindow()
        
        // Inicializácia stavovej lišty.
        StatusBarManager.shared.setupStatusBar()
        
        print("✅ Aplikácia spustená na pozadí.")

        // Automaticky požiada používateľa o povolenie spustenia pri štarte, ak nie je nastavené.
        LaunchManager.shared.requestLaunchAtStartup()

        // Požiadavka na oprávnenia pre Accessibility API
        systemPermissionManager.requestAccessibilityPermission()

        // Spustenie sledovania klávesov (iba ak máme oprávnenia)
        if systemPermissionManager.hasAccessibilityPermission() {
            keyboardManager = KeyboardManager()
            print("⌨️ Sledovanie klávesových skratiek bolo spustené.")
        } else {
            print("⚠️ Klávesové skratky nebudú fungovať, kým neudelíte oprávnenie v Nastaveniach.")
        }
    }

    /// Volá sa pri ukončení aplikácie a uvoľňuje zdroje.
    /// - Parameter aNotification: Systémová notifikácia pri ukončení aplikácie.
    func applicationWillTerminate(_ aNotification: Notification) {
        keyboardManager = nil
        print("🚪 Aplikácia bola ukončená.")
    }
}
