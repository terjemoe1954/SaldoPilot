//
//  AIPrivacyView.swift
//  SaldoPilot
//
//  Created by Terje Moe on 13/09/2026.
//

import SwiftUI

struct AIPrivacyView: View {
    @AppStorage(AppSettingsKey.allowExternalAI) private var allowExternalAI = false

    var body: some View {
        Form {
            Section("Current AI mode") {
                Label("AI runs locally on this device", systemImage: "iphone")
                Label("No transaction data is sent to an external AI service", systemImage: "lock.shield")
                Label("AI suggestions never change transactions automatically", systemImage: "checkmark.shield")
            }

            Section("Data minimization") {
                AIPrivacyInfoRow(
                    title: "Used locally",
                    detail: "Transaction title, amount, date, type, status and category."
                )
                AIPrivacyInfoRow(
                    title: "Avoided unless needed",
                    detail: "Personal name, notes and settings that are not required for the question."
                )
                AIPrivacyInfoRow(
                    title: "External AI",
                    detail: "If enabled later, only the minimum data needed for the specific request should be sent."
                )
            }

            Section("Consent") {
                Toggle("Allow external AI processing", isOn: $allowExternalAI)
                Text("This does not send data today. It records consent for future features that may need external processing.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Model choice") {
                AIPrivacyInfoRow(
                    title: "Preferred",
                    detail: "Use local logic or Apple Foundation Models on device when available and suitable."
                )
                AIPrivacyInfoRow(
                    title: "Server AI",
                    detail: "Consider only for features that cannot run locally, and only after clear consent."
                )
            }

            Section("Privacy policy") {
                Text("Update the privacy policy before enabling any feature that sends transaction data outside the device.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("AI & Privacy")
    }
}

private struct AIPrivacyInfoRow: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        AIPrivacyView()
    }
}
