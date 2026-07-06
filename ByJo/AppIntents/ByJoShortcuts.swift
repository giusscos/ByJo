//
//  ByJoShortcuts.swift
//  ByJo
//

import AppIntents

struct ByJoShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddOperationIntent(),
            phrases: [
                "Add operation in \(.applicationName)",
                "Log outflow in \(.applicationName)",
                "Record inflow in \(.applicationName)"
            ],
            shortTitle: "Add Operation",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: AddSwapIntent(),
            phrases: [
                "Transfer funds in \(.applicationName)",
                "Move money in \(.applicationName)"
            ],
            shortTitle: "Transfer Funds",
            systemImageName: "arrow.left.arrow.right"
        )
    }
}
