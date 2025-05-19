import SwiftUI
import Charts

struct CategoriesOverviewChart: View {
    let categories: [CategoryOperation]
    let filteredData: [AssetOperation]
    let operations: [AssetOperation]
    let showingChartLabels: Bool
    
    var categoryWithHighestBalance: (CategoryOperation, Decimal) {
        findCategoryWithHighestBalance(categories: categories)
    }
    
    var categoryWithLowestBalance: (CategoryOperation, Decimal) {
        findCategoryWithLowestBalance(categories: categories)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories Overview")
                .font(.title2)
                .bold()
            
            if !filteredData.isEmpty {
                if let operation = operations.first(where: { $0.category == categoryWithHighestBalance.0 }) {
                    if let asset = operation.asset {
                        Text(categoryWithHighestBalance.0.name)
                            .bold()
                            .foregroundStyle(Color.accentColor)
                        + Text(" this period hits ")
                        + Text(categoryWithHighestBalance.1, format: .currency(code: asset.currency.rawValue))
                            .bold()
                            .foregroundStyle(Color.green)
                    }
                }
                
                if let operation = operations.first(where: { $0.category == categoryWithLowestBalance.0 }) {
                    if let asset = operation.asset {
                        Text(categoryWithLowestBalance.0.name)
                            .bold()
                            .foregroundStyle(Color.accentColor)
                        + Text(" this period hits ")
                        + Text(categoryWithLowestBalance.1, format: .currency(code: asset.currency.rawValue))
                            .bold()
                            .foregroundStyle(Color.red)
                    }
                }
                
                let groupedData = Dictionary(grouping: filteredData, by: { $0.category?.name ?? "" })
                    .map { (key, values) in
                        (
                            category: key,
                            total: values.reduce(0) { $0 + $1.amount }
                        )
                    }
                    .filter { !$0.category.isEmpty }
                    .sorted { abs($0.total) > abs($1.total) }
                
                Chart(groupedData, id: \.category) { item in
                    BarMark(
                        x: .value("Amount", item.total),
                        y: .value("Category", item.category)
                    )
                    .foregroundStyle(by: .value("Category", item.category))
                    .cornerRadius(8)
                }
                .chartLegend(showingChartLabels ? .visible : .hidden)
                .chartYAxis(.hidden)
                .chartXAxis(.hidden)
                .frame(height: 200)
                .padding(.vertical, 8)
            }
        }
    }
    
    func calculateCategoryBalance(category: CategoryOperation) -> Decimal {
        let operationsForCategory = filteredData.filter { $0.category?.id == category.id }
        return operationsForCategory.reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    func findCategoryWithHighestBalance(categories: [CategoryOperation]) -> (CategoryOperation, Decimal) {
        let categoryBalances = categories.map { category in
            let balance = calculateCategoryBalance(category: category)
            return (category, balance)
        }
        return categoryBalances.max { $0.1 < $1.1 } ?? (CategoryOperation(name: ""), Decimal(0))
    }
    
    func findCategoryWithLowestBalance(categories: [CategoryOperation]) -> (CategoryOperation, Decimal) {
        let categoryBalances = categories.map { category in
            let balance = calculateCategoryBalance(category: category)
            return (category, balance)
        }
        return categoryBalances.min { $0.1 < $1.1 } ?? (CategoryOperation(name: ""), Decimal(0))
    }
}

#Preview {
    CategoriesOverviewChart(categories: [], filteredData: [], operations: [], showingChartLabels: true)
} 