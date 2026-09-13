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

    private let modelContainer: ModelContainer = {
        do {
            let schema = Schema(SaldoPilotSchemaV1.models)
            return try ModelContainer(for: schema, migrationPlan: SaldoPilotMigrationPlan.self)
        } catch {
            fatalError("Could not create SwiftData model container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(selectedAppearance.colorScheme)
        }
        .modelContainer(modelContainer)
    }

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appearanceRawValue) ?? .system
    }
}
