//
//  EditCategoryOperation.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 10/11/24.
//

import SwiftUI
import SwiftData

struct EditCategoryOperation: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Bindable var category: CategoryOperation

    var body: some View {
        VStack{
            HStack {
                Button (role: .destructive) {
                    modelContext.delete(category)
                    
                    dismiss()
                } label: {
                    Label("Delete", systemImage: "chevron.left")
                        .labelStyle(.titleOnly)
                }.frame(maxWidth: .infinity, alignment: .leading)
                
                Button {
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark.circle")
                        .labelStyle(.titleOnly)
                }.frame(maxWidth: .infinity, alignment: .trailing)
            }.padding()
            
            List {
                TextField("Name", text: $category.name)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .listStyle(.plain)
        }
    }
}

#Preview {
    EditCategoryOperation(category: CategoryOperation(name: "Bills"))
}
