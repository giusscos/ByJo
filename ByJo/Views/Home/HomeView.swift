//
//  HomeView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftData
import SwiftUI
import TipKit

struct HomeView: View {
    enum ActiveSheet: Identifiable {
        case createOperation
        case createAsset
        case createGoal
        case viewGoal
        case viewCategories
        case swapAssetOperation
        case customize

        var id: String {
            switch self {
                case .createOperation:
                    return "createOperation"
                case .createAsset:
                    return "createAsset"
                case .createGoal:
                    return "createGoal"
                case .viewGoal:
                    return "viewGoal"
                case .viewCategories:
                    return "viewCategories"
                case .swapAssetOperation:
                    return "assetAmountSwap"
                case .customize:
                    return "customize"
            }
        }
    }
    
    @Environment(\.requestReview) var requestReview
    
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true
    @AppStorage("homeSectionOrder") var sectionOrderString: String = HomeSection.defaultOrderString
    @AppStorage("homeSectionHidden") var sectionHiddenString: String = ""
    @AppStorage("whatsNewVersion") var whatsNewVersion: String = ""

    @State private var showWhatsNew: Bool = false

    @Query var assets: [Asset]
    
    @Query var goals: [Goal]
    
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    
    @Query(sort: \CategoryOperation.name, order: .reverse) var categories: [CategoryOperation]
    
    @State var activeSheet: ActiveSheet?

    private let addAssetTip = AddAssetTip()
    private let addOperationTip = AddOperationTip()

    var netWorth: Decimal {
        assets.reduce(Decimal(0)) { $0 + $1.calculateCurrentBalance() }
    }

    var visibleSections: [HomeSection] {
        let hidden = Set(sectionHiddenString.split(separator: ",").compactMap { HomeSection(rawValue: String($0)) })
        let ordered = sectionOrderString.split(separator: ",").compactMap { HomeSection(rawValue: String($0)) }
        let missing = HomeSection.allCases.filter { s in !ordered.contains(s) }
        return (ordered + missing).filter { !hidden.contains($0) }
    }

    @ViewBuilder
    private func sectionView(for section: HomeSection) -> some View {
        switch section {
        case .goals:            GoalListStackView()
        case .monthSummary:     FinancialSummaryWidgetView()
        case .spendmeter:       SaveToSpendGaugeView()
        case .recurring:        RecurringOperationWidgetView()
        case .category:         CategoryWidgetView()
        case .savingsRate:      SavingsRateWidgetView()
        case .topExpenses:      TopExpensesWidgetView()
        case .assetAllocation:  AssetAllocationWidgetView()
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(visibleSections) { section in
                    sectionView(for: section)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                AddAssetTip.hasAssets = !assets.isEmpty
                AddOperationTip.isReady = !assets.isEmpty && !categories.isEmpty && operations.isEmpty
                WidgetDataBridge.update(assets: assets, currencyCode: currencyCode, compactNumber: compactNumber)
                if whatsNewVersion != "2.0" {
                    showWhatsNew = true
                    whatsNewVersion = "2.0"
                }
            }
            .onChange(of: assets) { _, new in
                AddAssetTip.hasAssets = !new.isEmpty
                AddOperationTip.isReady = !new.isEmpty && !categories.isEmpty && operations.isEmpty
                WidgetDataBridge.update(assets: new, currencyCode: currencyCode, compactNumber: compactNumber)
            }
            .onChange(of: categories) { _, new in
                AddOperationTip.isReady = !assets.isEmpty && !new.isEmpty && operations.isEmpty
            }
            .onChange(of: operations) { _, new in
                AddOperationTip.isReady = !assets.isEmpty && !categories.isEmpty && new.isEmpty
                WidgetDataBridge.update(assets: assets, currencyCode: currencyCode, compactNumber: compactNumber)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(netWorth, format: compactNumber
                         ? .currency(code: currencyCode.rawValue).notation(.compactName)
                         : .currency(code: currencyCode.rawValue))
                        .font(.headline)
                        .contentTransition(.numericText(value: Double(truncating: netWorth as NSDecimalNumber)))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .createOperation
                    } label: {
                        VersionedLabel(title: "Add operation", newSystemImage: "plus", oldSystemImage: "plus.circle.fill")
                    }
                    .disabled(assets.count == 0 || categories.count == 0)
                    .popoverTip(addOperationTip)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section {
                            Button {
                                activeSheet = .customize
                            } label: {
                                Label("Customize Home", systemImage: "slider.horizontal.3")
                            }

                            Button {
                                withAnimation {
                                    compactNumber.toggle()
                                }
                            } label: {
                                Label(compactNumber ? "Long amount" : "Short amount", systemImage: compactNumber ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                            }
                        }
                        
                        Section {
                            Button {
                                activeSheet = .createAsset
                            } label: {
                                Label("Add asset", systemImage: "plus")
                            }
                            
                            Button {
                                activeSheet = .swapAssetOperation
                            } label: {
                                Label("Swap", systemImage: "arrow.up.arrow.down")
                            }
                            .disabled(assets.count < 2)
                        }
                        
                        Section {
                            Button {
                                activeSheet = .createGoal
                            } label: {
                                Label("Add goal", systemImage: "plus")
                            }
                            .disabled(assets.isEmpty)
                            
                            Button {
                                activeSheet = .viewGoal
                            } label: {
                                Label("Goals", systemImage: "list.bullet")
                            }
                            .disabled(goals.isEmpty)
                        }
                        
                        Section {
                            Button {
                                activeSheet = .viewCategories
                            } label: {
                                Label("Categories", systemImage: "list.bullet")
                            }
                        }
                        Section {
                            Menu("Currency") {
                                ForEach(CurrencyCode.allCases, id: \.self) { value in
                                    Button {
                                        withAnimation {
                                            currencyCode = value
                                        }
                                    } label: {
                                        HStack {
                                            Text(value.rawValue)
                                            
                                            if value == currencyCode {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        VersionedLabel(title: "Menu", newSystemImage: "ellipsis", oldSystemImage: "ellipsis.circle")
                    }
                    .popoverTip(addAssetTip)
                }
            }
            .fullScreenCover(isPresented: $showWhatsNew) {
                WhatsNewView {
                    showWhatsNew = false
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                    case .createOperation:
                        if let asset = assets.first, let category = categories.first {
                            EditAssetOperationView(asset: asset, category: category)
                        }
                    case .createAsset:
                        EditAssetView()
                    case .createGoal:
                        if let asset = assets.first {
                            EditGoalView(asset: asset)
                        }
                    case .viewGoal:
                        NavigationStack { GoalListView() }
                    case .viewCategories:
                        CategoryOperationView()
                    case .swapAssetOperation:
                        if assets.count > 1, let assetFrom = assets.first, let assetTo = assets.last {
                            AssetAmountSwapView(assetFrom: assetFrom, assetTo: assetTo)
                        }
                    case .customize:
                        CustomizeHomeView()
                }
            }
//            .onAppear() {
//                if assets.count > 0 && operations.count > 5 {
//                    requestReview()
//                }
//            }
        }
    }
}

#Preview {
    HomeView()
}
