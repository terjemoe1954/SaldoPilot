import SwiftUI

struct CategoryFormView: View {
    @Environment(\.dismiss) private var dismiss
    let title: LocalizedStringKey
    let onSave: (String, String, String, Bool) -> Void
    @State private var name: String
    @State private var systemImage: String
    @State private var colorName: String
    @State private var excludesFromSavingsTips: Bool

    private let icons = ["tag", "house", "cart", "car", "fork.knife", "heart", "gift", "banknote", "briefcase", "pawprint", "airplane", "figure.run"]
    private let colors = ["blue", "green", "orange", "red", "purple", "pink", "teal", "cyan", "indigo", "brown", "gray", "black"]

    init(title: LocalizedStringKey, name: String = "", systemImage: String = "tag", colorName: String = "blue", excludesFromSavingsTips: Bool = false, onSave: @escaping (String, String, String, Bool) -> Void) {
        self.title = title
        self.onSave = onSave
        _name = State(initialValue: name)
        _systemImage = State(initialValue: systemImage)
        _colorName = State(initialValue: colorName)
        _excludesFromSavingsTips = State(initialValue: excludesFromSavingsTips)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") { TextField("Category name", text: $name) }
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))]) {
                        ForEach(icons, id: \.self) { icon in
                            Button { systemImage = icon } label: {
                                Image(systemName: icon)
                                    .frame(width: 42, height: 42)
                                    .background(systemImage == icon ? Color.accentColor.opacity(0.18) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Section {
                    Toggle("Exclude from savings tips", isOn: $excludesFromSavingsTips)
                } footer: {
                    Text("This category will still appear in totals and budgets, but will not be suggested as a place to cut spending.")
                }
                Section("Color") {
                    Picker("Color", selection: $colorName) {
                        ForEach(colors, id: \.self) { Text($0.capitalized).tag($0) }
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), systemImage, colorName, excludesFromSavingsTips)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
