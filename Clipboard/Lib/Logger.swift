import os

/// Definuje rôzne úrovne logovania
enum LogLevel {
    case debug
    case info
    case warning
    case error
}

/// Funkcia na efektívne logovanie.
/// V debug režime loguje všetko, v release len kritické chyby.
/// - Parameters:
///   - message: Správa, ktorá sa má zalogovať.
///   - level: Úroveň logovania (`.debug`, `.info`, `.warning`, `.error`).
func appLog(_ message: String, level: LogLevel = .debug) {
    #if DEBUG
        print("[\(level)] \(message)") // V debug režime logujeme všetko
    #else
        if level == .error || level == .warning {
            let log = OSLog(subsystem: "com.yourcompany.Clipboard", category: "critical")
            os_log("%{public}@", log: log, type: .error, message)
        }
    #endif
}
