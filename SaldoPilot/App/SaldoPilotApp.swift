//
//  SaldoPilotApp.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import SwiftData
import SwiftUI
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}

enum AppLaunchConfiguration {
    static let usesIsolatedTestStore: Bool = {
        let normalizedArguments = ProcessInfo.processInfo.arguments.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
                .lowercased()
        }
        let environmentValue = ProcessInfo.processInfo.environment["SALDOPILOT_USE_TEST_STORE"]?.lowercased()

        return normalizedArguments.contains("saldopilotuseteststore")
            || environmentValue == "1"
            || environmentValue == "yes"
            || environmentValue == "true"
    }()
}

@main
struct SaldoPilotApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(AppSettingsKey.appearance) private var appearanceRawValue = AppAppearance.system.rawValue
    @AppStorage(AppSettingsKey.language) private var languageRawValue = AppLanguage.system.rawValue
    @State private var proPurchaseStore = ProPurchaseStore()

    private let modelContainer: ModelContainer = {
        let schema = Schema(SaldoPilotSchemaV2.models)

        if AppLaunchConfiguration.usesIsolatedTestStore {
            let testConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )

            do {
                return try ModelContainer(
                    for: schema,
                    migrationPlan: SaldoPilotMigrationPlan.self,
                    configurations: [testConfiguration]
                )
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
                    if AppLaunchConfiguration.usesIsolatedTestStore {
                        Label("ISOLATED TEST DATA", systemImage: "checkmark.shield.fill")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .foregroundStyle(.white)
                            .background(.orange)
                    }
                }
                .preferredColorScheme(selectedAppearance.colorScheme)
                .environment(\.locale, selectedLanguage.locale)
                .environment(proPurchaseStore)
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
