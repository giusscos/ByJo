---
name: project-onboarding
description: Onboarding and free plan, redone November 2026 — 3 screens ending on plans with "Continue for free"
metadata:
  type: project
---

In November 2026 the 5-step onboarding + hard paywall was replaced by a 3-screen onboarding and a free plan, modelled on yPrompt (which converts well with a free tier).

**Why:** ByJo 1.1.8 had a 7-day trial on the yearly plan, but 0 trials started between Oct 5 and Nov 9, 2026 (about 19 downloads), and ByJo had 0 ratings. The old flow asked for 5 screens of data entry, celebrated with confetti, then showed a paywall that couldn't be closed. Nobody got into the app without paying, so nobody could rate it either.

**How to apply:** keep onboarding short (show, don't ask) and keep the free plan usable. Pro features show a closable paywall at the moment they're reached. Never hide or delete a free user's existing data. Judge the change on trial starts per download from the version's go-live date; with ~15 downloads a month that takes 4–8 weeks.

## Files

- `ByJo/Views/Onboarding/OnboardingView.swift` — coordinator: Welcome → first asset → plans
- `OnboardingWelcomeStep.swift` — sample net worth card
- `OnboardingAssetStep.swift` — type, balance, optional name, inline currency menu, Skip
- `OnboardingPlansStep.swift` — net worth card, plan cards, Pro features, "Continue for free"
- `ByJo/Views/PlanPickerView.swift` — plan cards and purchase button shared with `PaywallView`

## Free plan

Up to 3 assets (`Store.freeAssetLimit`), unlimited operations and categories. Pro: unlimited assets, goals, recurring operations, Home Screen widgets, export & import, the six advanced Home charts (shown blurred with a lock on the free plan), and reordering/hiding Home sections. Budgets, balance history and split operations were deliberately left free.
