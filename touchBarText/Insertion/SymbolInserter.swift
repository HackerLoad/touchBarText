import Foundation
import CoreGraphics

enum SymbolInserter {
    static func insert(_ string: String) {
        guard !string.isEmpty else { return }

        let source = CGEventSource(stateID: .combinedSessionState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
            NSLog("touchBarText: Konnte CGEvent für Symbol-Insertion nicht erzeugen.")
            return
        }

        let utf16 = Array(string.utf16)
        keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
        keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
