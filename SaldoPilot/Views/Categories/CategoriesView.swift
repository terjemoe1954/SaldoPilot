import SwiftData
import SwiftUI

struct CategoriesView: View {
    @Environment(\.locale) private var locale
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.dueDate) private var transactions: [Transaction]
    @Query(sort: \Budget.monthStart) private var budgets: [Budget]
    @Query(sort: \CategoryDefinition.name) private var definitions: [CategoryDefinition]
    @State private var editedCategory: CategoryOption?
    @State private var isAddingCategory = false
    @State private var deletingCategory: CategoryOption?
    @State private var replacementCategoryID = CategoryKind.other.rawValue
    @State private var saveError = false

    var body: some View {
        List {
            Section("Categories") {
                ForEach(options) { category in
                    CategoryManagementRow(
                        category: category,
                        transactionCount: transactions.filter { $0.categoryID == category.id && !$0.isArchived }.count,
                        budgetCount: budgets.filter { $0.categoryID == category.id }.count
                    )
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            replacementCategoryID = options.first { $0.id != category.id }?.id ?? CategoryKind.other.rawValue
                            deletingCategory = category
                        }
                        Button("Edit") { editedCategory = category }.tint(.blue)
                    }
                }
            }
            Section("About categories") {
                Text("Names, icons and colors can be changed. When deleting a category, its transactions and budgets must be moved to another category first.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            Button { isAddingCategory = true } label: { Label("New category", systemImage: "plus") }
        }
        .sheet(isPresented: $isAddingCategory) {
            CategoryFormView(title: "New category") { name, icon, color in
                modelContext.insert(CategoryDefinition(name: name, systemImage: icon, colorName: color))
                save()
            }
        }
        .sheet(item: $editedCategory) { category in
            CategoryFormView(title: "Edit category", name: category.name, systemImage: category.systemImage, colorName: category.colorName) { name, icon, color in
                saveChanges(to: category, name: name, icon: icon, color: color)
            }
        }
        .sheet(item: $deletingCategory) { category in
            NavigationStack {
                Form {
                    Section {
                        Picker("Move to", selection: $replacementCategoryID) {
                            ForEach(options.filter { $0.id != category.id }) { option in
                                Label(option.name, systemImage: option.systemImage).tag(option.id)
                            }
                        }
                    } footer: {
                        Text("Existing transactions and budgets are moved before the category is removed.")
                    }
                }
                .navigationTitle("Delete category")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { deletingCategory = nil } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Move and delete", role: .destructive) {
                            delete(category, replacingWith: replacementCategoryID)
                            deletingCategory = nil
                        }
                    }
                }
            }
        }
        .alert("Could not save categories", isPresented: $saveError) { Button("OK", role: .cancel) {} }
    }

    private var options: [CategoryOption] { CategoryOption.available(definitions: definitions, locale: locale) }

    private func saveChanges(to category: CategoryOption, name: String, icon: String, color: String) {
        if let definition = definitions.first(where: { $0.id == category.id }) {
            definition.name = name
            definition.systemImage = icon
            definition.colorName = color
            definition.updatedAt = .now
        } else {
            modelContext.insert(CategoryDefinition(id: category.id, name: name, systemImage: icon, colorName: color, legacyKindRawValue: category.legacyKind?.rawValue))
        }
        save()
    }

    private func delete(_ category: CategoryOption, replacingWith replacementID: String) {
        let replacement = CategoryOption.resolve(id: replacementID, definitions: definitions, locale: locale)
        for transaction in transactions where transaction.categoryID == category.id {
            transaction.category = replacement.legacyKind ?? .other
            transaction.customCategoryID = replacement.legacyKind == nil ? replacement.id : nil
            transaction.markUpdated()
        }
        for budget in budgets.filter({ $0.categoryID == category.id }) {
            if let existingBudget = budgets.first(where: {
                $0.id != budget.id &&
                $0.categoryID == replacement.id &&
                Calendar.current.isDate($0.monthStart, equalTo: budget.monthStart, toGranularity: .month)
            }) {
                existingBudget.amount += budget.amount
                existingBudget.markUpdated()
                modelContext.delete(budget)
            } else {
                budget.category = replacement.legacyKind ?? .other
                budget.customCategoryID = replacement.legacyKind == nil ? replacement.id : nil
                budget.markUpdated()
            }
        }
        if let definition = definitions.first(where: { $0.id == category.id }) {
            if category.legacyKind == nil { modelContext.delete(definition) } else {
                definition.isHidden = true
                definition.updatedAt = .now
            }
        } else if let legacyKind = category.legacyKind {
            modelContext.insert(CategoryDefinition(id: category.id, name: category.name, systemImage: category.systemImage, colorName: category.colorName, legacyKindRawValue: legacyKind.rawValue, isHidden: true))
        }
        save()
    }

    private func save() {
        do { try modelContext.save() } catch {
            modelContext.rollback()
            saveError = true
        }
    }
}

private struct CategoryManagementRow: View {
    let category: CategoryOption
    let transactionCount: Int
    let budgetCount: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.systemImage)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(category.tint.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading) {
                Text(category.name).font(.headline)
                Text("\(transactionCount) transactions · \(budgetCount) budgets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
