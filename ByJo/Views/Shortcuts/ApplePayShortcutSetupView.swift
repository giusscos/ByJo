//
//  ApplePayShortcutSetupView.swift
//  ByJo
//

import SwiftUI

struct ApplePayShortcutSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @AppStorage("showApplePayShortcutBanner") private var showApplePayShortcutBanner: Bool = true

    var body: some View {
        NavigationStack {
            List {
                introSection
                openShortcutsSection
                stepsSection
                tipSection
                completedSection
            }
            .navigationTitle("Apple Pay Shortcut")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Sections

    private var introSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label("Auto-log Apple Pay taps", systemImage: "wallet.pass.fill")
                    .font(.headline)

                Text("When you pay with Apple Pay (NFC), Shortcuts can send the merchant and amount to ByJo as an expense. Apple requires you to finish setup in the Shortcuts app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private var openShortcutsSection: some View {
        Section {
            Button {
                guard let url = URL(string: "shortcuts://create-automation") else { return }
                openURL(url)
            } label: {
                Label("Open Shortcuts", systemImage: "arrow.up.forward.app")
            }
        } footer: {
            Text("Opens the Shortcuts app so you can create a new Transaction automation.")
        }
    }

    private var stepsSection: some View {
        Section("Setup steps") {
            setupStep(number: 1, text: "Choose Transaction (or Wallet on newer iOS).")
            setupStep(number: 2, text: "Select the cards to track, then choose Run Immediately.")
            setupStep(number: 3, text: "Add Action → Apps → ByJo → Log Apple Pay Transaction.")
            setupStep(number: 4, text: "Map Shortcut Input: Amount → Amount, Name or Merchant → Merchant. Optionally map Card → Card.")
            setupStep(number: 5, text: "Pick an Asset (and optional Category), then tap Done.")
        }
    }

    private var tipSection: some View {
        Section {
            Label(
                "If taps never log, enable Mobile Data for Wallet in Settings → Apps → Wallet.",
                systemImage: "info.circle"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var completedSection: some View {
        Section {
            Button {
                showApplePayShortcutBanner = false
                dismiss()
            } label: {
                Label("I've set this up", systemImage: "checkmark.circle.fill")
            }
        } footer: {
            Text("This hides the tip on Home. You can always show it again from Customize Home.")
        }
    }

    private func setupStep(number: Int, text: String) -> some View {
        Label {
            Text(text)
        } icon: {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(.tint))
        }
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }
}

#Preview {
    ApplePayShortcutSetupView()
}
