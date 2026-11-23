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

    @State private var allowNewMySavingsRecords = false
    @State private var isShowingImporter = false
    @State private var pendingImportURL: URL?
    @State private var isShowingImportConfirmation = false
    @State private var importSummary: ImportSummary?
    @State private var importError: String?

    var body: some View {
        Form {
            Section("Import file") {
                Toggle("MySavings: Tillat nye poster uten sikkert treff", isOn: $allowNewMySavingsRecords)
                Text("Bruk bare etter kontroll av at postene ikke finnes fra før. Koble eldre importer ved å importere originalfilen først.").font(.footnote).foregroundStyle(.secondary)
                Button {
                    isShowingImporter = true
                } label: {
                    Label("Choose JSON or CSV file", systemImage: "doc.badge.plus")
                }
            }

            Section("Supported formats") {
                ImportInfoRow(
                    title: "JSON",
                    detail: "Restores transactions, budgets, savings goals, categories, settings and recurrence fields from a JSON backup."
                )
                ImportInfoRow(
                    title: "CSV",
                    detail: "Uses columns like title, amount, date, type, status, category and recurrence."
                )
            }

            Section("Safety") {
                Text("Existing savings goals are kept when merging. Replace restores goals only when the file includes them. Older backups never remove your goals.")
                Text("MySavings: Uendrede lokale poster oppdateres fra nyere filer. Lokale endringer vises som konflikter og beholdes. Importer først den opprinnelige filen dersom du har importert tidligere.")
                Text("Merge adds records with new IDs and keeps existing records unchanged. Replace restores transactions and, when included, budgets from the backup. Matching category definitions are restored; other categories are kept. Settings are restored in both modes. Purchase status and external AI consent are never restored.")
                    .foregroundStyle(.secondary)
            }

            if let importSummary {
                Section("Import result") {
                    Text(importSummary.message)
                    ForEach(importSummary.sourceConflicts) { conflict in
                        VStack(alignment: .leading) {
                            Text(conflict.title).font(.headline)
                            Text(conflict.reason).foregroundStyle(.secondary)
                        }
                    }
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
            Button("Merge with existing data") {
                confirmImport(mode: .merge)
            }
            Button("Replace existing data", role: .destructive) {
                confirmImport(mode: .replaceExisting)
            }
            Button("Cancel", role: .cancel) {
                pendingImportURL = nil
            }
        } message: {
            Text("Merge adds missing records without duplicating existing IDs. Replace removes existing transactions and restores the backup. Budgets are replaced only when the file contains budgets. Settings in the backup are restored.")
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

    private func confirmImport(mode: ImportMode) {
        guard let pendingImportURL else { return }

        do {
            importSummary = try ImportService.importFile(
                at: pendingImportURL,
                mode: mode,
                modelContext: modelContext,
                allowNewMySavingsRecordsAlongsideUntracked: allowNewMySavingsRecords
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
