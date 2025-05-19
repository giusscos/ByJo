import SwiftUI
import Charts

struct AssetsComparisonChart: View {
    let assets: [Asset]
    let assetComparisonData: [(Asset, Decimal, Decimal)]
    let showingChartLabels: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assets Comparison")
                .font(.title2)
                .bold()
            
            if !assets.isEmpty {
                let currentTotal = assetComparisonData.reduce(0) { $0 + $1.1 }
                let previousTotal = assetComparisonData.reduce(0) { $0 + $1.2 }
                let percentageChange = previousTotal != 0 ? ((currentTotal - previousTotal) / abs(previousTotal)) * 100 : 0
                
                VStack (alignment: .leading) {
                    HStack (alignment: .lastTextBaseline) {
                        Text("Current:")
                            .foregroundStyle(.secondary)
                        
                        Text(currentTotal, format: .currency(code: assets.first!.currency.rawValue))
                            .bold()
                            .foregroundStyle(.blue)
                        
                        Text(percentageChange, format: .number.precision(.fractionLength(1)))
                            .bold()
                            .foregroundStyle(percentageChange >= 0 ? .green : .red)
                        +
                        Text("%")
                            .bold()
                            .foregroundStyle(percentageChange >= 0 ? .green : .red)
                    }
                    
                    HStack (alignment: .lastTextBaseline) {
                        Text("Previos:")
                            .foregroundStyle(.secondary)
                        
                        Text(previousTotal, format: .currency(code: assets.first!.currency.rawValue))
                            .bold()
                            .foregroundStyle(.blue.opacity(0.5))
                    }
                }
                
            }
            
            Chart(assetComparisonData, id: \.0.id) { item in
                BarMark(
                    x: .value("Asset", item.0.name),
                    y: .value("Current", item.1)
                )
                .foregroundStyle(by: .value("Period", "Current"))
                .position(by: .value("Period", "Current"))
                .annotation(position: .top) {
                    if showingChartLabels {
                        let percentage = item.2 != 0 ? ((item.1 - item.2) / abs(item.2)) * 100 : 0
                        Text(percentage, format: .number.precision(.fractionLength(1)))
                            .font(.caption2)
                            .foregroundStyle(percentage >= 0 ? .green : .red)
                            .bold()
                    }
                }
                
                BarMark(
                    x: .value("Asset", item.0.name),
                    y: .value("Previous", item.2)
                )
                .foregroundStyle(by: .value("Period", "Previous"))
                .position(by: .value("Period", "Previous"))
            }
            .chartForegroundStyleScale([
                "Current": Color.blue,
                "Previous": Color.blue.opacity(0.5)
            ])
            .chartLegend(showingChartLabels ? .visible : .hidden)
            .chartYAxis(.hidden)
            .chartXAxis(.hidden)
            .frame(height: 200)
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    AssetsComparisonChart(assets: [], assetComparisonData: [], showingChartLabels: true)
} 
