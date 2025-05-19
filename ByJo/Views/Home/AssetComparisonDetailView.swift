import SwiftUI
import SwiftData
import Charts

struct AssetComparisonDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Query var assets: [Asset]
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    
    @State private var dateRange: DateRangeOption = .all
    @State private var selectedAssets: Set<Asset> = []
    @State private var showingChartLabels = true
    @State private var selectedAsset: Asset?
    
    var availableDateRanges: [DateRangeOption] {
        DateRangeOption.availableRanges(for: operations)
    }
    
    private var assetComparisonData: [(asset: Asset, currentValue: Decimal, previousValue: Decimal)] {
        let assetsToCompare = selectedAssets.isEmpty ? assets : Array(selectedAssets)
        return assetsToCompare.map { asset in
            let currentValue = asset.calculateBalanceForDateRange(dateRange)
            let previousValue = asset.calculatePreviousBalanceForDateRange(dateRange)
            return (asset: asset, currentValue: currentValue, previousValue: previousValue)
        }
    }
    
    var totalCurrentValue: Decimal {
        assetComparisonData.reduce(0) { $0 + $1.currentValue }
    }
    
    var totalPreviousValue: Decimal {
        assetComparisonData.reduce(0) { $0 + $1.previousValue }
    }
    
    var percentageChange: Decimal {
        guard totalPreviousValue != 0 else { return 0 }
        let change = totalCurrentValue - totalPreviousValue
        return (change / abs(totalPreviousValue)) * 100
    }
    
    var topAsset: (Asset, Decimal, Decimal)? {
        assetComparisonData.max { $0.currentValue < $1.currentValue }
    }
    
    var body: some View {
        VStack {
            Picker("Date Range", selection: $dateRange.animation().animation(.spring())) {
                ForEach(availableDateRanges) { range in
                    Text(range.label)
                        .tag(range)
                }
            }
            .pickerStyle(.segmented)
            
            if !assets.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Current:")
                                .foregroundStyle(.secondary)
                            
                            Text(totalCurrentValue, format: .currency(code: assets.first!.currency.rawValue))
                                .font(.title3)
                                .bold()
                                .foregroundStyle(.blue)
                        
                            Text(percentageChange, format: .number.precision(.fractionLength(1)))
                                .font(.subheadline)
                                .foregroundStyle(percentageChange >= 0 ? .green : .red)
                            +
                            Text("%")
                                .font(.subheadline)
                                .foregroundStyle(percentageChange >= 0 ? .green : .red)
                        }
                        
                        HStack {
                            Text("Previos:")
                                .foregroundStyle(.secondary)
                            
                            Text(totalPreviousValue, format: .currency(code: assets.first!.currency.rawValue))
                                .font(.title3)
                                .bold()
                                .foregroundStyle(.blue.opacity(0.5))
                        }
                    }
                    .padding(.vertical, 8)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(assets) { asset in
                                Button {
                                    if selectedAssets.contains(asset) {
                                        selectedAssets.remove(asset)
                                    } else {
                                        selectedAssets.insert(asset)
                                    }
                                } label: {
                                    Text(asset.name)
                                }
                                .tint(selectedAssets.contains(asset) ? .accentColor : .secondary)
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.capsule)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Chart(assetComparisonData, id: \.asset.id) { item in
                        BarMark(
                            x: .value("Asset", item.asset.name),
                            y: .value("Current", item.currentValue)
                        )
                        .foregroundStyle(by: .value("Period", "Current"))
                        .position(by: .value("Period", "Current"))
                        .annotation(position: .top) {
                            if showingChartLabels {
                                let percentage = item.previousValue != 0 ? ((item.currentValue - item.previousValue) / abs(item.previousValue)) * 100 : 0
                                Text(percentage, format: .number.precision(.fractionLength(1)))
                                    .font(.caption2)
                                    .foregroundStyle(percentage >= 0 ? .green : .red)
                                    .bold()
                            }
                        }
                        
                        BarMark(
                            x: .value("Asset", item.asset.name),
                            y: .value("Previous", item.previousValue)
                        )
                        .foregroundStyle(by: .value("Period", "Previous"))
                        .position(by: .value("Period", "Previous"))
                    }
                    .chartForegroundStyleScale([
                        "Current": Color.blue,
                        "Previous": Color.blue.opacity(0.5)
                    ])
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic) { value in
                            AxisValueLabel {
                                if let asset = value.as(String.self) {
                                    Text(asset)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .frame(height: 300)
                    .padding(.vertical, 8)
                    .chartOverlay { proxy in
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(.clear)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            let x = value.location.x
                                            let width = geometry.size.width
                                            let assetCount = assetComparisonData.count
                                            let sectionWidth = width / CGFloat(assetCount)
                                            let index = Int(x / sectionWidth)
                                            
                                            if index >= 0 && index < assetComparisonData.count {
                                                selectedAsset = assetComparisonData[index].asset
                                            }
                                        }
                                )
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Assets Found",
                    systemImage: "exclamationmark",
                    description: Text("You need to add an asset by selecting the Assets tab and tapping the plus button on the top right corner")
                )
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
        .navigationTitle("Assets Comparison")
    }
}

#Preview {
    AssetComparisonDetailView()
}
