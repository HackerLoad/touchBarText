import AppKit
import SwiftUI

final class HotkeyPanelController {
    static let shared = HotkeyPanelController()

    private let hotkeyManager = HotkeyManager()
    private let viewModel: SymbolPickerViewModel
    private let panel: HotkeyPanel

    private init() {
        viewModel = SymbolPickerViewModel(categories: SymbolStore.shared.categories)

        let hostingView = NSHostingView(rootView: SymbolPickerView(viewModel: viewModel))
        hostingView.frame = NSRect(x: 0, y: 0, width: 340, height: 220)

        let panel = HotkeyPanel(
            contentRect: hostingView.frame,
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView, .hudWindow],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.contentView = hostingView
        self.panel = panel

        viewModel.onCommit = { [weak self] symbol in
            self?.hide()
            // Erst nach dem Schließen einfügen: Solange das (nonactivating) Panel
            // noch Key Window ist, würde der synthetische Tastendruck im Panel
            // selbst landen statt im zuvor fokussierten Textfeld der anderen App.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                SymbolInserter.insert(symbol)
            }
        }
        viewModel.onCancel = { [weak self] in
            self?.hide()
        }

        panel.onArrowKey = { [weak self] key in
            guard let self else { return }
            switch key {
            case .upArrow: self.viewModel.moveCategory(by: -1)
            case .downArrow: self.viewModel.moveCategory(by: 1)
            case .leftArrow: self.viewModel.moveSymbol(by: -1)
            case .rightArrow: self.viewModel.moveSymbol(by: 1)
            default: break
            }
        }
        panel.onCommit = { [weak self] in
            self?.viewModel.commitSelection()
        }
        panel.onCancel = { [weak self] in
            self?.hide()
        }

        hotkeyManager.onHotkey = { [weak self] in
            self?.toggle()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(symbolStoreDidReload),
            name: .symbolStoreDidReload,
            object: nil
        )
    }

    func activate() {
        hotkeyManager.register()
    }

    private func toggle() {
        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    private func show() {
        viewModel.categories = SymbolStore.shared.categories
        viewModel.reset()

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let origin = NSPoint(
                x: screenFrame.midX - panel.frame.width / 2,
                y: screenFrame.midY - panel.frame.height / 2
            )
            panel.setFrameOrigin(origin)
        }

        panel.makeKeyAndOrderFront(nil)
    }

    private func hide() {
        panel.orderOut(nil)
    }

    @objc private func symbolStoreDidReload() {
        viewModel.categories = SymbolStore.shared.categories
        viewModel.reset()
    }
}
