import AppKit

final class TouchBarController: NSObject, NSTouchBarDelegate, NSScrubberDataSource, NSScrubberDelegate {
    static let shared = TouchBarController()

    private let systemTrayIdentifier = NSTouchBarItem.Identifier("com.maxim.touchBarText.systemTray")
    private let categoryPickerIdentifier = NSTouchBarItem.Identifier("com.maxim.touchBarText.categoryPicker")
    private let scrubberIdentifier = NSTouchBarItem.Identifier("com.maxim.touchBarText.scrubber")

    private var systemTrayItem: NSCustomTouchBarItem?
    private var presentedBar: NSTouchBar?
    private var scrubber: NSScrubber?
    private var selectedCategoryIndex = 0

    private var categories: [SymbolCategory] {
        SymbolStore.shared.categories
    }

    func activate() {
        guard DFRPrivateAPI.isAvailable else {
            NSLog("touchBarText: DFRFoundation nicht verfügbar – Control-Strip-Integration wird übersprungen.")
            return
        }
        guard NSTouchBarItem.self.responds(to: #selector(NSTouchBarItem.addSystemTrayItem(_:))) else {
            NSLog("touchBarText: NSTouchBarItem.addSystemTrayItem: nicht verfügbar auf diesem System.")
            return
        }

        let item = NSCustomTouchBarItem(identifier: systemTrayIdentifier)
        let button = NSButton(
            image: NSImage(systemSymbolName: "textformat.abc", accessibilityDescription: "Sonderzeichen") ?? NSImage(),
            target: self,
            action: #selector(presentPicker)
        )
        item.view = button
        systemTrayItem = item

        NSTouchBarItem.addSystemTrayItem(item)
        DFRPrivateAPI.setControlStripPresence(identifier: systemTrayIdentifier.rawValue, present: true)
        DFRPrivateAPI.setShowsCloseBox(true)
    }

    func deactivate() {
        guard let item = systemTrayItem,
              NSTouchBarItem.self.responds(to: #selector(NSTouchBarItem.removeSystemTrayItem(_:))) else { return }
        NSTouchBarItem.removeSystemTrayItem(item)
        systemTrayItem = nil
    }

    @objc private func presentPicker() {
        selectedCategoryIndex = 0

        let bar = NSTouchBar()
        bar.delegate = self
        bar.defaultItemIdentifiers = [categoryPickerIdentifier, scrubberIdentifier]
        presentedBar = bar

        guard NSTouchBar.self.responds(to: #selector(NSTouchBar.presentSystemModalTouchBar(_:systemTrayItemIdentifier:))) else {
            NSLog("touchBarText: presentSystemModalTouchBar:systemTrayItemIdentifier: nicht verfügbar.")
            return
        }
        NSTouchBar.presentSystemModalTouchBar(bar, systemTrayItemIdentifier: systemTrayIdentifier)
    }

    private func dismiss() {
        guard let bar = presentedBar,
              NSTouchBar.self.responds(to: #selector(NSTouchBar.dismissSystemModalTouchBar(_:))) else { return }
        NSTouchBar.dismissSystemModalTouchBar(bar)
        presentedBar = nil

        // Das Präsentieren/Schließen der system-modalen Touch Bar setzt die
        // Control-Strip-Präsenz unseres Icons offenbar zurück – ohne erneutes
        // Setzen verschwindet das Icon nach der ersten Nutzung aus der Control Strip.
        DFRPrivateAPI.setControlStripPresence(identifier: systemTrayIdentifier.rawValue, present: true)
    }

    // MARK: - NSTouchBarDelegate

    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case categoryPickerIdentifier:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let segmented = NSSegmentedControl(
                labels: categories.map(\.name),
                trackingMode: .selectOne,
                target: self,
                action: #selector(categoryChanged(_:))
            )
            segmented.selectedSegment = selectedCategoryIndex
            item.view = segmented
            return item

        case scrubberIdentifier:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let scrubber = NSScrubber()
            scrubber.dataSource = self
            scrubber.delegate = self
            scrubber.mode = .free
            let layout = NSScrubberFlowLayout()
            layout.itemSize = NSSize(width: 40, height: 30)
            scrubber.scrubberLayout = layout
            scrubber.register(NSScrubberTextItemView.self, forItemIdentifier: .symbolItem)
            item.view = scrubber
            self.scrubber = scrubber
            return item

        default:
            return nil
        }
    }

    @objc private func categoryChanged(_ sender: NSSegmentedControl) {
        selectedCategoryIndex = sender.selectedSegment
        scrubber?.reloadData()
    }

    // MARK: - NSScrubberDataSource

    func numberOfItems(for scrubber: NSScrubber) -> Int {
        guard categories.indices.contains(selectedCategoryIndex) else { return 0 }
        return categories[selectedCategoryIndex].symbols.count
    }

    func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
        let itemView = scrubber.makeItem(withIdentifier: .symbolItem, owner: nil) as! NSScrubberTextItemView
        let symbols = categories[selectedCategoryIndex].symbols
        itemView.textField.stringValue = symbols.indices.contains(index) ? symbols[index] : ""
        itemView.textField.font = NSFont.systemFont(ofSize: 18)
        itemView.textField.alignment = .center
        return itemView
    }

    // MARK: - NSScrubberDelegate

    func scrubber(_ scrubber: NSScrubber, didSelectItemAt index: Int) {
        let symbols = categories[selectedCategoryIndex].symbols
        guard symbols.indices.contains(index) else { return }
        SymbolInserter.insert(symbols[index])
        dismiss()
    }
}

private extension NSUserInterfaceItemIdentifier {
    static let symbolItem = NSUserInterfaceItemIdentifier("symbolItem")
}
