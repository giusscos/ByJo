import SwiftUI
import Charts

struct AssetsOverviewChart: View {
    let assets: [Asset]
    let operations: [AssetOperation]
    let showingChartLabels: Bool
    let dateRange: DateRangeOption
    
    var filteredData: [AssetOperation] {
        filterData(for: dateRange, data: operations)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assets Overview")
                .font(.title2)
                .bold()
            
            if let assetsCurrency = assets.first {
                let totalBalance = assets.reduce(Decimal(0)) { $0 + $1.calculateBalanceForDateRange(dateRange) }
                Text("The sum of your assets hits ") + Text(totalBalance, format: .currency(code: assetsCurrency.currency.rawValue))
                    .bold()
                    .foregroundStyle(Color.accentColor)
            }
            
            Chart(assets) { value in
                BarMark(
                    x: .value("Asset", value.name),
                    y: .value("Amount", value.calculateBalanceForDateRange(dateRange))
                )
                .foregroundStyle(by: .value("Asset", value.name))
                .cornerRadius(8)
            }
            .chartLegend(showingChartLabels ? .visible : .hidden)
            .chartYAxis(.hidden)
            .chartXAxis(.hidden)
            .frame(height: 200)
            .padding(.vertical, 8)
        }
    }
    
    private func filterData(for dateRange: DateRangeOption, data: [AssetOperation]) -> [AssetOperation] {
        let calendar = Calendar.current
        let now = Date()
        
        switch dateRange {
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            return data.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            return data.filter { $0.date >= monthAgo }
        case .threeMonths:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now)!
            return data.filter { $0.date >= threeMonthsAgo }
        case .sixMonths:
            let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now)!
            return data.filter { $0.date >= sixMonthsAgo }
        case .year:
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now)!
            return data.filter { $0.date >= yearAgo }
        case .all:
            return data
        }
    }
}

#Preview {
    AssetsOverviewChart(assets: [], operations: [], showingChartLabels: true, dateRange: .all)
} 
