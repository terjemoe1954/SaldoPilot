//
//  SaldoPilotApp.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import SwiftData
import SwiftUI

@main
struct SaldoPilotApp: App {
    @AppStorage(AppSettingsKey.appearance) private var appearanceRawValue = AppAppearance.system.rawValue
    @AppStorage(AppSettingsKey.language) private var languageRawValue = AppLanguage.system.rawValue

    private let modelContainer: ModelContainer = {
        let schema = Schema(SaldoPilotSchemaV1.models)

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
                .preferredColorScheme(selectedAppearance.colorScheme)
                .environment(\.locale, selectedLanguage.locale)
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
