---
name: project-onboarding
description: Onboarding flow added June 2026 — interactive pre-paywall conversion funnel
metadata:
  type: project
---

Added a 5-step interactive onboarding flow to convert users before the paywall.

**Why:** The previous flow showed the paywall immediately on first launch with no context. The new flow makes users invest in the app (create real data) before seeing the paywall — increasing conversion intent.

**How to apply:** When touching onboarding, ContentView, or paywall flow, keep this sequencing: onboarding → paywall, never paywall first for new users. The `hasCompletedOnboarding` AppStorage key gates this.

## Files

- `ByJo/ByJo/Views/Onboarding/OnboardingView.swift` — all 5 steps + coordinator
- `ByJo/ByJo/Views/ContentView.swift` — added `onboarding` case to `ActiveSheet`, gates on `hasCompletedOnboarding`

## Flow

1. **Welcome** — value prop + feature list, spring-animated icon
2. **Currency** — 18-currency grid picker (most popular), saves to `@AppStorage("currencyCode")`
3. **Create Asset** — inline form (name, type menu, balance + positive/negative toggle); saves real `Asset` + default `CategoryOperation("General")` to SwiftData on "Save Asset"
4. **Add Transaction** — inline form (income/expense, description, amount); saves real `AssetOperation`; has "Skip for now" escape
5. **Ready** — success animation + feature highlights; "Unlock ByJo Pro" calls `onComplete()` → paywall

## Key decisions

- Data created during onboarding is persisted to SwiftData immediately — user sees their asset/transaction as soon as they subscribe
- The HStack + offset approach (not TabView) prevents accidental swipe navigation past required steps
- Step 3 (asset) is required (button disabled if name/balance empty); step 4 (transaction) is skippable
- A single `CategoryOperation("General")` is created alongside the first asset to satisfy the app's requirement that operations have a category
