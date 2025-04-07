import Cocoa

/// Trieda zodpovedná za sledovanie klávesových skratiek v systéme.
/// Aktuálne sleduje `Control + C`, `Control + V` a `Option + V`.
class KeyboardManager {
    /// Mach port na zachytávanie globálnych klávesových vstupov
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

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

                                         // Ak je stlačené Control + C, skopíruje označený text
                                         if flags.contains(.maskControl), keyCode == 8 { // 8 = C
                                             appLog("📝 Stlačené: Control + C", level: .info)
                                             ClipboardManager.shared.copySelectedText()
                                             return nil // Zablokuje pôvodnú akciu
                                         }

                                         // Ak je stlačené Control + X, vykoná vystrihnutie
                                         if flags.contains(.maskControl), keyCode == 7 { // 7 = X
                                             appLog("✂️ Stlačené: Control + X", level: .info)
                                             ClipboardManager.shared.copySelectedText(cut: true)
                                             return nil // Zablokuje pôvodnú akciu
                                         }

                                         // Ak je stlačené Control + V, vloží posledný skopírovaný text
                                         if flags.contains(.maskControl), keyCode == 9 { // 9 = V
                                             appLog("📋 Stlačené: Control + V", level: .info)
                                             ClipboardManager.shared.paste()
                                             return nil // Zablokuje pôvodnú akciu
                                         }

                                         // Ak je stlačené Option + V, otvorí alebo zatvorí okno aplikácie
                                         if flags.contains(.maskAlternate), keyCode == 9 { // 9 = V
                                             appLog("📜 Stlačené: Option + V", level: .info)
                                             WindowManager.shared.toggleWindow()
                                             return nil // Zablokuje pôvodnú akciu
                                         }

                                         // Ak je stlačené Command + V, len zatvor okno, ak je nastavené
                                         if flags.contains(.maskCommand), keyCode == 9 { // 9 = V
                                             appLog("📋 Stlačené: Cmd + V (len pasívne sledovanie)", level: .debug)

                                             if StatusBarManager.shared.closeWindowOnPaste {
                                                 WindowManager.shared.closeWindow()
                                             }

                                             return Unmanaged.passRetained(event) // Neblokuj akciu!
                                         }

                                         return Unmanaged.passRetained(event)
                                     }, userInfo: nil)

        // Overenie, či sa podarilo vytvoriť Event Tap
        if let eventTap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        } else {
            appLog("❌ Nepodarilo sa vytvoriť Event Tap.", level: .error)
        }
    }

    /// Deaktivuje sledovanie klávesových skratiek
    func disableEventTap() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            appLog("🛑 Event Tap bol deaktivovaný.", level: .info)
        }
    }

    /// Reaktivuje sledovanie klávesových skratiek
    func enableEventTap() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: true)
            appLog("✅ Event Tap bol aktivovaný.", level: .info)
        }
    }

    /// Zničí Event Tap pri strate oprávnenia
    func destroyEventTap() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)

            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }

            CFMachPortInvalidate(eventTap) // ✅ Správne invalidovanie Event Tap
            self.eventTap = nil
            runLoopSource = nil

            appLog("🔻 Event Tap bol úplne odstránený.", level: .info)
        }
    }

    /// Simuluje stlačenie klávesovej skratky Cmd + C (kopírovanie).
    static func simulateCmdC() {
        let source = CGEventSource(stateID: .hidSystemState)
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        let cDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        let cUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)

        cmdDown?.flags = .maskCommand
        cDown?.flags = .maskCommand

        cmdDown?.post(tap: .cghidEventTap)
        cDown?.post(tap: .cghidEventTap)
        cUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)

        appLog("⌨️ Simulovaný Cmd + C", level: .debug)
    }

    /// Simuluje stlačenie klávesovej skratky Cmd + X (vystrihnutie).
    static func simulateCmdX() {
        let source = CGEventSource(stateID: .hidSystemState)
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        let xDown = CGEvent(keyboardEventSource: source, virtualKey: 0x07, keyDown: true)
        let xUp = CGEvent(keyboardEventSource: source, virtualKey: 0x07, keyDown: false)
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)

        cmdDown?.flags = .maskCommand
        xDown?.flags = .maskCommand

        cmdDown?.post(tap: .cghidEventTap)
        xDown?.post(tap: .cghidEventTap)
        xUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)

        appLog("⌨️ Simulovaný Cmd + X", level: .debug)
    }

    /// Deštruktor - uvoľnenie Event Tap pri ukončení aplikácie
    deinit {
        destroyEventTap()
        appLog("🔻 KeyboardManager deinicializovaný.", level: .debug)
    }
}
