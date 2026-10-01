import SwiftUI

struct BrutalistChoicePicker<T: Hashable & Identifiable>: View {
    @Binding var selection: T
    let options: [T]
    let label: (T) -> String
    var isDisabled = false

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
            ForEach(options, id: \.id) { option in
                BrutalistChoiceChip(title: label(option), isSelected: selection == option,
                                    isDisabled: isDisabled) {
                    selection = option
                    HapticManager.shared.light()
                }
            }
        }
    }
}
