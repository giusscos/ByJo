//
//  OnboardingView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 30/06/26.
//

import SwiftUI
import SwiftData

// MARK: - Navigation Step

private enum OnboardingStep: Hashable {
    case firstAsset
    case plans
}

// MARK: - Root Container

/// First-run flow: Welcome → first asset (skippable) → ByJo Pro plans, where the user
/// can start the trial or continue on the free plan.
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    @AppStorage("whatsNewVersion") private var whatsNewVersion: String = ""
    var store: Store
    var onComplete: () -> Void

    @State private var path: [OnboardingStep] = []
    @State private var didDetectCurrency = false
    @State private var assetName = ""
    @State private var assetType: AssetType = .bankAccount
    @State private var assetBalance: Decimal? = nil
    @State private var assetStatusBalance: StatusBalance = .positive

    var body: some View {
        NavigationStack(path: $path) {
            OnboardingWelcomeStep(currencyCode: currencyCode) { path.append(.firstAsset) }
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {
                    case .firstAsset:
                        OnboardingAssetStep(
                            name: $assetName,
                            type: $assetType,
                            balance: $assetBalance,
                            statusBalance: $assetStatusBalance,
                            currencyCode: $currencyCode,
                            onContinue: {
                                saveFirstAsset()
                                path.append(.plans)
                            },
                            onSkip: { path.append(.plans) }
                        )
                    case .plans:
                        OnboardingPlansStep(store: store, onContinueFree: finish)
                    }
                }
        }
        .onAppear(perform: detectCurrency)
        // Purchased here, or a returning subscriber whose entitlement just loaded.
        .onChange(of: store.isPro) { _, isPro in
            if isPro { finish() }
        }
    }

    private func finish() {
        ensureDefaultCategory()
        // A new install has nothing to catch up on.
        whatsNewVersion = WhatsNewView.release
        onComplete()
    }

    /// Starts from the currency of the user's region; they can change it on the asset step.
    private func detectCurrency() {
        guard !didDetectCurrency else { return }
        didDetectCurrency = true
        if let identifier = Locale.current.currency?.identifier,
           let detected = CurrencyCode(rawValue: identifier) {
            currencyCode = detected
        }
    }

    // MARK: - SwiftData

    private func saveFirstAsset() {
        let trimmed = assetName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? assetType.displayName : trimmed
        let finalBalance: Decimal = {
            guard let b = assetBalance else { return 0 }
            return assetStatusBalance == .negative ? -abs(b) : abs(b)
        }()

        // Going back and saving again updates the same asset instead of adding a second one.
        let descriptor = FetchDescriptor<Asset>(predicate: #Predicate { $0.name == name })
        if let existing = (try? modelContext.fetch(descriptor))?.first {
            existing.type = assetType
            existing.initialBalance = finalBalance
        } else {
            modelContext.insert(Asset(name: name, type: assetType, initialBalance: finalBalance))
        }
        ensureDefaultCategory()
    }

    /// Operations need a category, so a "General" one is there from the start.
    private func ensureDefaultCategory() {
        let descriptor = FetchDescriptor<CategoryOperation>(predicate: #Predicate { $0.name == "General" })
        if (try? modelContext.fetch(descriptor))?.first == nil {
            modelContext.insert(CategoryOperation(name: "General"))
        }
    }
}

#Preview {
    OnboardingView(store: Store(), onComplete: {})
        .modelContainer(for: Asset.self, inMemory: true)
}
