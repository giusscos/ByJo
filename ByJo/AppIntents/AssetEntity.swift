//
//  AssetEntity.swift
//  ByJo
//

import AppIntents
import SwiftData

struct AssetEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Asset"
    static var defaultQuery = AssetEntityQuery()

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

struct AssetEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [AssetEntity] {
        let all = try await fetchAll()
        return all.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [AssetEntity] {
        try await fetchAll()
    }

    private func fetchAll() async throws -> [AssetEntity] {
        let container = try makeIntentModelContainer()
        let actor = ByJoDataActor(modelContainer: container)
        return try await actor.fetchAssets()
    }
}
