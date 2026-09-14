//
//  ImportDataView.swift
//  SaldoPilot
//
//  Created by Terje Moe on 13/09/2026.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ImportDataView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isShowingImporter = false
    @State private var pendingImportURL: URL?
    @State private var isShowingImportConfirmation = false
    @State private var importSummary: ImportSummary?
    @State private var importError: String?

    var body: some View {
        Form {
            Section("Import file") {
                Button {
                    isShowingImporter = true
                } label: {
                    Label("Choose JSON or CSV file", systemImage: "doc.badge.plus")
                }
            }

            Section("Supported formats") {
                ImportInfoRow(
                    title: "JSON",
                    detail: "Imports categories, transactions and recurrence fields from a structured export."
                )
                ImportInfoRow(
                    title: "CSV",
                    detail: "Uses columns like title, amount, date, type, status, category and recurrence."
                )
            }

            Section("Safety") {
                Text("Import creates new categories and transactions. It does not delete existing data or connect directly to the old database.")
                    .foregroundStyle(.secondary)
            }

            if let importSummary {
                Section("Import result") {
                    Text(importSummary.message)
                }
            }

            if let importError {
                Section("Import error") {
                    Text(importError)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Import data")
        .fileImporter(
            isPresented: $isShowingImporter,
            allowedContentTypes: [.json, .commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
        }
        .confirmationDialog(
            "Import backup?",
            isPresented: $isShowingImportConfirmation,
            titleVisibility: .visible
        ) {
            Button("Merge import data") {
                confirmImport()
            }
            Button("Cancel", role: .cancel) {
                pendingImportURL = nil
            }
        } message: {
            Text("Imported data will be added to your existing categories and transactions. Existing data will not be deleted.")
        }
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        importSummary = nil
        importError = nil

        do {
            guard let url = try result.get().first else { return }
            pendingImportURL = url
            isShowingImportConfirmation = true
        } catch {
            importError = error.localizedDescription
        }
    }

    private func confirmImport() {
        guard let pendingImportURL else { return }

        do {
            importSummary = try ImportService.importFile(
                at: pendingImportURL,
                modelContext: modelContext
            )
            self.pendingImportURL = nil
        } catch {
            importError = error.localizedDescription
        }
    }
}

private struct ImportInfoRow: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        ImportDataView()
    }
}
