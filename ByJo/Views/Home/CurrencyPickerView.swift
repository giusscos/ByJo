//
//  CurrencyPickerView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 12/08/25.
//

import SwiftUI

struct CurrencyPickerView: View {
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("showCurrencyPicker") var showOnboarding: Bool = true
    
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Hey, I'm ByJo 👋")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Before you start, set your preferred currency")
                .font(.title3)
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
            
            Picker("Currency", selection: $currencyCode) {
                ForEach(CurrencyCode.allCases, id: \.self) { currency in
                    Text(currency.rawValue)
                }
            }
            .pickerStyle(.wheel)
            
            Button {
                showOnboarding = false
                
                dismiss()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .tint(.accent)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

#Preview {
    CurrencyPickerView()
}
