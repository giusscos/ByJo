//
//  CustomizeHomeView.swift
//  ByJo
//

import SwiftUI

struct CustomizeHomeView: View {
    @AppStorage("homeSectionOrder") var sectionOrderString: String = HomeSection.defaultOrderString
    @AppStorage("homeSectionHidden") var sectionHiddenString: String = ""

    @State private var sections: [HomeSection] = []
    @State private var hiddenSections: Set<HomeSection> = []

    var body: some View {
        NavigationStack {
            List {
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
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Customize Home")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadState()
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
}
