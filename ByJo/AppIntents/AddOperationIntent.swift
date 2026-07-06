//
//  AddOperationIntent.swift
//  ByJo
//

import AppIntents

struct AddOperationIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Operation"
    static var description = IntentDescription("Log a financial operation to an asset in ByJo. Use a positive amount for an inflow and a negative amount for an outflow.")

    @Parameter(title: "Asset")
    var asset: AssetEntity

    @Parameter(title: "Name")
    var name: String

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Category")
    var category: CategoryEntity

    @Parameter(title: "Note")
    var note: String

    static var parameterSummary: some ParameterSummary {
        Summary("Add \"\(\.$name)\" of \(\.$amount) to \(\.$asset)") {
            \.$category
            \.$note
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let assetId = UUID(uuidString: asset.id) else {
            throw ByJoIntentError.assetNotFound
        }
        let categoryId = UUID(uuidString: category.id)
        let container = try makeIntentModelContainer()
        let actor = ByJoDataActor(modelContainer: container)
        let assetName = try await actor.addOperation(
            assetId: assetId,
            name: name,
            amount: Decimal(amount),
            categoryId: categoryId,
            note: note
        )
        return .result(dialog: "Added \(name) to \(assetName).")
    }
}
