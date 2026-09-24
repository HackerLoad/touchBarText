import AppKit

final class HotkeyPanel: NSPanel {
    var onArrowKey: ((NSEvent.SpecialKey) -> Void)?
    var onCommit: (() -> Void)?
    var onCancel: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func keyDown(with event: NSEvent) {
        switch event.specialKey {
        case .some(.upArrow), .some(.downArrow), .some(.leftArrow), .some(.rightArrow):
            onArrowKey?(event.specialKey!)
        case .some(.carriageReturn), .some(.enter):
            onCommit?()
        default:
            if event.keyCode == 53 { // Escape
                onCancel?()
            } else {
                super.keyDown(with: event)
            }
        }
    }
}
