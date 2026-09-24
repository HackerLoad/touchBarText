import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        _ = AccessibilityPermission.isTrusted(promptIfNeeded: true)

        _ = SymbolStore.shared

        StatusItemController.shared.install()
        HotkeyPanelController.shared.activate()
        TouchBarController.shared.activate()
    }

    func applicationWillTerminate(_ notification: Notification) {
        TouchBarController.shared.deactivate()
    }
}
