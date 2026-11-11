//
//  CustomizeHomeView.swift
//  ByJo
//

import SwiftUI

struct CustomizeHomeView: View {
    @AppStorage("homeSectionOrder") var sectionOrderString: String = HomeSection.defaultOrderString
    @AppStorage("homeSectionHidden") var sectionHiddenString: String = ""
    @AppStorage("showApplePayShortcutBanner") var showWalletShortcutBanner: Bool = true
    @Environment(Store.self) private var store

    @State private var sections: [HomeSection] = []
    @State private var hiddenSections: Set<HomeSection> = []
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Button {
                            showWalletShortcutBanner.toggle()
                        } label: {
                            Image(systemName: showWalletShortcutBanner ? "eye" : "eye.slash")
                                .foregroundStyle(showWalletShortcutBanner ? Color.primary : Color.secondary)
                                .frame(width: 28)
                        }
                        .buttonStyle(.plain)

                        Image(systemName: "wallet.pass")
                            .foregroundStyle(Color.secondary)
                            .frame(width: 20)

                        Text("Wallet Auto-Log")
                            .foregroundStyle(showWalletShortcutBanner ? Color.primary : Color.secondary)
                    }
                } footer: {
                    Text("Shown at the top of Home when enabled.")
                }

                // Reordering and hiding sections is Pro. The Wallet banner switch above
                // stays free: it's the only way to hide that banner.
                if store.unlocksPro {
                    sectionList
                } else {
                    Section {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 28)
                                Text("Reorder and hide Home sections")
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                Text(verbatim: "Pro")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.accentColor, in: Capsule())
                            }
                        }
                    }
                }
            }
            .environment(\.editMode, .constant(store.unlocksPro ? .active : .inactive))
            .navigationTitle("Customize Home")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) {
                PaywallView(store: store, context: .customizeHome)
            }
        }
        .onAppear {
            loadState()
        }
    }

    private var sectionList: some View {
        Section {
            ForEach(sections) { section in
                HStack(spacing: 12) {
                    Button {
                        toggleVisibility(section)
                    } label: {
                        Image(systemName: hiddenSections.contains(section) ? "eye.slash" : "eye")
                            .foregroundStyle(hiddenSections.contains(section) ? Color.secondary : Color.primary)
                            .frame(width: 28)
                    }
                    .buttonStyle(.plain)

                    Image(systemName: section.icon)
                        .foregroundStyle(Color.secondary)
                        .frame(width: 20)

                    Text(section.title)
                        .foregroundStyle(hiddenSections.contains(section) ? Color.secondary : Color.primary)
                }
                .deleteDisabled(true)
            }
            .onMove { from, to in
                sections.move(fromOffsets: from, toOffset: to)
                saveSectionOrder()
            }
        } footer: {
            Text("Drag to reorder. Tap the eye icon to show or hide a section.")
        }
    }

    private func loadState() {
        let ordered = sectionOrderString.split(separator: ",").compactMap { HomeSection(rawValue: String($0)) }
        let missing = HomeSection.allCases.filter { s in !ordered.contains(s) }
        sections = ordered + missing

        let hidden = sectionHiddenString.split(separator: ",").compactMap { HomeSection(rawValue: String($0)) }
        hiddenSections = Set(hidden)
    }

    private func saveSectionOrder() {
        sectionOrderString = sections.map(\.rawValue).joined(separator: ",")
    }

    private func toggleVisibility(_ section: HomeSection) {
        if hiddenSections.contains(section) {
            hiddenSections.remove(section)
        } else {
            hiddenSections.insert(section)
        }
        sectionHiddenString = hiddenSections.map(\.rawValue).joined(separator: ",")
    }
}

#Preview {
    CustomizeHomeView()
        .environment(Store())
}
