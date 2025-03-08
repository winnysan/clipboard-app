import AppKit

/// Vlastná trieda `NSWindow`, ktorá umožňuje, aby borderless okno mohlo byť hlavné (`key window`).
class CustomWindow: NSWindow {
    /// Umožňuje, aby sa okno stalo hlavné (`key window`).
    override var canBecomeKey: Bool {
        return true
    }
    
    /// Umožňuje, aby sa okno stalo hlavné (`main window`).
    override var canBecomeMain: Bool {
        return true
    }
}
