//
//  ReadableContentWidth.swift
//  ByJo
//

import SwiftUI

/// Keeps a List's content at a comfortable width on wide screens (iPad, the iPhone Duo inner display),
/// centered, the way Settings does. The background still fills the screen. Compact width is unchanged.
private struct ReadableContentWidth: ViewModifier {
    let maxWidth: CGFloat
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var width: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
            .contentMargins(.horizontal, sideMargin, for: .scrollContent)
    }

    /// nil keeps the system's own margins (the List's usual insets), which is what compact width
    /// and narrow columns need.
    private var sideMargin: CGFloat? {
        guard horizontalSizeClass == .regular, width > maxWidth else { return nil }
        return (width - maxWidth) / 2
    }
}

extension View {
    /// Centers scroll content at `maxWidth` points on regular width.
    func readableContentWidth(_ maxWidth: CGFloat = 720) -> some View {
        modifier(ReadableContentWidth(maxWidth: maxWidth))
    }
}
