import Foundation

struct BackupAppSettings: Codable, Equatable {
    let appearance: String
    let language: String
    let showNameOnDashboard: Bool
    let displayName: String
    let showCompletedStatus: Bool
    let showSettledTransactions: Bool
    let defaultPeriod: String
    let defaultDateType: String
    let notifyDueToday: Bool
    let notifyDueTomorrow: Bool
    let notifyDueInAdvance: Bool
    let notificationAdvanceDays: Int
    let notifyPendingIncome: Bool
    let openingBalanceAmount: String
    let openingBalanceDate: Double?

    static func capture(from defaults: UserDefaults = .standard) -> BackupAppSettings {
        BackupAppSettings(
            appearance: defaults.string(forKey: AppSettingsKey.appearance) ?? AppAppearance.system.rawValue,
            language: defaults.string(forKey: AppSettingsKey.language) ?? AppLanguage.system.rawValue,
            showNameOnDashboard: defaults.bool(forKey: AppSettingsKey.showNameOnDashboard),
            displayName: defaults.string(forKey: AppSettingsKey.displayName) ?? "",
            showCompletedStatus: defaults.optionalBool(forKey: AppSettingsKey.showCompletedStatus) ?? true,
            showSettledTransactions: defaults.optionalBool(forKey: AppSettingsKey.showSettledTransactions) ?? true,
            defaultPeriod: defaults.string(forKey: AppSettingsKey.defaultPeriod) ?? AppDefaultPeriod.thisMonth.rawValue,
            defaultDateType: defaults.string(forKey: AppSettingsKey.defaultDateType) ?? AppDefaultDateType.dueDate.rawValue,
            notifyDueToday: defaults.bool(forKey: AppSettingsKey.notifyDueToday),
            notifyDueTomorrow: defaults.bool(forKey: AppSettingsKey.notifyDueTomorrow),
            notifyDueInAdvance: defaults.bool(forKey: AppSettingsKey.notifyDueInAdvance),
            notificationAdvanceDays: defaults.object(forKey: AppSettingsKey.notificationAdvanceDays) as? Int ?? 7,
            notifyPendingIncome: defaults.bool(forKey: AppSettingsKey.notifyPendingIncome),
            openingBalanceAmount: defaults.string(forKey: AppSettingsKey.openingBalanceAmount) ?? "",
            openingBalanceDate: defaults.object(forKey: AppSettingsKey.openingBalanceDate) as? Double
        )
    }

    func apply(to defaults: UserDefaults = .standard) {
        if AppAppearance(rawValue: appearance) != nil {
            defaults.set(appearance, forKey: AppSettingsKey.appearance)
        }
        if AppLanguage(rawValue: language) != nil {
            defaults.set(language, forKey: AppSettingsKey.language)
        }
        defaults.set(showNameOnDashboard, forKey: AppSettingsKey.showNameOnDashboard)
        defaults.set(displayName, forKey: AppSettingsKey.displayName)
        defaults.set(showCompletedStatus, forKey: AppSettingsKey.showCompletedStatus)
        defaults.set(showSettledTransactions, forKey: AppSettingsKey.showSettledTransactions)
        if AppDefaultPeriod(rawValue: defaultPeriod) != nil {
            defaults.set(defaultPeriod, forKey: AppSettingsKey.defaultPeriod)
        }
        if AppDefaultDateType(rawValue: defaultDateType) != nil {
            defaults.set(defaultDateType, forKey: AppSettingsKey.defaultDateType)
        }
        defaults.set(notifyDueToday, forKey: AppSettingsKey.notifyDueToday)
        defaults.set(notifyDueTomorrow, forKey: AppSettingsKey.notifyDueTomorrow)
        defaults.set(notifyDueInAdvance, forKey: AppSettingsKey.notifyDueInAdvance)
        defaults.set(max(1, min(notificationAdvanceDays, 30)), forKey: AppSettingsKey.notificationAdvanceDays)
        defaults.set(notifyPendingIncome, forKey: AppSettingsKey.notifyPendingIncome)
        defaults.set(openingBalanceAmount, forKey: AppSettingsKey.openingBalanceAmount)
        if let openingBalanceDate {
            defaults.set(openingBalanceDate, forKey: AppSettingsKey.openingBalanceDate)
        } else {
            defaults.removeObject(forKey: AppSettingsKey.openingBalanceDate)
        }
    }
}

private extension UserDefaults {
    func optionalBool(forKey key: String) -> Bool? {
        guard object(forKey: key) != nil else { return nil }
        return bool(forKey: key)
    }
}
