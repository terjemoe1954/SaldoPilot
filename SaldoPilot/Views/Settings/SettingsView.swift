//
//  SettingsView.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.dueDate) private var transactions: [Transaction]

    @AppStorage(AppSettingsKey.appearance) private var appearanceRawValue = AppAppearance.system.rawValue
    @AppStorage(AppSettingsKey.language) private var languageRawValue = AppLanguage.system.rawValue
    @AppStorage(AppSettingsKey.showNameOnDashboard) private var showNameOnDashboard = false
    @AppStorage(AppSettingsKey.displayName) private var displayName = ""
    @AppStorage(AppSettingsKey.showCompletedStatus) private var showCompletedStatus = true
    @AppStorage(AppSettingsKey.defaultPeriod) private var defaultPeriodRawValue = AppDefaultPeriod.thisMonth.rawValue
    @AppStorage(AppSettingsKey.defaultDateType) private var defaultDateTypeRawValue = AppDefaultDateType.dueDate.rawValue
    @AppStorage(AppSettingsKey.notifyDueToday) private var notifyDueToday = false
    @AppStorage(AppSettingsKey.notifyDueTomorrow) private var notifyDueTomorrow = false
    @AppStorage(AppSettingsKey.notifyDueInAdvance) private var notifyDueInAdvance = false
    @AppStorage(AppSettingsKey.notificationAdvanceDays) private var notificationAdvanceDays = 7
    @AppStorage(AppSettingsKey.notifyPendingIncome) private var notifyPendingIncome = false

    @State private var isShowingDeleteAllConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Appearance", selection: appearanceBinding) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(appearance.title).tag(appearance)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Language", selection: languageBinding) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.title).tag(language)
                        }
                    }
                }

                Section("Personal") {
                    Toggle("Show name on the front page", isOn: $showNameOnDashboard)

                    TextField("Name", text: $displayName)
                        .textContentType(.name)
                }

                Section("Transactions") {
                    Toggle("Show completed status", isOn: $showCompletedStatus)

                    Picker("Default period", selection: defaultPeriodBinding) {
                        ForEach(AppDefaultPeriod.allCases) { period in
                            Text(period.title).tag(period)
                        }
                    }

                    Picker("Default date type", selection: defaultDateTypeBinding) {
                        ForEach(AppDefaultDateType.allCases) { dateType in
                            Text(dateType.title).tag(dateType)
                        }
                    }
                }

                Section("Notifications") {
                    Toggle("Due today", isOn: $notifyDueToday)
                    Toggle("Due tomorrow", isOn: $notifyDueTomorrow)
                    Toggle("Due in advance", isOn: $notifyDueInAdvance)
                    Toggle("Pending income", isOn: $notifyPendingIncome)

                    Stepper(value: $notificationAdvanceDays, in: 1...30) {
                        LabeledContent("Days in advance", value: notificationAdvanceDays.formatted())
                    }
                    .disabled(!notifyDueInAdvance)
                }

                Section("Manage") {
                    NavigationLink {
                        CategoriesView()
                    } label: {
                        Label("Categories", systemImage: "tag")
                    }

                    NavigationLink {
                        ImportDataView()
                    } label: {
                        Label("Import data", systemImage: "square.and.arrow.down")
                    }

                    NavigationLink {
                        ExportDataView()
                    } label: {
                        Label("Backup and export", systemImage: "externaldrive")
                    }

                    Button(role: .destructive) {
                        isShowingDeleteAllConfirmation = true
                    } label: {
                        Label("Delete all transactions", systemImage: "trash")
                    }
                    .disabled(transactions.isEmpty)
                }

                Section("App") {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Build", value: buildNumber)

                    Link(destination: privacyURL) {
                        Label("Privacy", systemImage: "hand.raised")
                    }

                    NavigationLink {
                        AIPrivacyView()
                    } label: {
                        Label("AI & Privacy", systemImage: "sparkles")
                    }

                    Link(destination: supportURL) {
                        Label("Support", systemImage: "questionmark.circle")
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Delete all transactions?",
                isPresented: $isShowingDeleteAllConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete all transactions", role: .destructive) {
                    deleteAllTransactions()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes \(transactions.count) transactions from this device and iCloud sync.")
            }
        }
    }

    private var appearanceBinding: Binding<AppAppearance> {
        Binding {
            AppAppearance(rawValue: appearanceRawValue) ?? .system
        } set: { newValue in
            appearanceRawValue = newValue.rawValue
        }
    }

    private var defaultPeriodBinding: Binding<AppDefaultPeriod> {
        Binding {
            AppDefaultPeriod(rawValue: defaultPeriodRawValue) ?? .thisMonth
        } set: { newValue in
            defaultPeriodRawValue = newValue.rawValue
        }
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding {
            AppLanguage(rawValue: languageRawValue) ?? .system
        } set: { newValue in
            languageRawValue = newValue.rawValue
        }
    }

    private var defaultDateTypeBinding: Binding<AppDefaultDateType> {
        Binding {
            AppDefaultDateType(rawValue: defaultDateTypeRawValue) ?? .dueDate
        } set: { newValue in
            defaultDateTypeRawValue = newValue.rawValue
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var privacyURL: URL {
        URL(string: "https://github.com/terjemoe1954/SaldoPilot/blob/main/AppStore/PrivacyPolicy.md") ?? URL(fileURLWithPath: "/")
    }

    private var supportURL: URL {
        URL(string: "https://github.com/terjemoe1954/SaldoPilot/issues") ?? URL(fileURLWithPath: "/")
    }

    private func deleteAllTransactions() {
        for transaction in transactions {
            modelContext.delete(transaction)
        }
    }
}

#Preview {
    SettingsView()
}
