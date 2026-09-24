import AppKit

final class StatusItemController: NSObject, NSMenuDelegate {
    static let shared = StatusItemController()

    private var statusItem: NSStatusItem?

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "textformat.abc",
            accessibilityDescription: "touchBarText"
        )

        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let permissionItem = NSMenuItem(
            title: "Bedienungshilfen prüfen",
            action: #selector(checkAccessibilityPermission),
            keyEquivalent: ""
        )
        permissionItem.target = self
        menu.addItem(permissionItem)

        menu.addItem(.separator())

        let testInsertItem = NSMenuItem(
            title: "Test: → einfügen",
            action: #selector(testInsertArrow),
            keyEquivalent: ""
        )
        testInsertItem.target = self
        menu.addItem(testInsertItem)

        menu.addItem(.separator())

        let openConfigItem = NSMenuItem(
            title: "Konfiguration öffnen",
            action: #selector(openConfiguration),
            keyEquivalent: ""
        )
        openConfigItem.target = self
        menu.addItem(openConfigItem)

        let reloadConfigItem = NSMenuItem(
            title: "Konfiguration neu laden",
            action: #selector(reloadConfiguration),
            keyEquivalent: ""
        )
        reloadConfigItem.target = self
        menu.addItem(reloadConfigItem)

        if let error = SymbolStore.shared.lastLoadError {
            let errorItem = NSMenuItem(
                title: "⚠️ Fehler beim Laden der Konfiguration: \(error)",
                action: nil,
                keyEquivalent: ""
            )
            errorItem.isEnabled = false
            menu.addItem(errorItem)
        }

        if LoginItemManager.isSupported {
            let loginItem = NSMenuItem(
                title: "Bei Anmeldung starten",
                action: #selector(toggleLoginItem),
                keyEquivalent: ""
            )
            loginItem.target = self
            loginItem.state = LoginItemManager.isEnabled ? .on : .off
            menu.addItem(loginItem)
        }

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Beenden",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)
    }

    @objc private func checkAccessibilityPermission() {
        let trusted = AccessibilityPermission.isTrusted(promptIfNeeded: true)
        let alert = NSAlert()
        alert.messageText = trusted ? "Bedienungshilfen: erteilt" : "Bedienungshilfen: fehlt"
        alert.informativeText = trusted
            ? "touchBarText darf Symbole in andere Apps einfügen."
            : "Bitte in Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen die App aktivieren."
        alert.alertStyle = trusted ? .informational : .warning
        alert.runModal()
    }

    @objc private func testInsertArrow() {
        SymbolInserter.insert("→")
    }

    @objc private func openConfiguration() {
        SymbolStore.shared.revealInFinder()
    }

    @objc private func reloadConfiguration() {
        SymbolStore.shared.reload()
    }

    @objc private func toggleLoginItem() {
        LoginItemManager.setEnabled(!LoginItemManager.isEnabled)
    }
}
