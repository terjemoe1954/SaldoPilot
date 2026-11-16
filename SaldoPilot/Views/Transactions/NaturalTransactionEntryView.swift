import SwiftUI

struct NaturalTransactionEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var input = ""
    @State private var isGenerating = false
    @State private var error: NaturalTransactionDraftError?
    @State private var generationTask: Task<Void, Never>?
    @FocusState private var isInputFocused: Bool

    let defaultType: TransactionType
    let onDraft: (NaturalTransactionDraft) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Describe one transaction", text: $input, axis: .vertical)
                        .lineLimit(4...8)
                        .focused($isInputFocused)
                        .accessibilityIdentifier("naturalTransactionInput")
                        .disabled(isGenerating)
                    Text("Use numbers for the amount. Include a description and a due date, and optionally a repeat interval.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if input.count > NaturalTransactionDraftParser.maximumInputLength {
                        Text("Use at most 500 characters.").foregroundStyle(.red)
                    }
                } header: {
                    Text("Write a transaction")
                } footer: {
                    Text("You will review an editable draft before saving. Nothing is saved automatically.")
                }

                Section("Example") {
                    Text("Add an electricity bill for 1249 kroner, due 25 November, every month.")
                        .foregroundStyle(.secondary)
                    Button("Use example") {
                        input = exampleText
                        error = nil
                    }
                    .disabled(isGenerating)
                    .accessibilityIdentifier("useNaturalTransactionExample")
                }

                if let error {
                    Section {
                        Text(error.message).foregroundStyle(.red)
                    }
                }

                Section {
                    Button(action: createDraft) {
                        HStack {
                            if isGenerating { ProgressView() }
                            Text(isGenerating ? "Creating draft…" : "Create draft")
                        }
                    }
                    .disabled(isGenerating || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                              || input.count > NaturalTransactionDraftParser.maximumInputLength)
                    .accessibilityIdentifier("createNaturalTransactionDraft")
                }

                Section("Privacy") {
                    Text("Text is processed on this device. On-device AI is used when available; otherwise local text recognition is used.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Write a transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { generationTask?.cancel(); dismiss() }
                }
            }
            .onDisappear { generationTask?.cancel() }
        }
    }

    private var exampleText: String {
        let language = locale.language.languageCode?.identifier ?? "en"
        let resource = language == "no" || language == "nn" ? "nb" : language
        let bundle = Bundle.main.path(forResource: resource, ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
        return bundle.localizedString(forKey: "Add an electricity bill for 1249 kroner, due 25 November, every month.", value: nil, table: nil)
    }

    private func createDraft() {
        isInputFocused = false
        error = nil
        isGenerating = true
        let text = input
        generationTask = Task {
            defer { isGenerating = false }
            do {
                let draft = try await NaturalTransactionDraftService.makeDraft(from: text, defaultType: defaultType, locale: locale)
                guard !Task.isCancelled else { return }
                onDraft(draft)
                dismiss()
            } catch is CancellationError {
                return
            } catch let draftError as NaturalTransactionDraftError {
                self.error = draftError
            } catch {
                self.error = .emptyInput
            }
        }
    }
}

private extension NaturalTransactionDraftError {
    var message: LocalizedStringKey {
        switch self {
        case .emptyInput: "Describe one transaction to create a draft."
        case .tooLong: "Use at most 500 characters."
        case .multipleAmounts: "Several amounts were found. Describe one transaction with one amount at a time."
        case .unsupportedCurrency: "This app records amounts in NOK. Convert foreign currency yourself and enter the NOK amount."
        }
    }
}

struct NaturalTransactionReviewSection: View {
    let draft: NaturalTransactionDraft
    @Binding var hasReviewed: Bool

    var body: some View {
        Section {
            Text(draft.source)
                .font(.subheadline)
                .textSelection(.enabled)
            Text(draft.usedLanguageModel ? "Draft created with on-device AI." : "Draft created with local text recognition.")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(draft.reviewItems, id: \.rawValue) { item in
                Label(item.message, systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
            Text("New drafts start as pending. If already paid or received, check the status and payment date below.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Toggle("I have checked the fields below", isOn: $hasReviewed)
                .accessibilityIdentifier("approveNaturalTransactionDraft")
        } header: {
            Text("Review draft")
        } footer: {
            Text("Check the description, amount, type, category, dates and recurrence. Save creates the transaction only after your approval.")
        }
    }
}

private extension NaturalTransactionDraft.ReviewItem {
    var message: LocalizedStringKey {
        switch self {
        case .missingAmount: "No valid amount found. Enter the amount below."
        case .missingDate: "No due date found. Today is proposed; check or change the date below."
        case .unclearDate: "The due date is unclear or invalid. Today is proposed; choose the correct date below."
        case .inferredYear: "No year was specified. The current year is proposed; check the date below."
        case .unclearType: "Check whether this is income or an expense."
        case .unclearRecurrence: "The repeat interval is unclear. No recurrence is selected; check the interval below."
        }
    }
}
