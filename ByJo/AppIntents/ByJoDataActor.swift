//
//  ByJoDataActor.swift
//  ByJo
//

import Foundation
import SwiftData
import WidgetKit

@ModelActor
actor ByJoDataActor {
    func fetchAssets() throws -> [AssetEntity] {
        let assets = try modelContext.fetch(FetchDescriptor<Asset>(sortBy: [SortDescriptor(\.name)]))
        return assets.map { AssetEntity(id: $0.id.uuidString, name: $0.name) }
    }

    func fetchCategories() throws -> [CategoryEntity] {
        let categories = try modelContext.fetch(FetchDescriptor<CategoryOperation>(sortBy: [SortDescriptor(\.name)]))
        return categories.map { CategoryEntity(id: $0.id.uuidString, name: $0.name) }
    }

    func addOperation(assetId: UUID, name: String, amount: Decimal, categoryId: UUID?, note: String) throws -> String {
        let predicate = #Predicate<Asset> { $0.id == assetId }
        guard let asset = try modelContext.fetch(FetchDescriptor<Asset>(predicate: predicate)).first else {
            throw ByJoIntentError.assetNotFound
        }
        var category: CategoryOperation? = nil
        if let categoryId {
            let catPredicate = #Predicate<CategoryOperation> { $0.id == categoryId }
            category = try modelContext.fetch(FetchDescriptor<CategoryOperation>(predicate: catPredicate)).first
        }
        let operation = AssetOperation(name: name, amount: amount, asset: asset, category: category, note: note)
        modelContext.insert(operation)
        try modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        return asset.name
    }

    func addSwap(fromAssetId: UUID, toAssetId: UUID, name: String, amount: Decimal) throws -> (String, String) {
        let fromPredicate = #Predicate<Asset> { $0.id == fromAssetId }
        let toPredicate = #Predicate<Asset> { $0.id == toAssetId }
        guard let fromAsset = try modelContext.fetch(FetchDescriptor<Asset>(predicate: fromPredicate)).first else {
            throw ByJoIntentError.assetNotFound
        }
        guard let toAsset = try modelContext.fetch(FetchDescriptor<Asset>(predicate: toPredicate)).first else {
            throw ByJoIntentError.assetNotFound
        }
        let swapId = UUID()
        let absAmount = abs(amount)
        let fromOp = AssetOperation(name: name, amount: -absAmount, asset: fromAsset, swapId: swapId)
        let toOp = AssetOperation(name: name, amount: absAmount, asset: toAsset, swapId: swapId)
        modelContext.insert(fromOp)
        modelContext.insert(toOp)
        try modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        return (fromAsset.name, toAsset.name)
    }
}

enum ByJoIntentError: LocalizedError {
    case assetNotFound

    var errorDescription: String? {
        switch self {
        case .assetNotFound: return "Asset not found."
        }
    }
}

func makeIntentModelContainer() throws -> ModelContainer {
    let schema = Schema([Asset.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    return try ModelContainer(for: schema, configurations: [config])
}
