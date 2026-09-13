//
//  StatisticsView.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import SwiftUI

struct StatisticsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Statistics",
                systemImage: "chart.bar.xaxis",
                description: Text("Charts and key figures will arrive later.")
            )
            .navigationTitle("Statistics")
        }
    }
}

#Preview {
    StatisticsView()
}
