import Cocoa

/// Trieda zodpovedná za sledovanie klávesových skratiek v systéme.
/// Aktuálne sleduje `Control + C` a pri jeho stlačení volá `ClipboardManager`.
class KeyboardManager {
    /// Mach port na zachytávanie globálnych klávesových vstupov
    private var eventTap: CFMachPort?

    /// Správca schránky
    private let clipboardManager = ClipboardManager()

    /// Inicializácia sledovania klávesových vstupov
    init() {
        setupEventTap()
    }

    /// Nastavenie `Event Tap` na zachytávanie stlačených klávesov
    private func setupEventTap() {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)

        eventTap = CGEvent.tapCreate(tap: .cghidEventTap,
                                     place: .headInsertEventTap,
                                     options: .defaultTap,
                                     eventsOfInterest: mask,
                                     callback: { _, type, event, _ -> Unmanaged<CGEvent>? in
            guard type == .keyDown else { return Unmanaged.passRetained(event) }

            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags

            // Kontrola, či bolo stlačené Control + C
            if flags.contains(.maskControl) && keyCode == 8 { // 8 = C
                print("📝 Stlačené: Control + C")
                ClipboardManager.shared.copySelectedText()
                return nil // Zablokuje pôvodnú akciu
            }

            return Unmanaged.passRetained(event)
        }, userInfo: nil)

        // Overenie, či sa podarilo vytvoriť Event Tap
        if let eventTap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        } else {
            print("❌ Nepodarilo sa vytvoriť Event Tap.")
        }
    }

    /// Deštruktor - uvoľnenie Event Tap pri ukončení aplikácie
    deinit {
        eventTap = nil
    }
}
