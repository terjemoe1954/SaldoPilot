//
//  ExportDataView.swift
//  SaldoPilot
//
//  Created by Terje Moe on 13/09/2026.
//

import SwiftData
import SwiftUI

struct ExportDataView: View {
    @Query(sort: \Transaction.dueDate) private var transactions: [Transaction]

    @State private var backupURL: URL?
    @State private var csvURL: URL?
    @State private var exportError: String?

    var body: some View {
        Form {
            Section("JSON backup") {
                Text("Creates a backup with categories, transactions, notes and recurrence rules.")
                    .foregroundStyle(.secondary)

                Button {
                    prepareJSONBackup()
                } label: {
                    Label("Prepare JSON backup", systemImage: "doc.badge.gearshape")
                }

                if let backupURL {
                    ShareLink(item: backupURL) {
                        Label("Share JSON backup", systemImage: "square.and.arrow.up")
                    }
                }
            }

            Section("CSV export") {
                Text("Creates a spreadsheet-friendly transaction export.")
                    .foregroundStyle(.secondary)

                Button {
                    prepareCSVExport()
                } label: {
                    Label("Prepare CSV export", systemImage: "tablecells")
                }

                if let csvURL {
                    ShareLink(item: csvURL) {
                        Label("Share CSV export", systemImage: "square.and.arrow.up")
                    }
                }
            }

            Section("Backup import") {
                Text("Use Import data to merge a JSON backup back into SaldoPilot. You will be asked to confirm before anything is imported.")
                    .foregroundStyle(.secondary)

                NavigationLink {
                    ImportDataView()
                } label: {
                    Label("Import backup", systemImage: "square.and.arrow.down")
                }
            }

            if let exportError {
                Section("Export error") {
                    Text(exportError)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Backup and export")
    }

    private func prepareJSONBackup() {
        exportError = nil

        do {
            backupURL = try ExportService.makeJSONBackup(transactions: transactions)
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func prepareCSVExport() {
        exportError = nil

        do {
            csvURL = try ExportService.makeCSVExport(transactions: transactions)
        } catch {
            exportError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ExportDataView()
    }
}
