# ByJo — Claude Code Notes

## What the app is

ByJo is a personal finance tracker designed as a better alternative to spreadsheets. Users track net worth, manage budgets across multiple asset types, log recurring operations, set financial goals, and compare performance across time periods. All data stays on-device (privacy-first). Monetised via a subscription/lifetime paywall (StoreKit 2).

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
ByJoApp → ContentView
  ├─ store.isLoading → ProgressView
  └─ TabView (Home / Assets / Operations)
       └─ fullScreenCover
            ├─ first launch, !hasCompletedOnboarding → OnboardingView → PaywallView
            ├─ hasCompletedOnboarding, !hasPaid    → PaywallView
            ├─ hasPaid, showCurrencyPicker          → CurrencyPickerView
            └─ hasPaid                              → (nothing, TabView visible)
```

`hasPaid = !purchasedSubscriptions.isEmpty || !purchasedProducts.isEmpty` (Store.swift)

## Subscription / paywall

- `Store` is `@Observable`, instantiated in `ContentView` as `@State var store = Store()`
- Product IDs: `bjpro_999_1m_fa`, `bjpro_9999_1y_fa`, `bjpro_399_1m`, `bjpro_3999_1y`
- Lifetime IDs: `com.giusscos.byjoFamilyLifetime`, `com.giusscos.byjoLifetime`
- `PaywallView` uses `SubscriptionStoreView(groupID:)` — cannot be dismissed interactively
- `PaywallLifetimeView` is presented as a medium detent sheet from inside `PaywallView`

## Onboarding (added 2026-06)

`OnboardingView` is shown on first launch via `@AppStorage("hasCompletedOnboarding")`. It:
1. Welcomes the user with the value proposition
2. Lets them pick their currency
3. Walks them through creating their first `Asset` (saved to SwiftData on step completion)
4. Walks them through logging their first `AssetOperation` (skippable)
5. Shows a feature summary then calls `onComplete()` → paywall

The onboarding creates real SwiftData records so the user's data is already waiting after they subscribe. A default `CategoryOperation("General")` is created alongside the asset.

## Key AppStorage keys

| Key | Type | Default | Purpose |
|---|---|---|---|
| `currencyCode` | `CurrencyCode` | `.usd` | Display currency throughout the app |
| `compactNumber` | `Bool` | `true` | Compact vs. full number formatting |
| `showCurrencyPicker` | `Bool` | `true` | Show currency picker after first subscription |
| `hasCompletedOnboarding` | `Bool` | `false` | Gate for onboarding vs. paywall on launch |

## Architecture notes

- **SwiftData** for all persistence; `ModelContainer` created in `ByJoApp` with `undoManager` attached
- **No Combine** — use `async/await` and SwiftUI reactive patterns
- `@Observable` (Observation framework) for `Store`, not `ObservableObject`
- `VersionedLabel` component wraps `Label` with an `#available(iOS 26, *)` check for the Liquid Glass era
- Swap operations: two `AssetOperation` records sharing the same `swapId` UUID represent a fund transfer between assets
- Recurring operations schedule local `UNUserNotificationCenter` notifications
- `filterData(for:data:)` is a free function in `AssetOperation.swift` used across multiple views
