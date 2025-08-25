//  VersionedLabel.swift
//  ByJo
//
//  Created by Your Coding Assistant on 18/08/25.
//

import SwiftUI

/// A reusable SwiftUI Label that shows a different system image depending on the iOS version.
struct VersionedLabel: View {
    let title: String
    let newSystemImage: String
    let oldSystemImage: String

    var body: some View {
//        if #available(iOS 26, *) {
//            Label(title, systemImage: newSystemImage)
//        } else {
            Label(title, systemImage: oldSystemImage)
//        }
    }
}
