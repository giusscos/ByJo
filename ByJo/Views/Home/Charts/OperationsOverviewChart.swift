import SwiftUI
import Charts

struct OperationsOverviewChart: View {
    let assets: [Asset]
    let filteredData: [AssetOperation]
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
        }
    }
}

#Preview {
    OperationsOverviewChart(assets: [], filteredData: [], showingChartLabels: true)
} 
