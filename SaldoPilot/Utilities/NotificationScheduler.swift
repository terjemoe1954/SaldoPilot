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
    private static let scheduledOncePrefix = "notifications.scheduledOnce"

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
        let isExpense = transaction.type == .expense

        if isExpense, settings.notifyDueInAdvance, settings.notificationAdvanceDays > 0 {
            let reminderDate = calendar.date(byAdding: .day, value: -settings.notificationAdvanceDays, to: dueDay)
            await schedule(
                transaction: transaction,
                kind: "advance",
                reminder: morningReminder(for: reminderDate, transaction: transaction, kind: "advance"),
                body: String(localized: "\(transaction.title) is due in \(settings.notificationAdvanceDays) days.")
            )
        }

        if isExpense, settings.notifyDueTomorrow {
            let reminderDate = calendar.date(byAdding: .day, value: -1, to: dueDay)
            await schedule(
                transaction: transaction,
                kind: "tomorrow",
                reminder: morningReminder(for: reminderDate, transaction: transaction, kind: "tomorrow"),
                body: String(localized: "\(transaction.title) is due tomorrow.")
            )
        }

        if isExpense, settings.notifyDueToday {
            await schedule(
                transaction: transaction,
                kind: "today",
                reminder: morningReminder(for: dueDay, transaction: transaction, kind: "today"),
                body: String(localized: "\(transaction.title) is due today.")
            )
        }

        if isExpense, dueDay < today {
            await schedule(
                transaction: transaction,
                kind: "overdue",
                reminder: ReminderSchedule(date: nextReminderDate()),
                body: String(localized: "\(transaction.title) is overdue.")
            )
        }

        if settings.notifyPendingIncome, transaction.type == .income && transaction.status == .pending {
            await schedule(
                transaction: transaction,
                kind: "pendingIncome",
                reminder: ReminderSchedule(date: nextReminderDate()),
                body: String(localized: "Pending income: \(transaction.title)")
            )
        }
    }

    private static func schedule(
        transaction: Transaction,
        kind: String,
        reminder: ReminderSchedule,
        body: String
    ) async {
        let triggerDate = reminder.date
        guard triggerDate > .now else { return }
        if let scheduledOnceKey = reminder.scheduledOnceKey {
            guard !UserDefaults.standard.bool(forKey: scheduledOnceKey) else { return }
        }

        let identifier = notificationIdentifier(transaction: transaction, kind: kind, triggerDate: triggerDate)

        let content = UNMutableNotificationContent()
        content.title = String(localized: "SaldoPilot")
        content.body = body
        content.sound = .default
        content.threadIdentifier = "saldopilot.notifications"

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            if let scheduledOnceKey = reminder.scheduledOnceKey {
                UserDefaults.standard.set(true, forKey: scheduledOnceKey)
            }
        } catch {
            return
        }
    }

    private static func morningReminder(for date: Date?, transaction: Transaction, kind: String) -> ReminderSchedule {
        guard let date else { return ReminderSchedule(date: .distantPast) }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = 9
        components.minute = 0
        let reminderDate = Calendar.current.date(from: components) ?? date

        if Calendar.current.isDateInToday(reminderDate), reminderDate <= .now {
            return ReminderSchedule(
                date: .now.addingTimeInterval(60),
                scheduledOnceKey: scheduledOnceKey(transaction: transaction, kind: kind, date: reminderDate)
            )
        }

        return ReminderSchedule(date: reminderDate)
    }

    private static func notificationIdentifier(transaction: Transaction, kind: String, triggerDate: Date) -> String {
        "\(identifierPrefix).\(transaction.id.uuidString).\(kind).\(dateCode(for: triggerDate))"
    }

    private static func scheduledOnceKey(transaction: Transaction, kind: String, date: Date) -> String {
        "\(scheduledOncePrefix).\(transaction.id.uuidString).\(kind).\(dateCode(for: date))"
    }

    private static func dateCode(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let dateCode = String(
            format: "%04d%02d%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
        return dateCode
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

private struct ReminderSchedule {
    let date: Date
    var scheduledOnceKey: String?
}
