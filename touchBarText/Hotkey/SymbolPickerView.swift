import SwiftUI

struct SymbolPickerView: View {
    @ObservedObject var viewModel: SymbolPickerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(Array(viewModel.categories.enumerated()), id: \.offset) { index, category in
                    Text(category.name)
                        .font(.system(size: 11, weight: index == viewModel.selectedCategoryIndex ? .bold : .regular))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(index == viewModel.selectedCategoryIndex
                                      ? Color.accentColor.opacity(0.25)
                                      : Color.clear)
                        )
                        .onTapGesture {
                            viewModel.selectSymbol(categoryIndex: index, symbolIndex: 0)
                        }
                }
            }

            let columns = [GridItem(.adaptive(minimum: 34), spacing: 4)]
            ScrollView {
                LazyVGrid(columns: columns, spacing: 4) {
                    if viewModel.categories.indices.contains(viewModel.selectedCategoryIndex) {
                        let symbols = viewModel.categories[viewModel.selectedCategoryIndex].symbols
                        ForEach(Array(symbols.enumerated()), id: \.offset) { index, symbol in
                            Text(symbol)
                                .font(.system(size: 16))
                                .frame(width: 34, height: 30)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(index == viewModel.selectedSymbolIndex
                                              ? Color.accentColor.opacity(0.35)
                                              : Color.gray.opacity(0.12))
                                )
                                .onTapGesture {
                                    viewModel.selectSymbol(categoryIndex: viewModel.selectedCategoryIndex, symbolIndex: index)
                                    viewModel.commitSelection()
                                }
                        }
                    }
                }
            }
            .frame(height: 150)
        }
        .padding(12)
        .frame(width: 340)
    }
}
