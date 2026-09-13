//
//  MainTabView.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import SwiftUI

struct MainTabView: View {
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
