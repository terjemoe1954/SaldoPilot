//
//  SettingsView.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("Manage") {
                    NavigationLink {
                        CategoriesView()
                    } label: {
                        Label("Categories", systemImage: "tag")
                    }
                }

                Section("App") {
                    LabeledContent("Name", value: "SaldoPilot")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
