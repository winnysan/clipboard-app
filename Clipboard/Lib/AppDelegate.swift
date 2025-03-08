import Cocoa

/// Hlavný delegát aplikácie, ktorý inicializuje `KeyboardManager`
class AppDelegate: NSObject, NSApplicationDelegate {
    /// Inštancia `KeyboardManager` na sledovanie klávesových skratiek
    private var keyboardManager: KeyboardManager?

    /// Spustenie aplikácie
    /// - Parameter aNotification: Systémová notifikácia pri štarte aplikácie
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("✅ Aplikácia spustená na pozadí.")
        keyboardManager = KeyboardManager() // Inicializujeme sledovanie klávesov
    }

    /// Ukončenie aplikácie
    /// - Parameter aNotification: Systémová notifikácia pri ukončení aplikácie
    func applicationWillTerminate(_ aNotification: Notification) {
        keyboardManager = nil // Uvoľníme zdroje pri ukončení
    }
}
