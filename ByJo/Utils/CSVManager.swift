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
    case emptyFile
    case detailedError(String)
    
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
        case .emptyFile:
            return "The file is empty"
        case .detailedError(let message):
            return message
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
        // Ensure notes with commas are properly quoted
        return """
        Date,Name,Amount,Category,Asset,Note
        2024-03-20,March Salary,1000.00,Salary,Cash,"Monthly salary, including bonus"
        2024-03-21,Grocery Shopping,-50.00,Food,Cash,"Groceries, fruits and vegetables"
        """
    }
    
    func validateHeaders(_ headers: [String]) -> Bool {
        let normalizedHeaders = headers.map { $0.trimmingCharacters(in: .whitespaces) }
        return Set(normalizedHeaders) == Set(requiredHeaders)
    }
    
    func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentValue = ""
        var insideQuotes = false
        
        let chars = Array(line)
        var i = 0
        
        while i < chars.count {
            let char = chars[i]
            
            switch char {
            case "\"":
                if i + 1 < chars.count && chars[i + 1] == "\"" {
                    // Handle escaped quotes
                    currentValue.append("\"")
                    i += 2
                } else {
                    insideQuotes.toggle()
                    i += 1
                }
            case ",":
                if insideQuotes {
                    currentValue.append(char)
                    i += 1
                } else {
                    // Remove surrounding quotes if present
                    let trimmed = currentValue.trimmingCharacters(in: .whitespaces)
                    if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") {
                        currentValue = String(trimmed.dropFirst().dropLast())
                    }
                    result.append(currentValue.trimmingCharacters(in: .whitespaces))
                    currentValue = ""
                    i += 1
                }
            default:
                currentValue.append(char)
                i += 1
            }
        }
        
        // Handle the last value
        let trimmed = currentValue.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") {
            currentValue = String(trimmed.dropFirst().dropLast())
        }
        result.append(currentValue.trimmingCharacters(in: .whitespaces))
        
        return result
    }
    
    private func isDuplicate(_ operation: AssetOperation, existingOperations: [AssetOperation]) -> Bool {
        let isDuplicate = existingOperations.contains { existing in
            // Compare dates (only day precision)
            let calendar = Calendar.current
            let sameDay = calendar.isDate(existing.date, inSameDayAs: operation.date)
            
            // Compare names (case and emoji insensitive)
            let sameName = normalizeString(existing.name) == normalizeString(operation.name)
            
            // Compare amounts with a small tolerance for floating point differences
            let sameAmount = abs(existing.amount - operation.amount) < 0.001
            
            // Compare categories (case and emoji insensitive)
            let sameCategory = normalizeString(existing.category?.name ?? "") == normalizeString(operation.category?.name ?? "")
            
            // Compare assets (case and emoji insensitive)
            let sameAsset = normalizeString(existing.asset?.name ?? "") == normalizeString(operation.asset?.name ?? "")
            
            return sameDay && sameName && sameAmount && sameCategory && sameAsset
        }
        
        return isDuplicate
    }
    
    private func normalizeString(_ string: String) -> String {
        // Remove emojis and other special characters
        return string
            .components(separatedBy: CharacterSet.symbols.union(.emojis))
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
    
    private func findOrCreateCategory(_ categoryName: String, context: ModelContext, existingCategories: [CategoryOperation]) -> CategoryOperation {
        let normalizedSearchName = normalizeString(categoryName)
        
        // Try to find existing category (case insensitive and emoji-insensitive)
        if let existingCategory = existingCategories.first(where: { normalizeString($0.name) == normalizedSearchName }) {
            return existingCategory
        }
        
        // If not found, create new category with the original name (keeping emojis)
        let newCategory = CategoryOperation(name: categoryName.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(newCategory)
        return newCategory
    }
    
    private func findAsset(_ assetName: String, assets: [Asset]) -> Asset? {
        let normalizedSearchName = normalizeString(assetName)
        return assets.first { normalizeString($0.name) == normalizedSearchName }
    }
    
    func importCSV(from url: URL, context: ModelContext, assets: [Asset], categories: [CategoryOperation]) throws -> [AssetOperation] {
        // Try different encodings in order of likelihood
        let encodings: [String.Encoding] = [.utf8, .windowsCP1252, .isoLatin1, .ascii]
        var content: String?
        
        for encoding in encodings {
            do {
                content = try String(contentsOf: url, encoding: encoding)
                // If we successfully read the content, break out of the loop
                break
            } catch {
                // If this is the last encoding we're trying
                if encoding == encodings.last {
                    // Try reading the data first to provide more detailed error
                    do {
                        let data = try Data(contentsOf: url)
                        throw CSVError.detailedError("""
                            Could not read file with any supported encoding.
                            File size: \(data.count) bytes
                            First few bytes: \(Array(data.prefix(20)).map { String(format: "%02x", $0) }.joined(separator: " "))
                            Tried encodings: \(encodings.map { $0.description }.joined(separator: ", "))
                            Last error: \(error.localizedDescription)
                            
                            Please ensure the file:
                            1. Is a valid CSV file
                            2. Has been saved with UTF-8 encoding
                            3. Has not been corrupted
                            4. Does not contain special characters
                            
                            Try opening the file in a text editor and saving it again as UTF-8
                            """)
                    } catch {
                        throw CSVError.detailedError("Could not read file at all: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // Check if we successfully read the content
        guard var fileContent = content else {
            throw CSVError.detailedError("Could not read file with any supported encoding")
        }
        
        // Remove BOM if present
        if fileContent.hasPrefix("\u{FEFF}") {
            fileContent = String(fileContent.dropFirst())
        }
        
        var rows = fileContent.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !rows.isEmpty else {
            throw CSVError.emptyFile
        }
        
        guard rows.count > 1 else {
            throw CSVError.detailedError("File contains only headers without data")
        }
        
        let headers = parseCSVLine(rows[0])
        
        if headers.count != requiredHeaders.count {
            throw CSVError.detailedError("Expected \(requiredHeaders.count) columns but found \(headers.count). Headers found: \(headers.joined(separator: ", "))")
        }
        
        guard validateHeaders(headers) else {
            throw CSVError.detailedError("Headers do not match required format. Expected: \(requiredHeaders.joined(separator: ", ")). Found: \(headers.joined(separator: ", "))")
        }
        
        var operations: [AssetOperation] = []
        var duplicateCount = 0
        var errors: [String] = []
        
        // Get existing operations for duplicate checking
        let descriptor = FetchDescriptor<AssetOperation>()
        let existingOperations = try context.fetch(descriptor)
        
        // Skip header row
        rows.removeFirst()
        
        for (index, row) in rows.enumerated() {
            let values = parseCSVLine(row)
            
            guard values.count == requiredHeaders.count else {
                errors.append("Row \(index + 2) has \(values.count) columns, expected \(requiredHeaders.count)")
                continue
            }
            
            // Parse date
            guard let date = dateFormatter.date(from: values[0]) else {
                errors.append("Invalid date format in row \(index + 2): '\(values[0])'. Expected format: yyyy-MM-dd")
                continue
            }
            
            // Get name
            let name = values[1]
            if name.isEmpty {
                errors.append("Empty name in row \(index + 2)")
                continue
            }
            
            // Parse amount
            guard let amount = Decimal(string: values[2].trimmingCharacters(in: .whitespaces)) else {
                errors.append("Invalid amount format in row \(index + 2): '\(values[2])'")
                continue
            }
            
            // Find or create category
            let categoryName = values[3]
            if categoryName.isEmpty {
                errors.append("Empty category in row \(index + 2)")
                continue
            }
            let category = findOrCreateCategory(categoryName, context: context, existingCategories: categories)
            
            // Find asset (case insensitive)
            let assetName = values[4]
            if assetName.isEmpty {
                errors.append("Empty asset in row \(index + 2)")
                continue
            }
            
            guard let asset = findAsset(assetName, assets: assets) else {
                errors.append("Asset '\(assetName)' not found in row \(index + 2). Available assets: \(assets.map { $0.name }.joined(separator: ", "))")
                continue
            }
            
            let note = values[5]
            
            let operation = AssetOperation(name: name, currency: asset.currency, date: date, amount: amount, asset: asset, category: category, note: note)
            
            // Check for duplicates
            if isDuplicate(operation, existingOperations: existingOperations) {
                print("Skipping duplicate operation: \(name) on \(date)")
                duplicateCount += 1
                continue
            }
            
            operations.append(operation)
            context.insert(operation)
            
        }
        
        // If we have any errors, report them all at once
        if !errors.isEmpty {
            throw CSVError.detailedError("Found \(errors.count) errors:\n" + errors.joined(separator: "\n"))
        }
        
        if duplicateCount > 0 {
            throw CSVError.duplicateOperation(duplicateCount)
        }
        
        return operations
    }
    
    private func escapeCSVValue(_ value: String) -> String {
        // If the value contains commas, quotes, or newlines, wrap it in quotes
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            // Escape any existing quotes by doubling them
            let escapedValue = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escapedValue)\""
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

extension CharacterSet {
    static var emojis: CharacterSet {
        // Include various Unicode ranges that contain emoji
        var characterSet = CharacterSet()
        characterSet.insert(charactersIn: "\u{1F300}"..."\u{1F9FF}") // Miscellaneous Symbols and Pictographs
        characterSet.insert(charactersIn: "\u{1F600}"..."\u{1F64F}") // Emoticons
        characterSet.insert(charactersIn: "\u{1F680}"..."\u{1F6FF}") // Transport and Map Symbols
        characterSet.insert(charactersIn: "\u{2600}"..."\u{26FF}")   // Miscellaneous Symbols
        characterSet.insert(charactersIn: "\u{2700}"..."\u{27BF}")   // Dingbats
        characterSet.insert(charactersIn: "\u{FE00}"..."\u{FE0F}")   // Variation Selectors
        characterSet.insert(charactersIn: "\u{1F900}"..."\u{1F9FF}") // Supplemental Symbols and Pictographs
        characterSet.insert(charactersIn: "\u{1F1E6}"..."\u{1F1FF}") // Regional Indicator Symbols
        return characterSet
    }
}
