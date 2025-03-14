import Cocoa
import Combine

/// Trieda zodpovedná za manipuláciu so schránkou.
/// Obsahuje funkcie na získanie označeného textu, správu histórie kopírovania a výpis vybraného textu.
class ClipboardManager: ObservableObject {
    /// Singleton inštancia triedy
    static let shared = ClipboardManager()

    /// Maximálny počet položiek v histórii
    private let maxHistorySize = 100

    /// História skopírovaných textov (najnovší na začiatku)
    @Published var clipboardHistory: [String] = []

    /// Privátny inicializátor zabraňujúci vytvoreniu ďalších inštancií.
    private init() {}

    /// Skopíruje označený text zo systému, uloží ho do histórie a zobrazí okno aplikácie.
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

        // Po krátkom čase prečítame obsah schránky a uložíme ho do histórie
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let copiedText = pasteboard.string(forType: .string), !copiedText.isEmpty {
                print("📋 Skopírovaný text: \(copiedText)")

                // Odstránime predchádzajúci výskyt a pridáme nový na začiatok
                self.clipboardHistory.removeAll { $0 == copiedText }
                self.clipboardHistory.insert(copiedText, at: 0)

                // Ak história presiahne maximálny počet, odstráni sa najstarší záznam
                if self.clipboardHistory.count > self.maxHistorySize {
                    self.clipboardHistory.removeLast()
                }

                // Ak je povolené "Otvoriť okno pri kopírovaní", zobrazíme ho
                if StatusBarManager.shared.openWindowOnCopy {
                    WindowManager.shared.openWindow()
                }
            } else {
                print("⚠️ Nepodarilo sa získať text.")
            }
        }
    }
    
    /// Vloží zadaný text alebo najnovší text z histórie na miesto kurzora.
    /// - Parameter text: Voliteľný parameter. Ak nie je zadaný, použije sa posledný text z histórie.
    func pasteText(_ text: String? = nil) {
         let pasteboard = NSPasteboard.general
 
         // Ak nie je zadaný text, použijeme posledný text z histórie.
         guard let textToPaste = text ?? clipboardHistory.first else {
            print("⚠️ Nie je k dispozícii žiadny text na vloženie.")
            return
        }

        pasteboard.clearContents()
        pasteboard.setString(textToPaste, forType: .string)

        // Simulácia Cmd + V na vloženie textu
        let source = CGEventSource(stateID: .hidSystemState)
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true) // Command
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // V
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)

        cmdDown?.flags = .maskCommand
        vDown?.flags = .maskCommand
        
        // Uchovanie pôvodného fokusu pred vložením textu.
        WindowManager.shared.preserveFocusBeforeOpening()

        cmdDown?.post(tap: .cghidEventTap)
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
        
        // Obnovenie pôvodného fokusu po vložení textu.
        WindowManager.shared.restorePreviousFocus()

        print("📋 Vložený text: \(textToPaste)")
    }
}
