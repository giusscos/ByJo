import Foundation
import SwiftData

enum CSVError: Error {
    case invalidFormat
    case invalidHeader
    case invalidData
    case invalidAmount
    case invalidDate
    case invalidCategory
    case invalidAsset
    case exportError
    case duplicateOperation(Int)
    
    var description: String {
        switch self {
        case .invalidFormat:
            return "The CSV file format is invalid"
        case .invalidHeader:
            return "The CSV headers do not match the required format"
        case .invalidData:
            return "Some data in the CSV file is invalid"
        case .invalidAmount:
            return "Invalid amount format"
        case .invalidDate:
            return "Invalid date format"
        case .invalidCategory:
            return "Invalid category"
        case .invalidAsset:
            return "Invalid asset"
        case .exportError:
            return "Error exporting data"
        case .duplicateOperation(let count):
            return "\(count) operations were skipped because they already exist"
        }
    }
}

class CSVManager {
    static let shared = CSVManager()
    private let dateFormatter: DateFormatter
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
    }
    
    // Required CSV headers
    private let requiredHeaders = ["Date", "Name", "Amount", "Category", "Asset", "Note"]
    
    // CSV template for users
    func getCSVTemplate() -> String {
        return """
        Date,Name,Amount,Category,Asset,Note
        2024-03-20,March Salary,1000.00,Salary,Bank Account,"Monthly salary, including bonus"
        2024-03-21,Grocery Shopping,-50.00,Food,Cash,"Groceries, fruits and vegetables"
        """
    }
    
    func validateHeaders(_ headers: [String]) -> Bool {
        return Set(headers) == Set(requiredHeaders)
    }
    
    func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentValue = ""
        var insideQuotes = false
        
        for char in line {
            switch char {
            case "\"":
                insideQuotes.toggle()
            case ",":
                if insideQuotes {
                    currentValue.append(char)
                } else {
                    result.append(currentValue)
                    currentValue = ""
                }
            default:
                currentValue.append(char)
            }
        }
        
        // Add the last value
        result.append(currentValue)
        
        return result.map { $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "") }
    }
    
    private func isDuplicate(_ operation: AssetOperation, existingOperations: [AssetOperation]) -> Bool {
        return existingOperations.contains { existing in
            existing.date == operation.date &&
            existing.name == operation.name &&
            existing.amount == operation.amount &&
            existing.category?.id == operation.category?.id &&
            existing.asset?.id == operation.asset?.id
        }
    }
    
    func importCSV(from url: URL, context: ModelContext, assets: [Asset], categories: [CategoryOperation]) throws -> [AssetOperation] {
        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = content.components(separatedBy: .newlines)
        
        guard rows.count > 1 else { throw CSVError.invalidFormat }
        
        let headers = parseCSVLine(rows[0])
        guard validateHeaders(headers) else { throw CSVError.invalidHeader }
        
        var operations: [AssetOperation] = []
        var duplicateCount = 0
        
        // Get existing operations for duplicate checking
        let descriptor = FetchDescriptor<AssetOperation>()
        let existingOperations = try context.fetch(descriptor)
        
        // Skip header row
        for row in rows.dropFirst() where !row.isEmpty {
            let values = parseCSVLine(row)
            guard values.count == requiredHeaders.count else { continue }
            
            // Parse date
            guard let date = dateFormatter.date(from: values[0]) else {
                throw CSVError.invalidDate
            }
            
            // Get name
            let name = values[1]
            
            // Parse amount
            guard let amount = Decimal(string: values[2]) else {
                throw CSVError.invalidAmount
            }
            
            // Find category
            let categoryName = values[3]
            guard let category = categories.first(where: { $0.name == categoryName }) else {
                throw CSVError.invalidCategory
            }
            
            // Find asset
            let assetName = values[4]
            guard let asset = assets.first(where: { $0.name == assetName }) else {
                throw CSVError.invalidAsset
            }
            
            let note = values[5]
            
            let operation = AssetOperation(name: name, currency: asset.currency, date: date, amount: amount, asset: asset, category: category, note: note)
            
            // Check for duplicates
            if isDuplicate(operation, existingOperations: existingOperations) {
                duplicateCount += 1
                continue
            }
            
            operations.append(operation)
            context.insert(operation)
        }
        
        if duplicateCount > 0 {
            throw CSVError.duplicateOperation(duplicateCount)
        }
        
        return operations
    }
    
    private func escapeCSVValue(_ value: String) -> String {
        if value.contains(",") {
            return "\"\(value)\""
        }
        return value
    }
    
    func exportCSV(operations: [AssetOperation]) throws -> String {
        var csvString = requiredHeaders.joined(separator: ",") + "\n"
        
        for operation in operations {
            let row = [
                dateFormatter.string(from: operation.date),
                operation.name,
                "\(operation.amount)",
                operation.category?.name ?? "",
                operation.asset?.name ?? "",
                escapeCSVValue(operation.note)
            ]
            csvString += row.joined(separator: ",") + "\n"
        }
        
        return csvString
    }
} 
