//
//  AccessibilityHelpers.swift
//  ByJo
//
//  Shared helpers for Dynamic Type, Reduce Motion and VoiceOver.
//

import SwiftUI
import UIKit

// MARK: - Dynamic Type

/// A custom-size font that still follows the user's text size, scaled relative to `textStyle`.
/// Use it for hero numbers that are bigger than any text style (e.g. the amount on an editor).
private struct ScaledFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    let maxSize: CGFloat?

    init(size: CGFloat, weight: Font.Weight, design: Font.Design, relativeTo textStyle: Font.TextStyle, maxSize: CGFloat?) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
        self.weight = weight
        self.design = design
        self.maxSize = maxSize
    }

    func body(content: Content) -> some View {
        content.font(.system(size: maxSize.map { min(size, $0) } ?? size, weight: weight, design: design))
    }
}

extension View {
    /// `.font(.system(size:weight:design:))` that grows with Dynamic Type.
    /// `maxSize` caps very large hero numbers so they still fit on one line at accessibility sizes.
    func scaledFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        relativeTo textStyle: Font.TextStyle = .largeTitle,
        maxSize: CGFloat? = nil
    ) -> some View {
        modifier(ScaledFont(size: size, weight: weight, design: design, relativeTo: textStyle, maxSize: maxSize))
    }
}

/// An HStack that becomes a leading-aligned VStack at accessibility text sizes,
/// so side-by-side label/value rows don't squeeze or clip.
struct AdaptiveStack<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var horizontalAlignment: HorizontalAlignment = .leading
    var verticalAlignment: VerticalAlignment = .center
    var spacing: CGFloat? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: horizontalAlignment, spacing: spacing, content: content)
        } else {
            HStack(alignment: verticalAlignment, spacing: spacing, content: content)
        }
    }
}

// MARK: - Reduce Motion

extension View {
    /// Like `.animation(_:value:)`, but turns the animation off when Reduce Motion is on.
    func motionAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        modifier(MotionAnimation(animation: animation, value: value))
    }
}

private struct MotionAnimation<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation?
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

/// `withAnimation` that skips movement (springs, rotations, scaling) when Reduce Motion is on.
/// Pass a fade-friendly fallback (default: a short ease) to keep a gentle crossfade instead.
@discardableResult
func withMotionAnimation<Result>(
    _ animation: Animation? = .default,
    reduced: Animation? = .easeInOut(duration: 0.2),
    _ body: () throws -> Result
) rethrows -> Result {
    try withAnimation(UIAccessibility.isReduceMotionEnabled ? reduced : animation, body)
}

// MARK: - VoiceOver

extension Decimal {
    /// The amount as VoiceOver should read it: full currency, never compact ("$1,250.00", not "$1.3K").
    func accessibilityCurrency(_ code: CurrencyCode) -> String {
        formatted(.currency(code: code.rawValue))
    }
}

extension Double {
    func accessibilityCurrency(_ code: CurrencyCode) -> String {
        formatted(.currency(code: code.rawValue))
    }
}

/// "Up $120.00" / "Down $120.00" / "$0.00" for a signed change, so VoiceOver says the direction
/// that the arrow and the rise/fall color show on screen.
func accessibilityChange(_ change: Decimal, _ code: CurrencyCode) -> String {
    let amount = abs(change).accessibilityCurrency(code)
    if change == 0 { return amount }
    return String(format: NSLocalizedString(change > 0 ? "Up %@" : "Down %@", comment: "VoiceOver: change over the period"), amount)
}
