//
//  OnboardingStepLayout.swift
//  ByJo
//

import SwiftUI

struct OnboardingStepLayout<Content: View>: View {
    let primaryLabel: String
    let primaryDisabled: Bool
    let primaryAction: () -> Void
    let skipAction: (() -> Void)?
    let primaryInToolbar: Bool
    let content: Content

    init(
        primaryLabel: String = "Continue",
        primaryDisabled: Bool = false,
        primaryAction: @escaping () -> Void,
        skipAction: (() -> Void)? = nil,
        primaryInToolbar: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.primaryLabel = primaryLabel
        self.primaryDisabled = primaryDisabled
        self.primaryAction = primaryAction
        self.skipAction = skipAction
        self.primaryInToolbar = primaryInToolbar
        self.content = content()
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            content
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            if !primaryInToolbar || skipAction != nil {
                VStack(spacing: 10) {
                    if !primaryInToolbar {
                        Button(action: primaryAction) {
                            Text(primaryLabel)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .controlSize(.large)
                        .disabled(primaryDisabled)
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity)
                .background {
                    Rectangle()
                        .foregroundStyle(.ultraThinMaterial)
                        .mask(
                            LinearGradient(colors: [.clear, .black.opacity(0.75), .black], startPoint: .top, endPoint: .bottom)
                        )
                        .ignoresSafeArea()
                }
            }
        }
        .toolbar {
            if primaryInToolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: primaryAction) {
                        Text(primaryLabel)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .disabled(primaryDisabled)
                }
            }
        }
    }
}
