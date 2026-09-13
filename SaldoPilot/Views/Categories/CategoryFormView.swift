//
//  CategoryFormView.swift
//  SaldoPilot
//
//  Created by Terje Moe on 13/09/2026.
//

import SwiftData
import SwiftUI

struct CategoryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let category: Category?

    @State private var name: String
    @State private var icon: String
    @State private var colorIdentifier: String

    init(category: Category? = nil) {
        self.category = category
        _name = State(initialValue: category?.name ?? "")
        _icon = State(initialValue: category?.icon ?? CategoryIcon.defaultIcon)
        _colorIdentifier = State(initialValue: category?.colorIdentifier ?? CategoryColor.defaultIdentifier)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)

                    Picker("Icon", selection: $icon) {
                        ForEach(CategoryIcon.options, id: \.self) { icon in
                            Label(CategoryIcon.title(for: icon), systemImage: icon)
                                .tag(icon)
                        }
                    }

                    Picker("Color", selection: $colorIdentifier) {
                        ForEach(CategoryColor.options) { option in
                            HStack {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 14, height: 14)
                                Text(option.title)
                            }
                            .tag(option.id)
                        }
                    }
                }

                Section("Preview") {
                    HStack(spacing: 12) {
                        CategoryIconView(icon: icon, colorIdentifier: colorIdentifier)
                        Text(cleanName.isEmpty ? "Category name" : cleanName)
                            .font(.headline)
                    }
                }
            }
            .navigationTitle(category == nil ? "New category" : "Edit category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(cleanName.isEmpty)
                }
            }
        }
    }

    private var cleanName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        guard !cleanName.isEmpty else { return }

        if let category {
            category.name = cleanName
            category.icon = icon
            category.colorIdentifier = colorIdentifier
        } else {
            let newCategory = Category(
                name: cleanName,
                icon: icon,
                colorIdentifier: colorIdentifier
            )
            modelContext.insert(newCategory)
        }

        dismiss()
    }
}

enum CategoryIcon {
    static let defaultIcon = "tag"

    static let options = [
        "tag",
        "house",
        "bolt",
        "phone",
        "car",
        "cart",
        "repeat",
        "shield",
        "banknote",
        "creditcard",
        "cross.case",
        "gift"
    ]

    static func title(for icon: String) -> LocalizedStringKey {
        switch icon {
        case "house":
            "Housing"
        case "bolt":
            "Power"
        case "phone":
            "Phone"
        case "car":
            "Transport"
        case "cart":
            "Groceries"
        case "repeat":
            "Subscription"
        case "shield":
            "Insurance"
        case "banknote":
            "Salary"
        case "creditcard":
            "Card"
        case "cross.case":
            "Health"
        case "gift":
            "Gift"
        default:
            "Tag"
        }
    }
}

enum CategoryColor {
    static let defaultIdentifier = "blue"

    static let options: [CategoryColorOption] = [
        CategoryColorOption(id: "blue", title: "Blue", color: .blue),
        CategoryColorOption(id: "green", title: "Green", color: .green),
        CategoryColorOption(id: "orange", title: "Orange", color: .orange),
        CategoryColorOption(id: "red", title: "Red", color: .red),
        CategoryColorOption(id: "purple", title: "Purple", color: .purple),
        CategoryColorOption(id: "gray", title: "Gray", color: .gray)
    ]

    static func color(for identifier: String?) -> Color {
        options.first { $0.id == identifier }?.color ?? .blue
    }
}

struct CategoryColorOption: Identifiable {
    let id: String
    let title: LocalizedStringKey
    let color: Color
}

#Preview {
    CategoryFormView()
}
