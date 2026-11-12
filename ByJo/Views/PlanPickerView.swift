//
//  PlanPickerView.swift
//  ByJo
//
//  Plan cards, purchase button and Pro feature list, shared by the paywall and the
//  last onboarding step. Adapted from yPrompt's paywall.
//

import StoreKit
import SwiftUI

/// What Pro adds. Everything listed here is locked on the free plan; anything free stays off.
struct ProFeatureList: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            row("infinity", .blue, "Unlimited Assets",
                "Track every account, card, loan and investment. The free plan covers \(Store.freeAssetLimit).")
            row("chart.line.uptrend.xyaxis", .indigo, "Charts & Insights",
                "Net worth history, spending trends, allocation and more, with Home arranged your way.")
            row("target", .orange, "Goals",
                "Give any asset a target and a date, and watch your progress.")
            row("repeat", .purple, "Recurring Operations",
                "Schedule bills and income, with a reminder before each one.")
            row("square.grid.2x2.fill", .teal, "Home Screen Widgets",
                "Net worth, spending and goals at a glance, without opening the app.")
            row("arrow.up.arrow.down.square.fill", .green, "Export & Import",
                "Bring in a CSV or JSON file, and take your data with you anytime.")
            row("sparkles", .yellow, "All Future Pro Features",
                "New Pro features are included in every plan.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ icon: String, _ color: Color, _ title: LocalizedStringKey, _ description: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(description).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Selectable plan cards. Yearly (with its free trial) is listed first and pre-selected;
/// lifetime is last.
struct PlanPicker: View {
    var store: Store
    @Binding var selectedID: String

    var body: some View {
        VStack(spacing: 10) {
            if let product = store.yearlyProduct {
                planCard(product, title: "Yearly", subtitle: perWeekText(product), badge: yearlyBadge)
            }
            if let product = store.weeklyProduct {
                planCard(product, title: "Weekly", subtitle: Text("Flexible, cancel anytime"), badge: nil)
            }
            if let product = store.lifetimeProduct {
                planCard(product, title: "Lifetime", subtitle: Text("Pay once, keep it forever"), badge: nil)
            }
        }
    }

    private var yearlyBadge: Text {
        if let days = store.yearlyTrialDays {
            Text("\(days) Days Free")
        } else {
            Text("Best Value")
        }
    }

    private func perWeekText(_ product: Product) -> Text {
        let perWeek = (product.price / 52).formatted(product.priceFormatStyle)
        return Text("Just \(perWeek) per week")
    }

    private func planCard(_ product: Product, title: LocalizedStringKey, subtitle: Text, badge: Text?) -> some View {
        let isSelected = selectedID == product.id
        return Button {
            withMotionAnimation(.snappy(duration: 0.2)) { selectedID = product.id }
        } label: {
            AdaptiveStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    subtitle
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Text(product.displayPrice)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
            .overlay(alignment: .topTrailing) {
                if let badge {
                    badge
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor, in: Capsule())
                        .offset(x: -10, y: -10)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Main call to action for the plan chosen in `PlanPicker`, with that plan's terms
/// underneath, so the free-trial promise only ever appears for the yearly plan.
struct PlanPurchaseButton: View {
    var store: Store
    let selectedID: String

    @Environment(\.purchase) private var purchase
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private var product: Product? {
        [store.yearlyProduct, store.weeklyProduct, store.lifetimeProduct]
            .compactMap { $0 }
            .first { $0.id == selectedID }
    }

    private var trialDays: Int? {
        selectedID == store.yearlyProductId ? store.yearlyTrialDays : nil
    }

    var body: some View {
        VStack(spacing: 8) {
            Button {
                guard let product else { return }
                Task {
                    isPurchasing = true
                    do {
                        try await store.purchase(product) { try await purchase($0) }
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                    isPurchasing = false
                }
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView()
                    } else if let trialDays {
                        Text("Start \(trialDays)-Day Free Trial")
                    } else {
                        Text("Continue")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .disabled(product == nil || isPurchasing)

            if let terms {
                terms
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .alert("Purchase Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var terms: Text? {
        guard let product else { return nil }
        let price = product.displayPrice
        if let trialDays {
            return Text("\(trialDays) days free, then \(price)/year. Cancel anytime.")
        }
        switch product.id {
        case store.yearlyProductId:
            return Text("\(price) per year. Renews automatically, cancel anytime.")
        case store.weeklyProductId:
            return Text("\(price) per week. Renews automatically, cancel anytime.")
        default:
            return Text("One payment of \(price). No subscription.")
        }
    }
}

/// Background for the paywall's pinned bottom bar: a blur that fades in from clear,
/// so scrolling content dissolves under the buttons instead of ending at a hard edge.
/// Like yPrompt's, but the fade sits entirely above the bar: a fade spread over the
/// whole (taller) bar let feature rows show through the price terms.
struct BottomBarFade: View {
    private let fadeHeight: CGFloat = 56

    var body: some View {
        Rectangle()
            .fill(.bar)
            .padding(.top, -fadeHeight)
            .mask {
                VStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                        .frame(height: fadeHeight)
                    Color.black
                }
            }
            .ignoresSafeArea()
    }
}

/// Terms, Privacy and Restore. Auto-renewal is spelled out by `PlanPurchaseButton`'s
/// terms line, so no separate notice is needed here.
struct PaywallLegalFooter: View {
    var store: Store

    var body: some View {
        AdaptiveStack(horizontalAlignment: .center, spacing: 6) {
            Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            Text(verbatim: "·").foregroundStyle(.tertiary).accessibilityHidden(true)
            Link("Privacy", destination: URL(string: "https://by-jo.com/privacy")!)
            Text(verbatim: "·").foregroundStyle(.tertiary).accessibilityHidden(true)
            Button("Restore Purchases") {
                Task { await store.restorePurchases() }
            }
        }
        .font(.caption)
        .buttonStyle(.borderless)
    }
}
