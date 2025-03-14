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
        appLog("🔓 Kontrola oprávnenia na sledovanie klávesnice...", level: .info)

        if hasAccessibilityPermission() {
            appLog("✅ Aplikácia už má požadované oprávnenie.", level: .info)
            return
        }

        appLog("⚠️ Aplikácia nemá oprávnenie. Otváram systémové nastavenia...", level: .warning)

        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        } else {
            appLog("❌ Nepodarilo sa otvoriť systémové nastavenia. Skontrolujte oprávnenia manuálne.", level: .error)
        }
    }
}
