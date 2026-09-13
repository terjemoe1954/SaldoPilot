//
//  NotificationScheduler.swift
//  SaldoPilot
//
//  Created by Terje Moe on 13/09/2026.
//

import Foundation
import UserNotifications

struct NotificationSettings: Equatable {
    let notifyDueToday: Bool
    let notifyDueTomorrow: Bool
    let notifyDueInAdvance: Bool
    let notificationAdvanceDays: Int
    let notifyPendingIncome: Bool

    var hasEnabledNotifications: Bool {
        notifyDueToday || notifyDueTomorrow || notifyDueInAdvance || notifyPendingIncome
    }
}

enum NotificationScheduler {
    private static let identifierPrefix = "saldopilot.transaction"

    static func synchronize(transactions: [Transaction], settings: NotificationSettings) async {
        await removeSaldoPilotNotifications()

        guard settings.hasEnabledNotifications else { return }
        guard await requestAuthorization() else { return }

        let activeTransactions = transactions.filter { transaction in
            !transaction.isArchived &&
            transaction.status != .cancelled &&
            !transaction.isCompleted &&
            (transaction.status == .pending || transaction.effectiveStatus == .overdue)
        }

        for transaction in activeTransactions {
            await scheduleNotifications(for: transaction, settings: settings)
        }
    }

    private static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    private static func removeSaldoPilotNotifications() async {
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()
        let identifiers = pendingRequests
            .map(\.identifier)
            .filter { $0.hasPrefix(identifierPrefix) }

        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func scheduleNotifications(for transaction: Transaction, settings: NotificationSettings) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let dueDay = calendar.startOfDay(for: transaction.dueDate)

        if settings.notifyDueInAdvance, settings.notificationAdvanceDays > 0 {
            let reminderDate = calendar.date(byAdding: .day, value: -settings.notificationAdvanceDays, to: dueDay)
            await schedule(
                transaction: transaction,
                kind: "advance",
                date: reminderDate,
                body: String(localized: "\(transaction.title) is due in \(settings.notificationAdvanceDays) days.")
            )
        }

        if settings.notifyDueTomorrow {
            let reminderDate = calendar.date(byAdding: .day, value: -1, to: dueDay)
            await schedule(
                transaction: transaction,
                kind: "tomorrow",
                date: reminderDate,
                body: String(localized: "\(transaction.title) is due tomorrow.")
            )
        }

        if settings.notifyDueToday {
            await schedule(
                transaction: transaction,
                kind: "today",
                date: dueDay,
                body: String(localized: "\(transaction.title) is due today.")
            )
        }

        if dueDay < today {
            await schedule(
                transaction: transaction,
                kind: "overdue",
                date: nextReminderDate(),
                body: String(localized: "\(transaction.title) is overdue.")
            )
        }

        if settings.notifyPendingIncome, transaction.type == .income && transaction.status == .pending {
            await schedule(
                transaction: transaction,
                kind: "pendingIncome",
                date: nextReminderDate(),
                body: String(localized: "Pending income: \(transaction.title)")
            )
        }
    }

    private static func schedule(transaction: Transaction, kind: String, date: Date?, body: String) async {
        guard let date else { return }

        let triggerDate = notificationDate(for: date)
        guard triggerDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "SaldoPilot")
        content.body = body
        content.sound = .default
        content.threadIdentifier = "saldopilot.notifications"

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = "\(identifierPrefix).\(transaction.id.uuidString).\(kind)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            return
        }
    }

    private static func notificationDate(for date: Date) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? date
    }

    private static func nextReminderDate() -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.hour = 18
        components.minute = 0

        let todayEvening = calendar.date(from: components) ?? .now
        if todayEvening > .now {
            return todayEvening
        }

        return calendar.date(byAdding: .day, value: 1, to: todayEvening) ?? .now.addingTimeInterval(3600)
    }
}
