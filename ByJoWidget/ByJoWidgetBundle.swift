//
//  ByJoWidgetBundle.swift
//  ByJoWidget
//
//  Created by Giuseppe Cosenza on 06/07/2026.
//

import WidgetKit
import SwiftUI

@main
struct ByJoWidgetBundle: WidgetBundle {
    var body: some Widget {
        NetWorthWidget()
        SpendmeterWidget()
        AssetAllocationWidget()
        RecurringWidget()
        SavingsRateWidget()
        GoalWidget()
    }
}
