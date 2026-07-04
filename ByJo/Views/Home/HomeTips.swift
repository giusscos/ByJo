//
//  HomeTips.swift
//  ByJo
//

import TipKit

struct AddAssetTip: Tip {
    @Parameter
    static var hasAssets: Bool = true

    var rules: [Rule] {
        [#Rule(Self.$hasAssets) { !$0 }]
    }

    var title: Text {
        Text("Add your first asset")
    }

    var message: Text? {
        Text("Tap here to add a bank account, investment, or any item with financial value to start tracking your net worth.")
    }

    var image: Image? {
        Image(systemName: "building.columns.fill")
    }
}

struct AddOperationTip: Tip {
    @Parameter
    static var isReady: Bool = false

    var rules: [Rule] {
        [#Rule(Self.$isReady) { $0 }]
    }

    var title: Text {
        Text("Log your first transaction")
    }

    var message: Text? {
        Text("Tap + to record income or expenses and keep your balances up to date.")
    }

    var image: Image? {
        Image(systemName: "arrow.up.arrow.down.circle.fill")
    }
}
