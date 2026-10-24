import Foundation
import SwiftData
import SwiftUI

typealias CategoryDefinition = SaldoPilotSchemaV4.CategoryDefinition

extension SaldoPilotSchemaV4 {
    @Model
    final class CategoryDefinition {
        var id: String = UUID().uuidString
        var name: String = ""
        var systemImage: String = "tag"
        var colorName: String = "blue"
        var legacyKindRawValue: String?
        var isHidden: Bool = false
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now

        init(
            id: String = UUID().uuidString,
            name: String,
            systemImage: String = "tag",
            colorName: String = "blue",
            legacyKindRawValue: String? = nil,
            isHidden: Bool = false,
            createdAt: Date = .now,
            updatedAt: Date = .now
        ) {
            self.id = id
            self.name = name
            self.systemImage = systemImage
            self.colorName = colorName
            self.legacyKindRawValue = legacyKindRawValue
            self.isHidden = isHidden
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
        let definitionsByID = Dictionary(uniqueKeysWithValues: definitions.map { ($0.id, $0) })
        let standard = CategoryKind.allCases.compactMap { kind -> CategoryOption? in
            let definition = definitionsByID[kind.rawValue]
            guard definition?.isHidden != true else { return nil }
            return CategoryOption(
                id: kind.rawValue,
                name: definition?.name.nilIfBlank ?? kind.localizedTitle(locale: locale),
                systemImage: definition?.systemImage ?? kind.systemImage,
                colorName: definition?.colorName ?? kind.colorName,
                legacyKind: kind
            )
        }
        let custom = definitions.filter { $0.legacyKindRawValue == nil && !$0.isHidden }.map {
            CategoryOption(id: $0.id, name: $0.name, systemImage: $0.systemImage, colorName: $0.colorName, legacyKind: nil)
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
