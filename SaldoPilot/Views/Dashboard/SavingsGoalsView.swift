import SwiftData
import SwiftUI

struct SavingsGoalsSection: View {
    @Query private var storedGoals: [SavingsGoal]
    @State private var editingGoal: SavingsGoal?
    @State private var addingGoal = false
    private var goals: [SavingsGoal] { SavingsGoalSelection.preferred(storedGoals).filter { !$0.isDeleted } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Savings goals", systemImage: "target").font(.headline)
                Spacer()
                Button { addingGoal = true } label: { Label("Add", systemImage: "plus") }
                    .font(.subheadline)
            }
            if goals.isEmpty {
                Text("What would you like to save for?").font(.subheadline.weight(.medium))
                Text("Create a buffer, a holiday fund or another savings goal.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Button("Create savings goal") { addingGoal = true }.buttonStyle(.bordered)
            }
            ForEach(goals, id: \.id) { goal in
                Button { editingGoal = goal } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(goal.name).font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(goal.progress, format: .percent.precision(.fractionLength(0)))
                                .font(.caption).foregroundStyle(.secondary)
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        }
                        ProgressView(value: goal.progress).tint(.blue)
                            .accessibilityLabel(goal.name)
                        ViewThatFits(in: .horizontal) {
                            HStack {
                                goalAmounts(goal)
                                Spacer()
                                goalRemaining(goal)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                goalAmounts(goal)
                                goalRemaining(goal)
                            }
                        }
                        if let date = goal.targetDate {
                            Text(date, format: .dateTime.day().month(.abbreviated).year())
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }.buttonStyle(.plain)
                if goal.id != goals.last?.id { Divider() }
            }
            Text("Goals are tracked separately and do not change income, expenses or the forecast.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
        .sheet(isPresented: $addingGoal) { SavingsGoalFormView(goal: nil) }
        .sheet(item: $editingGoal) { SavingsGoalFormView(goal: $0) }
    }
    private func goalAmounts(_ goal: SavingsGoal) -> some View {
        Text(goal.savedAmount.formattedCurrency + " / " + goal.targetAmount.formattedCurrency)
            .font(.caption).foregroundStyle(.secondary)
    }
    private func goalRemaining(_ goal: SavingsGoal) -> some View {
        Text("\(goal.remaining.formattedCurrency) remaining").font(.caption).foregroundStyle(.secondary)
    }
}

struct SavingsGoalFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    let goal: SavingsGoal?
    @State private var name: String
    @State private var target: String
    @State private var saved: String
    @State private var hasTargetDate: Bool
    @State private var targetDate: Date
    @State private var confirmingDelete = false
    @State private var errorMessage: String?
    @State private var isSaving = false

    init(goal: SavingsGoal?) {
        self.goal = goal
        _name = State(initialValue: goal?.name ?? "")
        _target = State(initialValue: goal.map { $0.targetAmount.description } ?? "")
        _saved = State(initialValue: goal.map { $0.savedAmount.description } ?? "0")
        _hasTargetDate = State(initialValue: goal?.targetDate != nil)
        _targetDate = State(initialValue: goal?.targetDate ?? .now)
    }
    private func amount(_ value: String) -> Decimal? {
        let compact = value.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\u{00a0}", with: "").replacingOccurrences(of: "\u{202f}", with: "")
        // Only accept a complete decimal value, never a partial NumberFormatter parse.
        let separator = locale.decimalSeparator ?? "."
        let normalized = compact.replacingOccurrences(of: separator, with: ".").replacingOccurrences(of: ",", with: ".")
        guard normalized.range(of: #"^\d+(\.\d{1,2})?$"#, options: .regularExpression) != nil else { return nil }
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }
    private var isValid: Bool {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !title.isEmpty && title.count <= 120 && (amount(target).map { $0 > 0 } ?? false) && (amount(saved).map { $0 >= 0 } ?? false)
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("Goal details") {
                    TextField("Name", text: $name)
                    TextField("Target amount", text: $target).keyboardType(.decimalPad)
                    TextField("Saved so far", text: $saved).keyboardType(.decimalPad)
                    Toggle("Target date", isOn: $hasTargetDate)
                    if hasTargetDate { DatePicker("Target date", selection: $targetDate, displayedComponents: .date) }
                }
                Section {
                    Text("Enter the total saved for this goal. This does not register a payment or move money.")
                        .foregroundStyle(.secondary)
                }
                if goal != nil {
                    Section { Button("Delete savings goal", role: .destructive) { confirmingDelete = true } }
                }
            }
            .navigationTitle(goal == nil ? "New savings goal" : "Edit savings goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(isSaving) }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!isValid || isSaving) }
            }
            .interactiveDismissDisabled(isSaving)
            .confirmationDialog("Remove this savings goal?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete savings goal", role: .destructive) {
                    guard let goal else { return }
                    do { try SavingsGoalSelection.delete(goal, in: context); dismiss() }
                    catch { errorMessage = error.localizedDescription }
                }
            } message: { Text("Only the savings goal is removed. Transactions and amounts are kept.") }
            .alert("Could not save savings goal", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }
    private func save() {
        guard !isSaving, isValid, let target = amount(target), let saved = amount(saved) else { return }
        isSaving = true
        do {
            try SavingsGoalSelection.save(goal, name: name, target: target, saved: saved, date: hasTargetDate ? targetDate : nil, in: context)
            dismiss()
        } catch { isSaving = false; errorMessage = error.localizedDescription }
    }
}
