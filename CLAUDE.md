# ByJo — Claude Code Notes

## What the app is

ByJo is a personal finance tracker designed as a better alternative to spreadsheets. Users track net worth, manage budgets across multiple asset types, log recurring operations, set financial goals, and compare performance across time periods. All data stays on-device (privacy-first). Free plan up to 3 assets; ByJo Pro (subscription or lifetime, StoreKit 2) unlocks the rest.

## Core models (SwiftData)

| Model | Key fields | Notes |
|---|---|---|
| `Asset` | `name`, `type: AssetType`, `initialBalance: Decimal` | Has `operations: [AssetOperation]` and `goals: [Goal]` (cascade delete) |
| `AssetOperation` | `name`, `date`, `amount: Decimal`, `frequency: RecurrenceFrequency`, `swapId: UUID?` | Negative amount = expense. Linked to `Asset` + `CategoryOperation`. `swapId` links paired swap operations |
| `CategoryOperation` | `name` | Simple label for grouping operations |
| `Goal` | `title`, `startingAmount`, `targetAmount`, `dueDate?` | Linked to an `Asset`; optionally has a `CompletedGoal` |

`Asset.calculateCurrentBalance()` = `initialBalance + sum(operations.amount)`.

## Enums

- `AssetType` — 40+ types (cash, bank account, crypto, real estate, vehicles, loans, etc.)
- `CurrencyCode` — 50+ ISO codes with `symbol` computed property
- `RecurrenceFrequency` — `single | daily | weekly | monthly | yearly`; drives local notifications
- `OperationType` — `income | expense` (UI helper; sign of `amount` is the source of truth)
- `DateRangeOption` — `week | month | threeMonths | sixMonths | year | all`; used for filtering and comparisons

## App flow

```
ByJoApp → ContentView (.environment(store))
  ├─ !hasCompletedOnboarding → OnboardingView: Welcome → first asset (skippable) → plans
  │                              ("Start free trial", or "Continue for free")
  └─ TabView (Home / Assets / Operations / Search), free or Pro
```

There is no hard paywall. `Store.isPro = !purchasedSubscriptions.isEmpty || !purchasedProducts.isEmpty`.

## Free plan vs ByJo Pro (since 2026-11)

- **Free:** up to `Store.freeAssetLimit` (3) assets, unlimited operations and categories (with budgets), the basic Home cards, swaps, search, Siri/Shortcuts logging, the Wallet banner switch.
- **Pro:** unlimited assets, goals, recurring operations, Home Screen widgets, export & import, the advanced Home charts (`HomeSection.isPro`: Net Worth History, Spending Trends, Savings Rate Trend, Expense Breakdown, Asset Allocation, Debt Payoff), and reordering/hiding Home sections in `CustomizeHomeView`.
- Locked Home charts stay visible, blurred, through `.proLockedCard(title:onUnlock:)`; tapping opens `PaywallView(context: .charts)`.
- Gate with `store.unlocksPro` (true while StoreKit loads, so subscribers never see a lock). Gates live where the feature opens: `EditAssetView` (new asset past the cap), `EditGoalView` (new goal), `ExportImportView`, and the frequency picker in `EditAssetOperationView`. The editors show `PaywallView(dismissOnUnlock: false)` in place of the form and switch to the form once Pro unlocks.
- Never remove or hide existing data on the free plan: existing goals, recurring operations and extra assets stay viewable and editable after a plan lapses.
- Widgets and App Intents can't ask StoreKit, so `Store` writes `ProAccess` (app group, `WidgetShared.swift`). Widgets wrap their view in `.proLocked()`; the Wallet intent won't create a 4th asset.

## Subscription / paywall

- `Store` is `@Observable`, created in `ContentView` as `@State var store = Store()` and injected with `.environment(store)`; views read it with `@Environment(Store.self)`.
- Paywall plans: `bjpro_3999_1y` (yearly, 7-day free trial, pre-selected), `byjo_399_1w` (weekly, no trial), `com.giusscos.byjoLifetime`. Older IDs in `productIds` / `productLifetimeIds` stay so their owners keep Pro.
- `PlanPickerView.swift` holds `PlanPicker`, `PlanPurchaseButton` (trial wording only for the yearly plan), `ProFeatureList` and `PaywallLegalFooter`, shared by `PaywallView` and `OnboardingPlansStep`. Adapted from yPrompt.
- `PaywallView(context:)` is always closable; `context` sets the headline (upgrade, asset limit, goals, recurring, export & import).
- Purchases go through `store.purchase(product) { try await purchase($0) }` with `@Environment(\.purchase)`.

## Onboarding (redone 2026-11)

`OnboardingView` is shown on first launch via `@AppStorage("hasCompletedOnboarding")`:
1. **Welcome**: sample net worth card, "Your whole net worth. Private."
2. **First asset**: type and balance (name optional, defaults to the type's name), currency picked from the region and changeable inline. Skippable.
3. **Plans** (`OnboardingPlansStep`): the user's net worth, plan cards, Pro features, "Continue for free".

A default `CategoryOperation("General")` is created when onboarding finishes. If Pro unlocks during onboarding (purchase, or a returning subscriber's entitlement loading), onboarding closes on its own. New installs skip the What's New sheet.

## Key AppStorage keys

| Key | Type | Default | Purpose |
|---|---|---|---|
| `currencyCode` | `CurrencyCode` | `.usd` | Display currency throughout the app |
| `compactNumber` | `Bool` | `true` | Compact vs. full number formatting |
| `showCurrencyPicker` | `Bool` | `true` | Legacy `CurrencyPickerView` flag; not part of the current flow (onboarding sets the currency) |
| `whatsNewVersion` | `String` | `""` | Last What's New release seen (`WhatsNewView.release`); onboarding sets it so new installs skip the sheet |
| `hasCompletedOnboarding` | `Bool` | `false` | Gate for onboarding vs. paywall on launch |

## Architecture notes

- **SwiftData** for all persistence; `ModelContainer` created in `ByJoApp` with `undoManager` attached
- **No Combine** — use `async/await` and SwiftUI reactive patterns
- `@Observable` (Observation framework) for `Store`, not `ObservableObject`
- `VersionedLabel` component wraps `Label` with an `#available(iOS 26, *)` check for the Liquid Glass era
- Swap operations: two `AssetOperation` records sharing the same `swapId` UUID represent a fund transfer between assets
- Recurring operations schedule local `UNUserNotificationCenter` notifications
- `filterData(for:data:)` is a free function in `AssetOperation.swift` used across multiple views
