import Cocoa

/// Trieda na správu systémových oprávnení pre aplikáciu.
/// Obsahuje funkciu na otvorenie nastavení pre Accessibility.
class SystemPermissionManager {
    /// Skontroluje, či má aplikácia povolenie na sledovanie klávesnice.
    /// - Returns: `true`, ak má aplikácia povolenie, inak `false`.
    func hasAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    /// Otvorí systémové nastavenia pre udelenie oprávnenia v **Privacy & Security > Accessibility**.
    func requestAccessibilityPermission() {
        print("🔓 Kontrola oprávnenia na sledovanie klávesnice...")

        if hasAccessibilityPermission() {
            print("✅ Aplikácia už má oprávnenie.")
            return
        }

        print("⚠️ Aplikácia nemá oprávnenie. Otváram systémové nastavenia...")

        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        } else {
            print("❌ Nepodarilo sa otvoriť systémové nastavenia.")
        }
    }
}
