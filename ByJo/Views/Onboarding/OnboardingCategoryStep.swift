//
//  OnboardingCategoryStep.swift
//  ByJo
//

import SwiftUI

struct OnboardingCategoryStep: View {
    @Binding var name: String
    let onContinue: () -> Void

    @FocusState private var isFocused: Bool
    @State private var appeared = false

    private var isDisabled: Bool { name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 100, height: 100)

                        Image(systemName: "folder.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.accentColor)
                    }
                    .onboardingAppear(appeared, delay: 0.05)

                    VStack(spacing: 8) {
                        Text("Name a Category")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Categories help you group and filter your transactions. You can always add more later.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .onboardingAppear(appeared, delay: 0.14)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    TextField("e.g. General", text: $name)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                        .focused($isFocused)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit { if !isDisabled { onContinue() } }
                }
                .onboardingAppear(appeared, delay: 0.24)
                .padding(.horizontal, 24)
            }
            .padding(.top, 16)
        }
        .background(KeyboardDismissOnAppear())
        .scrollDismissesKeyboard(.interactively)
        .ignoresSafeArea(.keyboard)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Continue", action: onContinue)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .disabled(isDisabled)
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button { isFocused = false } label: {
                    Label("Dismiss keyboard", systemImage: "keyboard.chevron.compact.down")
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .onAppear {
            appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { isFocused = true }
        }
        .onDisappear { isFocused = false }
    }
}
