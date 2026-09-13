//
//  MainTabView.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import SwiftData
import SwiftUI

struct MainTabView: View {
    @Query(sort: \Transaction.dueDate) private var transactions: [Transaction]
    @AppStorage(AppSettingsKey.notifyDueToday) private var notifyDueToday = false
    @AppStorage(AppSettingsKey.notifyDueTomorrow) private var notifyDueTomorrow = false
    @AppStorage(AppSettingsKey.notifyDueInAdvance) private var notifyDueInAdvance = false
    @AppStorage(AppSettingsKey.notificationAdvanceDays) private var notificationAdvanceDays = 7
    @AppStorage(AppSettingsKey.notifyPendingIncome) private var notifyPendingIncome = false

    @State private var selectedTab: MainTab = .dashboard
    @State private var newTransactionIntent: NewTransactionIntent?

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(
                onNewIncome: { newTransactionIntent = .income },
                onNewExpense: { newTransactionIntent = .expense },
                onRegisterPayment: { newTransactionIntent = .payment },
                onShowTransactions: { selectedTab = .transactions }
            )
            .tabItem {
                Label("Overview", systemImage: "gauge.with.dots.needle.33percent")
            }
            .tag(MainTab.dashboard)

            TransactionsView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle")
                }
                .tag(MainTab.transactions)

            StatisticsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.xaxis")
                }
                .tag(MainTab.statistics)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(MainTab.settings)
        }
        .safeAreaInset(edge: .bottom) {
            AddTransactionBar {
                newTransactionIntent = .transaction
            }
        }
        .sheet(item: $newTransactionIntent) { intent in
            TransactionFormView(intent: intent)
        }
        .task {
            await synchronizeNotifications()
        }
        .onChange(of: notificationFingerprint) { _, _ in
            Task {
                await synchronizeNotifications()
            }
        }
    }

    private var notificationSettings: NotificationSettings {
        NotificationSettings(
            notifyDueToday: notifyDueToday,
            notifyDueTomorrow: notifyDueTomorrow,
            notifyDueInAdvance: notifyDueInAdvance,
            notificationAdvanceDays: notificationAdvanceDays,
            notifyPendingIncome: notifyPendingIncome
        )
    }

    private var notificationFingerprint: String {
        let settingsFingerprint = [
            notifyDueToday.description,
            notifyDueTomorrow.description,
            notifyDueInAdvance.description,
            notificationAdvanceDays.description,
            notifyPendingIncome.description
        ].joined(separator: "|")

        let transactionFingerprint = transactions.map { transaction in
            [
                transaction.id.uuidString,
                transaction.title,
                transaction.amount.description,
                transaction.type.rawValue,
                transaction.dueDate.timeIntervalSinceReferenceDate.description,
                transaction.status.rawValue,
                transaction.isCompleted.description,
                transaction.isArchived.description
            ].joined(separator: ":")
        }.joined(separator: "|")

        return "\(settingsFingerprint)#\(transactionFingerprint)"
    }

    private func synchronizeNotifications() async {
        await NotificationScheduler.synchronize(transactions: transactions, settings: notificationSettings)
    }
}

private enum MainTab: Hashable {
    case dashboard
    case transactions
    case statistics
    case settings
}

enum NewTransactionIntent: String, Identifiable {
    case transaction
    case income
    case expense
    case payment

    var id: String { rawValue }
}

private struct AddTransactionBar: View {
    let action: () -> Void

    var body: some View {
        HStack {
            Spacer()

            Button(action: action) {
                Label("New transaction", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("New transaction")

            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(.bar)
    }
}

#Preview {
    MainTabView()
}
