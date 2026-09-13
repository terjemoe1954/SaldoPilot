//
//  DecimalFormatting.swift
//  SaldoPilot
//
//  Created by Terje Moe on 13/09/2026.
//

import Foundation

extension Decimal {
    var formattedCurrency: String {
        let value = NSDecimalNumber(decimal: self).doubleValue
        let currencyCode = Locale.current.currency?.identifier ?? "NOK"
        return value.formatted(.currency(code: currencyCode))
    }
}
