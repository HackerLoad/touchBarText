import Foundation
import AppKit

extension Notification.Name {
    static let symbolStoreDidReload = Notification.Name("touchBarText.symbolStoreDidReload")
}

final class SymbolStore {
    static let shared = SymbolStore()

    private(set) var categories: [SymbolCategory] = []
    private(set) var lastLoadError: String?

    private let fileURL: URL

    static let defaultCategories: [SymbolCategory] = [
        SymbolCategory(name: "Pfeile", symbols: ["→", "←", "↑", "↓", "↔", "↕", "⇒", "⇐", "⇔", "↗", "↘", "↩", "⟶"]),
        SymbolCategory(name: "Typografie", symbols: ["–", "—", "…", "•", "·", "„", "\u{201C}", "‚", "\u{2018}", "«", "»", "‹", "›", "§", "¶", "†"]),
        SymbolCategory(name: "Mathe", symbols: ["×", "÷", "±", "≈", "≠", "≤", "≥", "∞", "√", "∑", "°", "‰", "²", "³", "½"]),
        SymbolCategory(name: "Sonstiges", symbols: ["✓", "✗", "★", "☆", "⌘", "⌥", "⇧", "⌃", "⏎", "⌫", "€", "™", "©", "®"])
    ]

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "touchBarText"
        let dir = appSupport.appendingPathComponent(appName, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("symbols.json")
        load()
    }

    func load() {
        do {
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                try writeDefaultFile()
            }
            let data = try Data(contentsOf: fileURL)
            categories = try JSONDecoder().decode([SymbolCategory].self, from: data)
            lastLoadError = nil
        } catch {
            lastLoadError = error.localizedDescription
            NSLog("touchBarText: Fehler beim Laden von symbols.json (\(fileURL.path)): \(error). Nutze Standardwerte.")
            categories = Self.defaultCategories
        }
    }

    func reload() {
        load()
        NotificationCenter.default.post(name: .symbolStoreDidReload, object: self)
    }

    func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }

    private func writeDefaultFile() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(Self.defaultCategories)
        try data.write(to: fileURL)
    }
}
