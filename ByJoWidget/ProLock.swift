//
//  ProLock.swift
//  ByJoWidget
//
//  Home Screen widgets are part of ByJo Pro. Free users see their widget blurred
//  behind a lock; tapping it opens the app.
//

import SwiftUI
import WidgetKit

private struct ProLockModifier: ViewModifier {
    @Environment(\.widgetFamily) private var family

    func body(content: Content) -> some View {
        if ProAccess.isUnlocked {
            content
        } else {
            content
                .blur(radius: 8)
                .overlay {
                    if family.isAccessory {
                        Image(systemName: "lock.fill")
                            .font(.title3)
                    } else {
                        VStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.title2)
                            Text(verbatim: "ByJo Pro")
                                .font(.headline)
                        }
                        .foregroundStyle(.primary)
                    }
                }
        }
    }
}

private extension WidgetFamily {
    var isAccessory: Bool {
        switch self {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: true
        default: false
        }
    }
}

extension View {
    /// Blurs the widget and shows a lock when ByJo Pro isn't unlocked.
    func proLocked() -> some View {
        modifier(ProLockModifier())
    }
}
