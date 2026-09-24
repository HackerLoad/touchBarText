import Foundation

final class SymbolPickerViewModel: ObservableObject {
    @Published var categories: [SymbolCategory]
    @Published var selectedCategoryIndex: Int = 0
    @Published var selectedSymbolIndex: Int = 0

    var onCommit: ((String) -> Void)?
    var onCancel: (() -> Void)?

    init(categories: [SymbolCategory]) {
        self.categories = categories
    }

    var currentSymbol: String? {
        guard categories.indices.contains(selectedCategoryIndex) else { return nil }
        let symbols = categories[selectedCategoryIndex].symbols
        guard symbols.indices.contains(selectedSymbolIndex) else { return nil }
        return symbols[selectedSymbolIndex]
    }

    func reset() {
        selectedCategoryIndex = 0
        selectedSymbolIndex = 0
    }

    func moveCategory(by delta: Int) {
        guard !categories.isEmpty else { return }
        let count = categories.count
        selectedCategoryIndex = (selectedCategoryIndex + delta + count) % count
        selectedSymbolIndex = 0
    }

    func moveSymbol(by delta: Int) {
        guard categories.indices.contains(selectedCategoryIndex) else { return }
        let symbols = categories[selectedCategoryIndex].symbols
        guard !symbols.isEmpty else { return }
        let count = symbols.count
        selectedSymbolIndex = (selectedSymbolIndex + delta + count) % count
    }

    func selectSymbol(categoryIndex: Int, symbolIndex: Int) {
        selectedCategoryIndex = categoryIndex
        selectedSymbolIndex = symbolIndex
    }

    func commitSelection() {
        guard let symbol = currentSymbol else { return }
        onCommit?(symbol)
    }
}
