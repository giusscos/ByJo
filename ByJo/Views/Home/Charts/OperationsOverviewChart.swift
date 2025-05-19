import SwiftUI
import Charts

struct OperationsOverviewChart: View {
    let assets: [Asset]
    let filteredData: [AssetOperation]
    let operationsData: [OperationDataType]
    let showingChartLabels: Bool
    
    var totalIncome: Decimal {
        filteredData.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
    }
    
    var totalExpenses: Decimal {
        filteredData.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Operations Overview")
                .font(.title2)
                .bold()
            
            if !filteredData.isEmpty {
                if let assetsCurrency = assets.first {
                    if totalIncome > 0 {
                        Text("Your incomes this period hits ") + Text(totalIncome, format: .currency(code: assetsCurrency.currency.rawValue))
                            .bold()
                            .foregroundStyle(Color.green)
                    }
                    
                    if totalExpenses < 0 {
                        Text("Your outcomes this period hits ") + Text(totalExpenses, format: .currency(code: assetsCurrency.currency.rawValue))
                            .bold()
                            .foregroundStyle(Color.red)
                    }
                }
                
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
                .chartLegend(showingChartLabels ? .visible : .hidden)
                .chartYAxis(.hidden)
                .chartXAxis(.hidden)
                .frame(height: 200)
                .padding(.vertical, 8)
            }
        }
    }
}

#Preview {
    OperationsOverviewChart(assets: [], filteredData: [], operationsData: [], showingChartLabels: true)
} 