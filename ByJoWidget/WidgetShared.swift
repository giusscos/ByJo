//
//  WidgetShared.swift
//  Shared between ByJo and ByJoWidget targets.
//  Select this file in Xcode → File Inspector → add ByJo to Target Membership.
//

import Foundation

// MARK: - App Group
let kAppGroupIdentifier = "group.com.giusscos.byjo"

// MARK: - UserDefaults keys
enum WidgetKey: String {
    case netWorth    = "widget.netWorth"
    case spendmeter  = "widget.spendmeter"
    case assetAlloc  = "widget.assetAlloc"
    case recurring   = "widget.recurring"
    case savingsRate = "widget.savingsRate"
    case goals       = "widget.goals"
}

// MARK: - Transfer objects

struct WNetWorthData: Codable {
    struct AssetRow: Codable, Identifiable {
        var id: String; var name: String; var balance: Double; var colorIndex: Int
    }
    var netWorth: Double
    var currencyCode: String
    var compactNumber: Bool
    var assets: [AssetRow]
    var updatedAt: Date
}

struct WSpendmeterData: Codable {
    var inflow: Double; var outflow: Double; var savedAmount: Double
    var ratio: Double; var currencyCode: String; var updatedAt: Date
}

struct WAssetAllocData: Codable {
    struct Slice: Codable, Identifiable {
        var id: String; var label: String; var value: Double; var colorIndex: Int
    }
    var slices: [Slice]; var currencyCode: String; var updatedAt: Date
}

struct WRecurringData: Codable {
    struct Item: Codable, Identifiable {
        var id: String; var name: String; var amount: Double
        var nextDate: Date; var frequencyLabel: String; var assetName: String; var isInflow: Bool
    }
    var items: [Item]; var currencyCode: String; var updatedAt: Date
}

struct WSavingsRateData: Codable {
    var rate: Double; var inflow: Double; var outflow: Double
    var currencyCode: String; var updatedAt: Date
}

struct WGoalData: Codable {
    struct GoalItem: Codable, Identifiable {
        var id: String; var title: String; var currentAmount: Double
        var targetAmount: Double; var startingAmount: Double
        var assetName: String; var dueDate: Date?; var progress: Double
    }
    var goals: [GoalItem]; var currencyCode: String; var updatedAt: Date
}

// MARK: - UserDefaults helpers
extension UserDefaults {
    static var appGroup: UserDefaults? { UserDefaults(suiteName: kAppGroupIdentifier) }

    func decode<T: Codable>(_ type: T.Type, forKey key: WidgetKey) -> T? {
        guard let data = self.data(forKey: key.rawValue) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(T.self, from: data)
    }

    func encode<T: Codable>(_ value: T, forKey key: WidgetKey) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(value) { self.set(data, forKey: key.rawValue) }
    }
}
