import Foundation
import SwiftData
import SwiftUI

typealias CategoryDefinition = SaldoPilotSchemaV5.CategoryDefinition

extension SaldoPilotSchemaV5 {
    @Model
    final class CategoryDefinition {
        var id: String = UUID().uuidString
        var name: String = ""
        var systemImage: String = "tag"
        var colorName: String = "blue"
        var legacyKindRawValue: String?
        var isHidden: Bool = false
        var excludesFromSavingsTips: Bool?
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now

        init(
            id: String = UUID().uuidString,
            name: String,
            systemImage: String = "tag",
            colorName: String = "blue",
            legacyKindRawValue: String? = nil,
            isHidden: Bool = false,
            excludesFromSavingsTips: Bool? = nil,
            createdAt: Date = .now,
            updatedAt: Date = .now
        ) {
            self.id = id
            self.name = name
            self.systemImage = systemImage
            self.colorName = colorName
            self.legacyKindRawValue = legacyKindRawValue
            self.isHidden = isHidden
            self.excludesFromSavingsTips = excludesFromSavingsTips
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }
}

struct CategoryOption: Identifiable, Hashable {
    let id: String
    let name: String
    let systemImage: String
    let colorName: String
    let legacyKind: CategoryKind?
    var excludesFromSavingsTips: Bool = false

    static func excludesFromSavingsTips(id: String, definitions: [CategoryDefinition]) -> Bool {
        if let value = preferredDefinitions(definitions)[id]?.excludesFromSavingsTips { return value }
        return [CategoryKind.home.rawValue, CategoryKind.insurance.rawValue, CategoryKind.deduction.rawValue].contains(id)
    }

    // CloudKit can deliver multiple records for a logical category ID.
    // Resolve these in memory; never delete records while building the UI.
    static func preferredDefinitions(_ definitions: [CategoryDefinition]) -> [String: CategoryDefinition] {
        definitions.reduce(into: [:]) { result, candidate in
            guard let current = result[candidate.id] else {
                result[candidate.id] = candidate
                return
            }
            func tieBreak(_ value: CategoryDefinition) -> String {
                [value.name, value.systemImage, value.colorName,
                 value.legacyKindRawValue ?? "", String(value.isHidden),
                 value.excludesFromSavingsTips.map { String($0) } ?? "nil"].joined(separator: "\u{0}")
            }
            if candidate.updatedAt > current.updatedAt
                || (candidate.updatedAt == current.updatedAt && candidate.createdAt > current.createdAt)
                || (candidate.updatedAt == current.updatedAt && candidate.createdAt == current.createdAt
                    && tieBreak(candidate) > tieBreak(current)) {
                result[candidate.id] = candidate
            }
        }
    }

    var tint: Color {
        switch colorName {
        case "red": .red
        case "orange": .orange
        case "yellow": .yellow
        case "green": .green
        case "mint": .mint
        case "teal": .teal
        case "cyan": .cyan
        case "indigo": .indigo
        case "purple": .purple
        case "pink": .pink
        case "brown": .brown
        case "gray": .gray
        case "black": .black
        default: .blue
        }
    }

    static func available(definitions: [CategoryDefinition], locale: Locale) -> [CategoryOption] {
        let definitionsByID = preferredDefinitions(definitions)
        let standard = CategoryKind.allCases.compactMap { kind -> CategoryOption? in
            let definition = definitionsByID[kind.rawValue]
            guard definition?.isHidden != true else { return nil }
            return CategoryOption(
                id: kind.rawValue,
                name: definition?.name.nilIfBlank ?? kind.localizedTitle(locale: locale),
                systemImage: definition?.systemImage ?? kind.systemImage,
                colorName: definition?.colorName ?? kind.colorName,
                legacyKind: kind,
                excludesFromSavingsTips: excludesFromSavingsTips(id: kind.rawValue, definitions: definitions)
            )
        }
        let custom = definitionsByID.values.filter { CategoryKind(rawValue: $0.id) == nil && $0.legacyKindRawValue == nil && !$0.isHidden }.map {
            CategoryOption(id: $0.id, name: $0.name, systemImage: $0.systemImage, colorName: $0.colorName, legacyKind: nil, excludesFromSavingsTips: $0.excludesFromSavingsTips ?? false)
        }
        return (standard + custom).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func resolve(id: String, definitions: [CategoryDefinition], locale: Locale) -> CategoryOption {
        available(definitions: definitions, locale: locale).first { $0.id == id }
            ?? CategoryOption(id: CategoryKind.other.rawValue, name: CategoryKind.other.localizedTitle(locale: locale), systemImage: CategoryKind.other.systemImage, colorName: CategoryKind.other.colorName, legacyKind: .other)
    }
}

private extension String {
    var nilIfBlank: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
