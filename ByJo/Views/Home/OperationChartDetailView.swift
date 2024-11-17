//
//  OperationChartDetailView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 15/11/24.
//

import SwiftUI
import SwiftData
import Charts

struct OperationChartDetailView: View {
    @State private var dateRange: DateRangeOption = .month
    
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    
    var filteredData: [AssetOperation] {
        filterData(for: dateRange, data: operations)
    }
    
    var incomeData: [AssetOperation] {
        filterData(for: dateRange, data: operations.filter { $0.amount > 0.0 })
    }
    
    var outcomeData: [AssetOperation] {
        filterData(for: dateRange, data: operations.filter { $0.amount < 0.0 })
    }
    
    var totalIncome: Decimal {
        filteredData.filter { $0.amount > 0.0 }.reduce(0) { $0 + $1.amount }
    }
    
    var totalOutcome: Decimal {
        filteredData.filter { $0.amount < 0.0 }.reduce(0) { $0 + $1.amount }
    }
    
    var operationsData: [OperationDataType] {
        [OperationDataType(type: "Outcome", data: outcomeData),
        OperationDataType(type: "Income", data: incomeData)]
    }
    
    var body: some View {
        ScrollView {
            Text("Operations")
                .font(.largeTitle)
                .bold()
                .frame(maxWidth: .infinity, alignment: .topLeading)
            
            VStack (alignment: .leading, spacing: 0) {
                Text("Total Income: ")
                + Text(totalIncome, format: .currency(code: filteredData.first!.currency.rawValue))
                    .bold()
                
                Text("Total Outcome: ")
                + Text(totalOutcome, format: .currency(code: filteredData.first!.currency.rawValue))
                    .bold()
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            
            Picker("Date Range", selection: $dateRange.animation()) {
                ForEach(DateRangeOption.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            
            Chart (operationsData) { operation in
                ForEach(operation.data) { value in
                    PointMark(
                        x: .value("Date", value.date),
                        y: .value("Amount", value.amount)
                    )
                }
                .foregroundStyle(by: .value("Type", operation.type))
                .symbol(by: .value("Type", operation.type))
                .symbolSize(30)
            }
            .chartForegroundStyleScale([
                "Outcome": Color.red,
                "Income": Color.green
            ])
            .chartYScale(domain: (totalOutcome * 2.5)...(totalIncome * 1.5))
            .aspectRatio(1, contentMode: .fit)
        }.padding()
    }
}


#Preview {
    OperationChartDetailView()
}
