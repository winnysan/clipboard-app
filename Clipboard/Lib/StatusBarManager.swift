import AppKit

/// Správa ikonky na stavovej lište aplikácie.
/// Umožňuje interakciu s aplikáciou cez ikonku v `NSStatusBar`.
class StatusBarManager {
    /// Singleton inštancia pre správu stavovej lišty.
    static let shared = StatusBarManager()
    
    /// Referencia na položku stavovej lišty.
    private var statusItem: NSStatusItem?

    /// Privátny inicializátor zabraňujúci vytvoreniu ďalších inštancií.
    private init() {}

    /// Inicializuje ikonku v stavovej lište a nastaví akcie.
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clipboard")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
    }
    
    /// Akcia pri kliknutí na ikonku stavovej lišty - zobrazí alebo skryje okno aplikácie.
    @objc private func statusBarButtonClicked() {
        WindowManager.shared.toggleWindow()
    }
}
