//
//  PendingOnboardingData.swift
//  ByJo
//

import Foundation

struct PendingOnboardingData: Codable {
    var assetName: String
    var assetType: String
    var assetBalance: String
    var assetNegativeBalance: Bool
    var categoryName: String
    var operationName: String
    var operationAmount: String
    var operationIsExpense: Bool
    var recurringName: String
    var recurringAmount: String
    var recurringIsExpense: Bool
    var recurringFrequency: String

    private static let storageKey = "pendingOnboardingData"

    static func load() -> PendingOnboardingData? {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(PendingOnboardingData.self, from: data)
        else { return nil }
        return decoded
    }

    func save() {
        guard let encoded = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(encoded, forKey: Self.storageKey)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
