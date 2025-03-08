import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var eventTap: CFMachPort?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("✅ Aplikácia spustená na pozadí.")

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        eventTap = CGEvent.tapCreate(tap: .cghidEventTap,
                                     place: .headInsertEventTap,
                                     options: .defaultTap,
                                     eventsOfInterest: mask,
                                     callback: { _, type, event, _ -> Unmanaged<CGEvent>? in
            if type == .keyDown {
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let flags = event.flags

                if flags.contains(.maskControl) && keyCode == 8 { // 8 = C
                    print("📝 Stlačené: Control + C")
                    AppDelegate.copySelectedText()
                    return nil // Zablokuje pôvodnú akciu
                }
            }
            return Unmanaged.passRetained(event)
        }, userInfo: nil)

        if let eventTap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        } else {
            print("❌ Nepodarilo sa vytvoriť Event Tap.")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        eventTap = nil
    }

    static func copySelectedText() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let copiedText = pasteboard.string(forType: .string), !copiedText.isEmpty {
                print("📋 Skopírovaný text: \(copiedText)")
            } else {
                print("⚠️ Nepodarilo sa získať text.")
            }
        }
    }
}
