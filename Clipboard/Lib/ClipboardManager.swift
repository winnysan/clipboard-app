import Cocoa

/// Trieda zodpovedná za manipuláciu so schránkou.
/// Obsahuje funkciu na získanie označeného textu.
class ClipboardManager {
    /// Singleton inštancia triedy
    static let shared = ClipboardManager()

    /// Skopíruje označený text zo systému a vypíše ho do konzoly.
    func copySelectedText() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents() // Vymaže schránku pred kopírovaním

        // Simulácia stlačenia Cmd + C na skopírovanie označeného textu
        let source = CGEventSource(stateID: .hidSystemState)
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true) // Command
        let cDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true) // C
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        let cUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)

        cmdDown?.flags = .maskCommand
        cDown?.flags = .maskCommand

        cmdDown?.post(tap: .cghidEventTap)
        cDown?.post(tap: .cghidEventTap)
        cUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)

        // Po krátkom čase prečítame obsah schránky
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let copiedText = pasteboard.string(forType: .string), !copiedText.isEmpty {
                print("📋 Skopírovaný text: \(copiedText)")
            } else {
                print("⚠️ Nepodarilo sa získať text.")
            }
        }
    }
}
