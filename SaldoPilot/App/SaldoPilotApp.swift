//
//  SaldoPilotApp.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import CoreData
import SwiftData
import SwiftUI
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private var cloudKitEventObserver: NSObjectProtocol?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        if AppLaunchConfiguration.usesIsolatedCloudTestStore {
            cloudKitEventObserver = NotificationCenter.default.addObserver(
                forName: NSPersistentCloudKitContainer.eventChangedNotification,
                object: nil,
                queue: .main
            ) { notification in
                guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                        as? NSPersistentCloudKitContainer.Event else { return }
                let state = event.endDate == nil
                    ? "started"
                    : (event.succeeded ? "succeeded" : "failed")
                print(
                    "CloudKit test event type=\(event.type.rawValue) "
                    + "state=\(state) error=\(event.error?.localizedDescription ?? "none")"
                )
            }
        }
        return true
    }

    deinit {
        if let cloudKitEventObserver {
            NotificationCenter.default.removeObserver(cloudKitEventObserver)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}

enum AppLaunchConfiguration {
    private static let persistedTestStoreModeKey = "SaldoPilot.persistedTestStoreMode"

    private static let allowsIsolatedTestStores: Bool = {
#if DEBUG
        true
#else
        false
#endif
    }()

    private static let normalizedArguments = ProcessInfo.processInfo.arguments.map {
        $0.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
            .lowercased()
    }

    private static let explicitlyUsesProductionStore = !allowsIsolatedTestStores
        || normalizedArguments.contains("saldopilotuseproductionstore")
        || environmentFlag(named: "SALDOPILOT_USE_PRODUCTION_STORE")

    static let usesEnglishScreenshotData = allowsIsolatedTestStores
        && normalizedArguments.contains("saldopilotscreenshotmodeenglish")

    static let usesProReviewData = allowsIsolatedTestStores
        && normalizedArguments.contains("saldopilotproreviewmode")

    static let usesScreenshotData = allowsIsolatedTestStores
        && (
            normalizedArguments.contains("saldopilotscreenshotmode")
                || usesEnglishScreenshotData
                || usesProReviewData
        )

    static let usesIsolatedCloudTestStore: Bool = {
        if explicitlyUsesProductionStore {
            UserDefaults.standard.removeObject(forKey: persistedTestStoreModeKey)
            return false
        }

        if usesScreenshotData {
            return false
        }

        if normalizedArguments.contains("saldopilotusecloudteststore")
            || environmentFlag(named: "SALDOPILOT_USE_CLOUD_TEST_STORE") {
            UserDefaults.standard.set("cloud", forKey: persistedTestStoreModeKey)
            return true
        }

        return UserDefaults.standard.string(forKey: persistedTestStoreModeKey) == "cloud"
    }()

    static let usesLocalIsolatedTestStore: Bool = {
        guard !explicitlyUsesProductionStore, !usesIsolatedCloudTestStore else { return false }

        if usesScreenshotData {
            return true
        }

        if normalizedArguments.contains("saldopilotuseteststore")
            || environmentFlag(named: "SALDOPILOT_USE_TEST_STORE") {
            UserDefaults.standard.set("local", forKey: persistedTestStoreModeKey)
            return true
        }

        return UserDefaults.standard.string(forKey: persistedTestStoreModeKey) == "local"
    }()

    static var usesIsolatedTestStore: Bool {
        usesLocalIsolatedTestStore || usesIsolatedCloudTestStore
    }

    static let simulatesICloudUnavailable = usesIsolatedCloudTestStore
        && (normalizedArguments.contains("saldopilotsimulateicloudunavailable")
            || environmentFlag(named: "SALDOPILOT_SIMULATE_ICLOUD_UNAVAILABLE"))

    static var activeCloudContainerIdentifier: String? {
        guard !usesLocalIsolatedTestStore else { return nil }
        return usesIsolatedCloudTestStore
            ? "iCloud.com.terjemoe.SaldoPilot.Test"
            : "iCloud.com.terjemoe.SaldoPilot"
    }

    static var isolatedTestStoreURL: URL {
        if usesScreenshotData {
            return URL.applicationSupportDirectory
                .appending(
                    path: usesEnglishScreenshotData
                        ? "SaldoPilot-Screenshot-English-v1.store"
                        : usesProReviewData
                            ? "SaldoPilot-Pro-Review-v1.store"
                            : "SaldoPilot-Screenshot-v2.store",
                    directoryHint: .notDirectory
                )
        }
        return URL.applicationSupportDirectory
            .appending(path: "SaldoPilot-Isolated-Test.store", directoryHint: .notDirectory)
    }

    static var isolatedCloudTestStoreURL: URL {
        URL.applicationSupportDirectory
            .appending(path: "SaldoPilot-Isolated-Cloud-Test.store", directoryHint: .notDirectory)
    }

    static let syntheticTransactionCount: Int = {
        guard usesLocalIsolatedTestStore, !usesIsolatedCloudTestStore, !usesScreenshotData else { return 0 }
        let value = ProcessInfo.processInfo.environment["SALDOPILOT_SYNTHETIC_TRANSACTION_COUNT"]
        return min(max(Int(value ?? "") ?? 0, 0), 10_000)
    }()

    private static func environmentFlag(named name: String) -> Bool {
        guard let value = ProcessInfo.processInfo.environment[name]?.lowercased() else { return false }
        return value == "1" || value == "yes" || value == "true"
    }
}

@main
struct SaldoPilotApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(AppSettingsKey.appearance) private var appearanceRawValue = AppAppearance.system.rawValue
    @AppStorage(AppSettingsKey.language) private var languageRawValue = AppLanguage.system.rawValue
    @State private var proPurchaseStore = ProPurchaseStore()
    @State private var networkStatusMonitor = NetworkStatusMonitor()

    private let modelContainer: ModelContainer = {
        let schema = Schema(SaldoPilotSchemaV4.models)

        if AppLaunchConfiguration.usesIsolatedCloudTestStore {
            let testCloudConfiguration = ModelConfiguration(
                "SaldoPilotIsolatedCloudTest",
                schema: schema,
                url: AppLaunchConfiguration.isolatedCloudTestStoreURL,
                cloudKitDatabase: .private("iCloud.com.terjemoe.SaldoPilot.Test")
            )

            do {
                return try ModelContainer(
                    for: schema,
                    migrationPlan: SaldoPilotMigrationPlan.self,
                    configurations: [testCloudConfiguration]
                )
            } catch {
                fatalError("Could not create isolated CloudKit test container: \(error)")
            }
        }

        if AppLaunchConfiguration.usesLocalIsolatedTestStore {
            let testConfiguration = ModelConfiguration(
                "SaldoPilotIsolatedTest",
                schema: schema,
                url: AppLaunchConfiguration.isolatedTestStoreURL,
                cloudKitDatabase: .none
            )

            do {
                let container = try ModelContainer(
                    for: schema,
                    migrationPlan: SaldoPilotMigrationPlan.self,
                    configurations: [testConfiguration]
                )
                try SampleData.ensureSyntheticTransactions(
                    count: AppLaunchConfiguration.syntheticTransactionCount,
                    in: container.mainContext
                )
                if AppLaunchConfiguration.usesScreenshotData {
                    try SampleData.ensureScreenshotData(
                        in: container.mainContext,
                        language: AppLaunchConfiguration.usesEnglishScreenshotData ? .english : .norwegian
                    )
                    UserDefaults.standard.set(true, forKey: AppSettingsKey.hasCompletedOnboarding)
                    let screenshotLanguage: AppLanguage = AppLaunchConfiguration.usesEnglishScreenshotData ? .english : .norwegian
                    UserDefaults.standard.set(screenshotLanguage.rawValue, forKey: AppSettingsKey.language)
                    UserDefaults.standard.set(AppAppearance.light.rawValue, forKey: AppSettingsKey.appearance)
                    UserDefaults.standard.set(AppProStatus.pro.rawValue, forKey: AppSettingsKey.proStatus)
                    UserDefaults.standard.set("10000", forKey: AppSettingsKey.openingBalanceAmount)
                    let monthStart = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? Date.now
                    UserDefaults.standard.set(monthStart.timeIntervalSince1970, forKey: AppSettingsKey.openingBalanceDate)
                }
                return container
            } catch {
                fatalError("Could not create isolated test model container: \(error)")
            }
        }

        do {
            let cloudConfiguration = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private("iCloud.com.terjemoe.SaldoPilot")
            )
            return try ModelContainer(
                for: schema,
                migrationPlan: SaldoPilotMigrationPlan.self,
                configurations: [cloudConfiguration]
            )
        } catch {
            print("CloudKit SwiftData container failed, falling back to local storage: \(error)")
        }

        do {
            let localConfiguration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
            return try ModelContainer(
                for: schema,
                migrationPlan: SaldoPilotMigrationPlan.self,
                configurations: [localConfiguration]
            )
        } catch {
            fatalError("Could not create local SwiftData model container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .safeAreaInset(edge: .top, spacing: 0) {
                    AppStatusBanners(
                        isICloudUnavailable: networkStatusMonitor.isICloudUnavailable,
                        isOffline: networkStatusMonitor.isOffline
                    )
                }
                .preferredColorScheme(selectedAppearance.colorScheme)
                .environment(\.locale, selectedLanguage.locale)
                .environment(proPurchaseStore)
                .task {
                    try? CategoryStandardizationService.standardize(in: modelContainer.mainContext)
                    networkStatusMonitor.start(
                        cloudContainerIdentifier: AppLaunchConfiguration.activeCloudContainerIdentifier,
                        simulatesICloudUnavailable: AppLaunchConfiguration.simulatesICloudUnavailable
                    )
                }
        }
        .modelContainer(modelContainer)
    }

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appearanceRawValue) ?? .system
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .system
    }
}

private struct AppStatusBanners: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let isICloudUnavailable: Bool
    let isOffline: Bool

    var body: some View {
        VStack(spacing: 0) {
            if isICloudUnavailable {
                AppStatusBanner(
                    title: "ICLOUD UNAVAILABLE — CHANGES ARE SAVED ON THIS DEVICE",
                    systemImage: "icloud.slash",
                    color: Color(red: 0.54, green: 0.11, blue: 0.11),
                    usesCompactLayout: dynamicTypeSize.isAccessibilitySize
                )
            } else if !AppLaunchConfiguration.usesLocalIsolatedTestStore, isOffline {
                AppStatusBanner(
                    title: "OFFLINE — CHANGES WILL SYNC WHEN CONNECTED",
                    systemImage: "wifi.slash",
                    color: Color(red: 0.54, green: 0.11, blue: 0.11),
                    usesCompactLayout: dynamicTypeSize.isAccessibilitySize
                )
            }
        }
    }
}

private struct AppStatusBanner: View {
    let title: LocalizedStringKey
    let systemImage: String
    let color: Color
    let usesCompactLayout: Bool

    var body: some View {
        HStack {
            Image(systemName: systemImage)

            if !usesCompactLayout {
                Text(title)
            }
        }
        .font(.caption.bold())
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .foregroundStyle(.white)
        .background(color)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
    }
}
