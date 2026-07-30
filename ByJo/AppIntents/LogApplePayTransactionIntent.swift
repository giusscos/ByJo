//
//  LogApplePayTransactionIntent.swift
//  ByJo
//

import AppIntents

struct LogApplePayTransactionIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Apple Pay Transaction"
    static var description = IntentDescription(
        "Log an Apple Pay tap as an expense in ByJo. Map Shortcut Input Amount and Merchant from a Wallet/Transaction automation."
    )

    @Parameter(title: "Merchant")
    var merchant: String

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Asset")
    var asset: AssetEntity

    @Parameter(title: "Category")
    var category: CategoryEntity?

    @Parameter(title: "Card", default: "")
    var card: String

    static var parameterSummary: some ParameterSummary {
        Summary("Log Apple Pay \"\(\.$merchant)\" of \(\.$amount) to \(\.$asset)") {
            \.$category
            \.$card
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let assetId = UUID(uuidString: asset.id) else {
            throw ByJoIntentError.assetNotFound
        }

        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmedMerchant.isEmpty ? "Apple Pay" : trimmedMerchant
        let expenseAmount = Decimal(-abs(amount))
        let trimmedCard = card.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = trimmedCard.isEmpty ? "Apple Pay" : "Apple Pay · \(trimmedCard)"
        let categoryId = category.flatMap { UUID(uuidString: $0.id) }

        let container = try makeIntentModelContainer()
        let actor = ByJoDataActor(modelContainer: container)
        let assetName = try await actor.addOperation(
            assetId: assetId,
            name: name,
            amount: expenseAmount,
            categoryId: categoryId,
            note: note
        )

        let formatted = abs(Decimal(amount)).formatted(.number.precision(.fractionLength(0...2)))
        return .result(dialog: "Logged \(name) (\(formatted)) to \(assetName).")
    }
}
