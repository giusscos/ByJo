//
//  ApplePayShortcutSetupView.swift
//  ByJo
//

import SwiftUI

struct ApplePayShortcutSetupView: View {
    private static let shortcutURL = URL(string: "https://www.icloud.com/shortcuts/03928890ce474e8aa1fecc57d03f5b60")!
    private static let createAutomationURL = URL(string: "shortcuts://create-automation")!

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @AppStorage("showApplePayShortcutBanner") private var showApplePayShortcutBanner: Bool = true

    var body: some View {
        NavigationStack {
            List {
                introSection
                getShortcutSection
                createAutomationSection
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

                Text("Add the shared ByJo x Apple Pay shortcut, then wire a Transaction automation so each NFC tap logs into ByJo. Assets and categories are matched or created from the names you pass.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private var getShortcutSection: some View {
        Section {
            Button {
                openURL(Self.shortcutURL)
            } label: {
                Label("Get Shortcut", systemImage: "square.and.arrow.down")
            }
        } footer: {
            Text("Opens the shared ByJo x Apple Pay shortcut so you can add it to Shortcuts.")
        }
    }

    private var createAutomationSection: some View {
        Section {
            Button {
                openURL(Self.createAutomationURL)
            } label: {
                Label("Create Automation", systemImage: "arrow.up.forward.app")
            }
        } footer: {
            Text("Opens Shortcuts to create a new Transaction / Wallet automation.")
        }
    }

    private var stepsSection: some View {
        Section("Setup steps") {
            setupStep(number: 1, text: "Tap Get Shortcut and add ByJo x Apple Pay.")
            setupStep(number: 2, text: "Tap Create Automation and choose Transaction (or Wallet on newer iOS).")
            setupStep(number: 3, text: "Select the cards to track, then choose Run Immediately.")
            setupStep(number: 4, text: "Add Action → Run Shortcut → ByJo x Apple Pay (or open the shortcut and confirm Merchant, Amount, and Asset Name mappings).")
            setupStep(number: 5, text: "Optionally set Category Name. Leave empty to categorize later in ByJo.")
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
