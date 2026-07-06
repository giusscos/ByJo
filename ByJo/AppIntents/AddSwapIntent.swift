//
//  AddSwapIntent.swift
//  ByJo
//

import AppIntents

struct AddSwapIntent: AppIntent {
    static var title: LocalizedStringResource = "Transfer Between Assets"
    static var description = IntentDescription("Move funds from one asset to another in ByJo.")

    @Parameter(title: "From Asset")
    var fromAsset: AssetEntity

    @Parameter(title: "To Asset")
    var toAsset: AssetEntity

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Name", default: "Transfer")
    var name: String

    static var parameterSummary: some ParameterSummary {
        Summary("Transfer \(\.$amount) from \(\.$fromAsset) to \(\.$toAsset)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let fromId = UUID(uuidString: fromAsset.id),
              let toId = UUID(uuidString: toAsset.id) else {
            throw ByJoIntentError.assetNotFound
        }
        let container = try makeIntentModelContainer()
        let actor = ByJoDataActor(modelContainer: container)
        let (fromName, toName) = try await actor.addSwap(
            fromAssetId: fromId,
            toAssetId: toId,
            name: name,
            amount: Decimal(amount)
        )
        let formatted = Decimal(amount).formatted(.number.precision(.fractionLength(0...2)))
        return .result(dialog: "Transferred \(formatted) from \(fromName) to \(toName).")
    }
}
