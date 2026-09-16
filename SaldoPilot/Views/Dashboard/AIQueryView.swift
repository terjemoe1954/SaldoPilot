//
//  AIQueryView.swift
//  SaldoPilot
//
//  Created by Terje Moe on 13/09/2026.
//

import SwiftUI

struct AIQueryView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettingsKey.language) private var languageRawValue = AppLanguage.system.rawValue

    @State private var question = ""
    @State private var result: AIQueryResult?

    let transactions: [Transaction]

    var body: some View {
        NavigationStack {
            List {
                Section("Ask") {
                    TextField("Ask about your transactions", text: $question, axis: .vertical)
                        .lineLimit(2...4)

                    Button("Ask SaldoPilot") {
                        runQuery()
                    }
                    .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section("Examples") {
                    ForEach(exampleQuestions) { example in
                        AIQueryExampleButton(example: example, question: $question, runQuery: runQuery)
                    }
                }

                if let result {
                    Section(result.title) {
                        Text(result.answer)

                        if !result.transactions.isEmpty {
                            ForEach(result.transactions, id: \.id) { transaction in
                                AIQueryTransactionRow(transaction: transaction)
                            }
                        }
                    }
                }

                Section("Privacy") {
                    Text("Questions are answered locally from transactions already stored on this device.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Ask SaldoPilot")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func runQuery() {
        result = AIQueryEngine.answer(question: question, transactions: transactions, locale: selectedLanguage.locale)
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .system
    }

    private var exampleQuestions: [AIQueryExample] {
        [
            AIQueryExample(
                displayText: localized("What is due next week?"),
                queryText: "What is due next week?"
            ),
            AIQueryExample(
                displayText: localized("How much did I spend on subscriptions this year?"),
                queryText: "How much did I spend on subscriptions this year?"
            ),
            AIQueryExample(
                displayText: localized("Which expenses increased most?"),
                queryText: "Which expenses increased most?"
            ),
            AIQueryExample(
                displayText: localized("What can I save on?"),
                queryText: "What can I save on?"
            )
        ]
    }

    private func localized(_ value: String.LocalizationValue) -> String {
        String(localized: value, bundle: .main, locale: selectedLanguage.locale)
    }
}

private struct AIQueryExample: Identifiable {
    let id = UUID()
    let displayText: String
    let queryText: String
}

private struct AIQueryExampleButton: View {
    let example: AIQueryExample
    @Binding var question: String
    let runQuery: () -> Void

    var body: some View {
        Button {
            question = example.queryText
            runQuery()
        } label: {
            Label(example.displayText, systemImage: "text.bubble")
        }
    }
}

private struct AIQueryTransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: transaction.type == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.title3)
                .foregroundStyle(transaction.type == .income ? .green : .red)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                Text(transaction.dueDate, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(transaction.amount.formattedCurrency)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    AIQueryView(transactions: [])
}
