import AppKit

/// Vlastná trieda `NSWindow`, ktorá definuje správanie plávajúceho okna bez preberania fokusu.
class CustomWindow: NSWindow {
    /// Zabraňuje, aby sa okno stalo hlavným (`key window`).
    override var canBecomeKey: Bool {
        return false
    }
    
    /// Umožňuje, aby sa okno stalo hlavné (`main window`).
    override var canBecomeMain: Bool {
        return false
    }
    
    /// Zobrazenie okna bez jeho aktivácie ako hlavného.
    /// - Parameter sender: Objekt, ktorý volá túto metódu.
    override func makeKeyAndOrderFront(_ sender: Any?) {
        // Umožní zobrazenie okna, ale neaktivuje ho ako hlavné
        super.orderFront(sender)
    }
}
