//
//  SaldoPilotSchema.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import SwiftData

enum SaldoPilotSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            Transaction.self
        ]
    }
}

enum SaldoPilotMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SaldoPilotSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
