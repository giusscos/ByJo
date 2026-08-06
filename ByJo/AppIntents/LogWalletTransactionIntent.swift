//
//  LogWalletTransactionIntent.swift
//  ByJo
//

import AppIntents

struct LogWalletTransactionIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Wallet Transaction"
    static var description = IntentDescription(
        "Log a Wallet card tap as an expense in ByJo. Missing assets and categories are created automatically from the names you pass."
    )

    @Parameter(title: "Merchant")
    var merchant: String

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Asset Name")
    var assetName: String

    @Parameter(title: "Category Name", default: "")
    var categoryName: String

    @Parameter(title: "Card", default: "")
    var card: String

    static var parameterSummary: some ParameterSummary {
        Summary("Log Wallet \"\(\.$merchant)\" of \(\.$amount) to \(\.$assetName)") {
            \.$categoryName
            \.$card
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmedAsset = assetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAsset.isEmpty else {
            throw ByJoIntentError.invalidAssetName
        }

        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmedMerchant.isEmpty ? "Card tap" : trimmedMerchant
        let expenseAmount = Decimal(-abs(amount))
        let trimmedCard = card.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = trimmedCard.isEmpty ? "Wallet" : "Wallet · \(trimmedCard)"
        let trimmedCategory = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)

        let container = try makeIntentModelContainer()
        let actor = ByJoDataActor(modelContainer: container)
        let resolvedAssetName = try await actor.addWalletOperation(
            merchant: name,
            amount: expenseAmount,
            assetName: trimmedAsset,
            categoryName: trimmedCategory.isEmpty ? nil : trimmedCategory,
            note: note
        )

        let formatted = abs(Decimal(amount)).formatted(.number.precision(.fractionLength(0...2)))
        return .result(dialog: IntentDialog(stringLiteral: String(format: String(localized: "Logged %@ (%@) to %@."), name, formatted, resolvedAssetName)))
    }
}
