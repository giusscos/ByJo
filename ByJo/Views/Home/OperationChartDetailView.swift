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
    @State private var dateRange: DateRangeOption = .all
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    @Query var assets: [Asset]
    
    var availableDateRanges: [DateRangeOption] {
        DateRangeOption.availableRanges(for: operations)
    }
    
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
    
    var chartYScale: ClosedRange<Decimal> {
        let maxIncome = totalIncome
        let minOutcome = totalOutcome
        let buffer = max(abs(maxIncome), abs(minOutcome)) * 0.1
        
        return (minOutcome - buffer)...(maxIncome + buffer)
    }
    
    var body: some View {
        VStack {
            if operations.isEmpty {
                ContentUnavailableView(
                    "No Operations Found",
                    systemImage: "exclamationmark",
                    description: Text("You need to add an operation by selecting the Operations tab and tapping the plus button on the top right corner")
                )
            } else if filteredData.isEmpty {
                ContentUnavailableView(
                    "No Data for Selected Range",
                    systemImage: "exclamationmark",
                    description: Text("Try selecting a different date range or add new operations")
                )
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    if let currency = assets.first?.currency {
                        VStack(alignment: .leading, spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Income")
                                    .foregroundStyle(.secondary)
                                Text(totalIncome, format: .currency(code: currency.rawValue))
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(Color.green)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Outcome")
                                    .foregroundStyle(.secondary)
                                Text(totalOutcome, format: .currency(code: currency.rawValue))
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(Color.red)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        
                        Picker("Date Range", selection: $dateRange.animation()) {
                            ForEach(availableDateRanges) { range in
                                Text(range.label).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Chart(operationsData) { operation in
                            ForEach(operation.data) { value in
                                LineMark(
                                    x: .value("Date", value.date, unit: .day),
                                    y: .value("Amount", value.amount)
                                )
                                .foregroundStyle(by: .value("Type", operation.type))
                                
                                PointMark(
                                    x: .value("Date", value.date, unit: .day),
                                    y: .value("Amount", value.amount)
                                )
                                .foregroundStyle(by: .value("Type", operation.type))
                            }
                        }
                        .chartForegroundStyleScale([
                            "Outcome": Color.red,
                            "Income": Color.green
                        ])
                        .chartYScale(domain: chartYScale)
                        .chartLegend(.visible)
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .chartXAxis {
                            AxisMarks(preset: .aligned) { value in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month().day().year())
                            }
                        }
                        .frame(height: 300)
                    }
                }
                .padding(.top)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
        .navigationTitle("Operations")
    }
}

#Preview {
    OperationChartDetailView()
}
