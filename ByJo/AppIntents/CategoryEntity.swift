//
//  CategoryEntity.swift
//  ByJo
//

import AppIntents
import SwiftData

struct CategoryEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static var defaultQuery = CategoryEntityQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: name))
    }

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

struct CategoryEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CategoryEntity] {
        let all = try await fetchAll()
        return all.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [CategoryEntity] {
        try await fetchAll()
    }

    private func fetchAll() async throws -> [CategoryEntity] {
        let container = try makeIntentModelContainer()
        let actor = ByJoDataActor(modelContainer: container)
        return try await actor.fetchCategories()
    }
}
