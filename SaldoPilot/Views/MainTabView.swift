//
//   MainTabView.swift
//   SaldoPilot
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
    @AppStorage(AppSettingsKey.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    @State private var selectedTab: MainTab = .dashboard
    @State private var newTransactionIntent: NewTransactionIntent?
    @State private var transactionListFilter: TransactionListFilter = .all
    @State private var isShowingOnboarding = false
    @State private var isShowingOverdueAtLaunch = false
    @State private var hasCheckedOverdueAtLaunch = false

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(
                onNewIncome: { newTransactionIntent = .income },
                onNewExpense: { newTransactionIntent = .expense },
                onRegisterPayment: { newTransactionIntent = .payment },
                onShowTransactions: showTransactions
            )
            .tabItem {
                Label("Overview", systemImage: "gauge.with.dots.needle.33percent")
            }
            .tag(MainTab.dashboard)

            TransactionsView(initialFilter: transactionListFilter)
                .onNewTransaction {
                    newTransactionIntent = .transaction
                }
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle")
                }
                .tag(MainTab.transactions)

            StatisticsView {
                newTransactionIntent = .transaction
            }
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.xaxis")
                }
                .tag(MainTab.statistics)

            BudgetsView()
                .tabItem {
                    Label("Budgets", systemImage: "target")
                }
                .tag(MainTab.budgets)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(MainTab.settings)
        }
        .sheet(item: $newTransactionIntent) { intent in
            TransactionFormView(intent: intent)
        }
        .fullScreenCover(isPresented: $isShowingOnboarding) {
            OnboardingView {
                hasCompletedOnboarding = true
                isShowingOnboarding = false
            }
        }
        .sheet(isPresented: $isShowingOverdueAtLaunch) {
            NavigationStack {
                UnpaidBillsView(scope: .overdueOnly)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                isShowingOverdueAtLaunch = false
                            }
                        }
                    }
            }
        }
        .task {
            if !hasCompletedOnboarding && transactions.isEmpty {
                isShowingOnboarding = true
            } else {
                showOverdueAtLaunchIfNeeded()
            }
            await synchronizeNotifications()
        }
        .onChange(of: notificationFingerprint) { _, _ in
            Task {
                await synchronizeNotifications()
            }
        }
    }

    private var overdueTransactions: [Transaction] {
        let today = Calendar.current.startOfDay(for: .now)
        return transactions.filter {
            $0.type == .expense &&
            $0.status == .pending &&
            !$0.isCompleted &&
            !$0.isArchived &&
            $0.dueDate < today
        }
    }

    private func showOverdueAtLaunchIfNeeded() {
        guard !hasCheckedOverdueAtLaunch else { return }
        hasCheckedOverdueAtLaunch = true
        isShowingOverdueAtLaunch = !overdueTransactions.isEmpty
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
        guard !AppLaunchConfiguration.usesIsolatedTestStore else { return }
        await NotificationScheduler.synchronize(transactions: transactions, settings: notificationSettings)
    }

    private func showTransactions(filter: TransactionListFilter) {
        transactionListFilter = filter
        selectedTab = .transactions
    }
}

private enum MainTab: Hashable {
    case dashboard
    case transactions
    case statistics
    case budgets
    case settings
}

enum NewTransactionIntent: String, Identifiable {
    case transaction
    case income
    case expense
    case payment

    var id: String { rawValue }
}

#Preview {
    MainTabView()
}
