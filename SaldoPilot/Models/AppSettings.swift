//
//  AppSettings.swift
//  SaldoPilot
//
//  Created by Terje Moe on 13/09/2026.
//

import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .system:
            "System"
        case .light:
            "Light"
        case .dark:
            "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

enum AppDefaultPeriod: String, CaseIterable, Identifiable {
    case thisMonth
    case previousMonth
    case thisYear
    case custom

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .thisMonth:
            "This month"
        case .previousMonth:
            "Previous month"
        case .thisYear:
            "This year"
        case .custom:
            "Custom"
        }
    }
}

enum AppDefaultDateType: String, CaseIterable, Identifiable {
    case dueDate
    case paidDate

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .dueDate:
            "Due date"
        case .paidDate:
            "Paid date"
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case norwegian
    case thai

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .system:
            "System"
        case .english:
            "English"
        case .norwegian:
            "Norwegian"
        case .thai:
            "Thai"
        }
    }

    var locale: Locale {
        switch self {
        case .system:
            .autoupdatingCurrent
        case .english:
            Locale(identifier: "en")
        case .norwegian:
            Locale(identifier: "nb")
        case .thai:
            Locale(identifier: "th")
        }
    }
}

enum AppProStatus: String, CaseIterable, Identifiable {
    case free
    case pro

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .free:
            "Free"
        case .pro:
            "SaldoPilot Pro"
        }
    }

    var isProUnlocked: Bool {
        self == .pro
    }
}

enum AppSettingsKey {
    static let appearance = key("appearance")
    static let language = key("language")
    static let showNameOnDashboard = key("showNameOnDashboard")
    static let displayName = key("displayName")
    static let showCompletedStatus = key("showCompletedStatus")
    static let showSettledTransactions = key("showSettledTransactions")
    static let defaultPeriod = key("defaultPeriod")
    static let defaultDateType = key("defaultDateType")
    static let notifyDueToday = key("notifyDueToday")
    static let notifyDueTomorrow = key("notifyDueTomorrow")
    static let notifyDueInAdvance = key("notifyDueInAdvance")
    static let notificationAdvanceDays = key("notificationAdvanceDays")
    static let notifyPendingIncome = key("notifyPendingIncome")
    static let allowExternalAI = key("allowExternalAI")
    static let proStatus = key("proStatus")
    static let openingBalanceAmount = key("openingBalanceAmount")
    static let openingBalanceDate = key("openingBalanceDate")
    static let hasCompletedOnboarding = key("hasCompletedOnboarding")

    private static func key(_ name: String) -> String {
        AppLaunchConfiguration.usesIsolatedTestStore
            ? "settings.test.\(name)"
            : "settings.\(name)"
    }
}
