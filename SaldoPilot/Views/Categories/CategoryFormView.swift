//
//  CategoryFormView.swift
//  SaldoPilot
//
//  Created by Terje Moe on 13/09/2026.
//

import SwiftUI

struct CategoryFormView: View {
    var body: some View {
        ContentUnavailableView(
            "Standard categories",
            systemImage: "tag",
            description: Text("Categories are fixed and translated automatically.")
        )
    }
}

#Preview {
    CategoryFormView()
}
