//
//  AppRouter.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import Foundation

enum AppRoute: Hashable {
    case root
}

struct AppRouter {
    var route: AppRoute = .root
}
