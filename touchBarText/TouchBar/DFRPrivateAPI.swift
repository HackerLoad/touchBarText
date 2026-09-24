import Foundation

/// Kapselt den Zugriff auf die private DFRFoundation-API. Seit macOS Big Sur liegt
/// DFRFoundation nur noch im dyld_shared_cache, nicht mehr als linkbare Datei auf der
/// Platte — daher werden die beiden benötigten C-Funktionen zur Laufzeit per dlopen/dlsym
/// aufgelöst, statt das Framework über Framework Search Paths zu linken.
enum DFRPrivateAPI {
    private typealias SetControlStripPresenceFn = @convention(c) (CFString, Bool) -> Void
    private typealias ShowsCloseBoxFn = @convention(c) (Bool) -> Void

    private static let handle: UnsafeMutableRawPointer? = dlopen(
        "/System/Library/PrivateFrameworks/DFRFoundation.framework/DFRFoundation",
        RTLD_NOW
    )

    private static let setControlStripPresenceFn: SetControlStripPresenceFn? = {
        guard let handle, let sym = dlsym(handle, "DFRElementSetControlStripPresenceForIdentifier") else { return nil }
        return unsafeBitCast(sym, to: SetControlStripPresenceFn.self)
    }()

    private static let showsCloseBoxFn: ShowsCloseBoxFn? = {
        guard let handle, let sym = dlsym(handle, "DFRSystemModalShowsCloseBoxWhenFrontMost") else { return nil }
        return unsafeBitCast(sym, to: ShowsCloseBoxFn.self)
    }()

    static var isAvailable: Bool { handle != nil && setControlStripPresenceFn != nil }

    static func setControlStripPresence(identifier: String, present: Bool) {
        guard let fn = setControlStripPresenceFn else {
            NSLog("touchBarText: DFRElementSetControlStripPresenceForIdentifier nicht verfügbar. Control-Strip-Icon deaktiviert.")
            return
        }
        fn(identifier as CFString, present)
    }

    static func setShowsCloseBox(_ show: Bool) {
        guard let fn = showsCloseBoxFn else { return }
        fn(show)
    }
}
