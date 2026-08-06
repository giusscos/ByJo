//
//  DataManager.swift
//  ByJo

import Foundation
import SwiftData

// MARK: - JSON Codable types

struct ByJoExport: Codable {
    let version: Int
    let exportDate: Date
    let categories: [CategoryExport]
    let assets: [AssetExport]
    let operations: [OperationExport]
    let goals: [GoalExport]
}

struct CategoryExport: Codable {
    let id: String
    let name: String
}

struct AssetExport: Codable {
    let id: String
    let name: String
    let type: String
    let initialBalance: String
    let timestamp: Date
}

struct OperationExport: Codable {
    let id: String
    let name: String
    let date: Date
    let amount: String
    let note: String
    let frequency: String
    let assetId: String
    let categoryId: String?
    let swapId: String?
    let seriesId: String?
}

struct GoalExport: Codable {
    let id: String
    let title: String
    let startingAmount: String
    let targetAmount: String
    let dueDate: Date?
    let assetId: String
    let completedDate: Date?
    let completedStatus: String?
}

// MARK: - CSV Import types

struct CSVImportRow {
    let name: String
    let date: Date
    let amount: Decimal
    let assetName: String
    let categoryName: String
    let frequency: RecurrenceFrequency
    let note: String
}

struct ColumnMapping: Equatable {
    var name: String? = nil
    var date: String? = nil
    var amount: String? = nil
    var asset: String? = nil
    var category: String? = nil
    var frequency: String? = nil
    var note: String? = nil

    var isComplete: Bool {
        name != nil && date != nil && amount != nil && asset != nil
    }
}

private struct DuplicateKey: Hashable {
    let name: String
    let day: Date
    let amount: Decimal
    let assetName: String
}

enum DataImportError: LocalizedError, Identifiable {
    case missingRequiredMapping(String)
    case rowError(Int, String)
    case invalidJSON(String)
    case unsupportedVersion(Int)

    var id: String { localizedDescription }

    var errorDescription: String? {
        switch self {
        case .missingRequiredMapping(let field):
            return String(format: String(localized: "Required field not mapped: %@"), field)
        case .rowError(let row, let message):
            return String(format: String(localized: "Row %lld: %@"), row, message)
        case .invalidJSON(let message):
            return String(format: String(localized: "Invalid backup file: %@"), message)
        case .unsupportedVersion(let v):
            return String(format: String(localized: "Unsupported backup version %lld. Please update ByJo."), v)
        }
    }
}

// MARK: - DataManager

enum DataManager {

    // MARK: JSON Export

    static func exportJSON(
        assets: [Asset],
        operations: [AssetOperation],
        categories: [CategoryOperation],
        goals: [Goal]
    ) throws -> Data {
        let export = ByJoExport(
            version: 1,
            exportDate: Date(),
            categories: categories.map {
                CategoryExport(id: $0.id.uuidString, name: $0.name)
            },
            assets: assets.map {
                AssetExport(
                    id: $0.id.uuidString,
                    name: $0.name,
                    type: $0.type.rawValue,
                    initialBalance: "\($0.initialBalance)",
                    timestamp: $0.timestamp
                )
            },
            operations: operations.map {
                OperationExport(
                    id: $0.id.uuidString,
                    name: $0.name,
                    date: $0.date,
                    amount: "\($0.amount)",
                    note: $0.note,
                    frequency: $0.frequency.rawValue,
                    assetId: $0.asset?.id.uuidString ?? "",
                    categoryId: $0.category?.id.uuidString,
                    swapId: $0.swapId?.uuidString,
                    seriesId: $0.seriesId?.uuidString
                )
            },
            goals: goals.map {
                GoalExport(
                    id: $0.id.uuidString,
                    title: $0.title,
                    startingAmount: "\($0.startingAmount)",
                    targetAmount: "\($0.targetAmount)",
                    dueDate: $0.dueDate,
                    assetId: $0.asset?.id.uuidString ?? "",
                    completedDate: $0.completedDate,
                    completedStatus: $0.completedStatus?.rawValue
                )
            }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(export)
    }

    // MARK: CSV Export

    static func exportCSV(operations: [AssetOperation]) -> String {
        var lines = ["name,date,amount,asset,category,frequency,note"]
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate]
        for op in operations.sorted(by: { $0.date < $1.date }) {
            let fields: [String] = [
                escape(op.name),
                iso.string(from: op.date),
                "\(op.amount)",
                escape(op.asset?.name ?? ""),
                escape(op.category?.name ?? ""),
                op.frequency.rawValue,
                escape(op.note)
            ]
            lines.append(fields.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private static func escape(_ s: String) -> String {
        guard s.contains(",") || s.contains("\"") || s.contains("\n") else { return s }
        return "\"\(s.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    // MARK: CSV Parsing

    static func parseCSV(_ text: String) -> (headers: [String], rows: [[String]]) {
        var lines = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\r")) }
            .filter { !$0.isEmpty }
        guard !lines.isEmpty else { return ([], []) }
        let headers = parseLine(lines.removeFirst())
        return (headers, lines.map { parseLine($0) })
    }

    private static func parseLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex
        while i < line.endIndex {
            let c = line[i]
            if inQuotes {
                if c == "\"" {
                    let next = line.index(after: i)
                    if next < line.endIndex && line[next] == "\"" {
                        current.append("\"")
                        i = line.index(after: next)
                        continue
                    }
                    inQuotes = false
                } else {
                    current.append(c)
                }
            } else {
                switch c {
                case "\"": inQuotes = true
                case ",":
                    result.append(current)
                    current = ""
                default:
                    current.append(c)
                }
            }
            i = line.index(after: i)
        }
        result.append(current)
        return result
    }

    // MARK: CSV Validation

    static func validateAndParseCSV(
        headers: [String],
        rows: [[String]],
        mapping: ColumnMapping
    ) -> (valid: [CSVImportRow], errors: [DataImportError]) {
        var errors: [DataImportError] = []

        if mapping.name == nil   { errors.append(.missingRequiredMapping("Description")) }
        if mapping.date == nil   { errors.append(.missingRequiredMapping("Date")) }
        if mapping.amount == nil { errors.append(.missingRequiredMapping("Amount")) }
        if mapping.asset == nil  { errors.append(.missingRequiredMapping("Asset")) }

        guard errors.isEmpty else { return ([], errors) }

        guard
            let nameCol = mapping.name,   let nameIdx   = headers.firstIndex(of: nameCol),
            let dateCol = mapping.date,   let dateIdx   = headers.firstIndex(of: dateCol),
            let amtCol  = mapping.amount, let amountIdx = headers.firstIndex(of: amtCol),
            let assetCol = mapping.asset, let assetIdx  = headers.firstIndex(of: assetCol)
        else {
            return ([], [.missingRequiredMapping(String(localized: "Column not found in file"))])
        }

        let categoryIdx = mapping.category.flatMap  { headers.firstIndex(of: $0) }
        let frequencyIdx = mapping.frequency.flatMap { headers.firstIndex(of: $0) }
        let noteIdx = mapping.note.flatMap           { headers.firstIndex(of: $0) }

        var valid: [CSVImportRow] = []

        for (i, row) in rows.enumerated() {
            let rowNum = i + 2

            func field(_ idx: Int) -> String {
                idx < row.count ? row[idx].trimmingCharacters(in: .whitespaces) : ""
            }

            let name      = field(nameIdx)
            let assetName = field(assetIdx)
            let dateStr   = field(dateIdx)
            let amountStr = field(amountIdx)

            if name.isEmpty      { errors.append(.rowError(rowNum, String(localized: "Description is empty"))); continue }
            if assetName.isEmpty { errors.append(.rowError(rowNum, String(localized: "Asset name is empty"))); continue }

            guard let date = parseDate(dateStr) else {
                errors.append(.rowError(rowNum, String(format: String(localized: "Cannot parse date \"%@\""), dateStr))); continue
            }

            let cleanAmount = amountStr
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: ",", with: ".")
            guard let amount = Decimal(string: cleanAmount) else {
                errors.append(.rowError(rowNum, String(format: String(localized: "Cannot parse amount \"%@\""), amountStr))); continue
            }

            let freqStr = frequencyIdx.map { field($0) } ?? ""
            let frequency = RecurrenceFrequency(rawValue: freqStr) ?? .single

            valid.append(CSVImportRow(
                name: name,
                date: date,
                amount: amount,
                assetName: assetName,
                categoryName: categoryIdx.map { field($0) } ?? "",
                frequency: frequency,
                note: noteIdx.map { field($0) } ?? ""
            ))
        }

        return (valid, errors)
    }

    private static func parseDate(_ string: String) -> Date? {
        let s = string.trimmingCharacters(in: .whitespaces)
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: s) { return d }
        for format in ["yyyy-MM-dd", "dd/MM/yyyy", "MM/dd/yyyy", "dd-MM-yyyy", "MM-dd-yyyy", "yyyy/MM/dd"] {
            let f = DateFormatter()
            f.dateFormat = format
            f.locale = Locale(identifier: "en_US_POSIX")
            if let d = f.date(from: s) { return d }
        }
        return nil
    }

    // MARK: JSON Validation

    static func validateJSON(_ data: Data) throws -> ByJoExport {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let export = try decoder.decode(ByJoExport.self, from: data)
            guard export.version == 1 else {
                throw DataImportError.unsupportedVersion(export.version)
            }
            return export
        } catch let error as DataImportError {
            throw error
        } catch {
            throw DataImportError.invalidJSON(error.localizedDescription)
        }
    }

    // MARK: Auto-detect mapping

    static func autoDetectMapping(headers: [String]) -> ColumnMapping {
        var mapping = ColumnMapping()
        let normalized = headers.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        func match(keys: [String]) -> String? {
            for key in keys {
                if let idx = normalized.firstIndex(of: key) { return headers[idx] }
            }
            for key in keys {
                if let idx = normalized.firstIndex(where: { $0.contains(key) }) { return headers[idx] }
            }
            return nil
        }

        mapping.name     = match(keys: ["name", "description", "desc", "title", "memo", "narration", "transaction"])
        mapping.date     = match(keys: ["date", "day", "datetime", "transaction date", "transactiondate"])
        mapping.amount   = match(keys: ["amount", "value", "sum", "total", "price"])
        mapping.asset    = match(keys: ["asset", "account", "wallet", "bank", "source"])
        mapping.category = match(keys: ["category", "cat", "tag", "type"])
        mapping.frequency = match(keys: ["frequency", "recurrence", "freq"])
        mapping.note     = match(keys: ["note", "notes", "memo", "comment"])

        return mapping
    }

    // MARK: Duplicate detection

    static func countDuplicates(rows: [CSVImportRow], context: ModelContext) -> Int {
        guard let existing = try? context.fetch(FetchDescriptor<AssetOperation>()) else { return 0 }
        let cal = Calendar.current
        let existingKeys: Set<DuplicateKey> = Set(existing.compactMap { op in
            guard let assetName = op.asset?.name else { return nil }
            return DuplicateKey(name: op.name, day: cal.startOfDay(for: op.date), amount: op.amount, assetName: assetName)
        })
        return rows.filter { row in
            let key = DuplicateKey(name: row.name, day: cal.startOfDay(for: row.date), amount: row.amount, assetName: row.assetName)
            return existingKeys.contains(key)
        }.count
    }

    // MARK: Perform CSV Import

    @discardableResult
    static func importCSV(
        rows: [CSVImportRow],
        context: ModelContext,
        skipDuplicates: Bool = true
    ) throws -> (imported: Int, skipped: Int) {
        var assetCache: [String: Asset] = [:]
        var categoryCache: [String: CategoryOperation] = [:]

        let allAssets = try context.fetch(FetchDescriptor<Asset>())
        let allCategories = try context.fetch(FetchDescriptor<CategoryOperation>())

        for a in allAssets { assetCache[a.name] = a }
        for c in allCategories { categoryCache[c.name] = c }

        var existingKeys: Set<DuplicateKey> = []
        if skipDuplicates {
            let cal = Calendar.current
            let allOps = try context.fetch(FetchDescriptor<AssetOperation>())
            existingKeys = Set(allOps.compactMap { op in
                guard let assetName = op.asset?.name else { return nil }
                return DuplicateKey(name: op.name, day: cal.startOfDay(for: op.date), amount: op.amount, assetName: assetName)
            })
        }

        let cal = Calendar.current
        var imported = 0
        var skipped = 0

        for row in rows {
            if skipDuplicates {
                let key = DuplicateKey(name: row.name, day: cal.startOfDay(for: row.date), amount: row.amount, assetName: row.assetName)
                if existingKeys.contains(key) {
                    skipped += 1
                    continue
                }
            }

            if assetCache[row.assetName] == nil {
                let newAsset = Asset(name: row.assetName, type: .bankAccount, initialBalance: 0)
                context.insert(newAsset)
                assetCache[row.assetName] = newAsset
            }

            if !row.categoryName.isEmpty, categoryCache[row.categoryName] == nil {
                let newCat = CategoryOperation(name: row.categoryName)
                context.insert(newCat)
                categoryCache[row.categoryName] = newCat
            }

            let op = AssetOperation(
                name: row.name,
                date: row.date,
                amount: row.amount,
                asset: assetCache[row.assetName],
                category: row.categoryName.isEmpty ? nil : categoryCache[row.categoryName],
                note: row.note,
                frequency: row.frequency
            )
            context.insert(op)
            imported += 1
        }

        try context.save()
        return (imported, skipped)
    }

    // MARK: JSON Duplicate counting

    struct JSONDuplicateCounts {
        let categories: Int
        let assets: Int
        let operations: Int
        let goals: Int
        var total: Int { categories + assets + operations + goals }
    }

    static func countJSONDuplicates(export: ByJoExport, context: ModelContext) -> JSONDuplicateCounts {
        let existingCatNames  = Set((try? context.fetch(FetchDescriptor<CategoryOperation>()))?.map { $0.name } ?? [])
        let existingAssetNames = Set((try? context.fetch(FetchDescriptor<Asset>()))?.map { $0.name } ?? [])
        let existingOps   = (try? context.fetch(FetchDescriptor<AssetOperation>())) ?? []
        let existingGoals = (try? context.fetch(FetchDescriptor<Goal>())) ?? []

        let cal = Calendar.current
        let existingOpKeys: Set<DuplicateKey> = Set(existingOps.compactMap { op in
            guard let assetName = op.asset?.name else { return nil }
            return DuplicateKey(name: op.name, day: cal.startOfDay(for: op.date), amount: op.amount, assetName: assetName)
        })
        let existingGoalTuples = existingGoals.compactMap { g -> (String, Decimal, String)? in
            guard let assetName = g.asset?.name else { return nil }
            return (g.title, g.targetAmount, assetName)
        }

        let exportAssetNames = Dictionary(uniqueKeysWithValues: export.assets.map { ($0.id, $0.name) })

        let dupCats  = export.categories.filter { existingCatNames.contains($0.name) }.count
        let dupAssets = export.assets.filter { existingAssetNames.contains($0.name) }.count
        let dupOps   = export.operations.filter { op in
            let assetName = exportAssetNames[op.assetId] ?? ""
            let amount = Decimal(string: op.amount) ?? 0
            return existingOpKeys.contains(DuplicateKey(name: op.name, day: cal.startOfDay(for: op.date), amount: amount, assetName: assetName))
        }.count
        let dupGoals = export.goals.filter { g in
            let assetName = exportAssetNames[g.assetId] ?? ""
            let targetAmount = Decimal(string: g.targetAmount) ?? 0
            return existingGoalTuples.contains { $0.0 == g.title && $0.1 == targetAmount && $0.2 == assetName }
        }.count

        return JSONDuplicateCounts(categories: dupCats, assets: dupAssets, operations: dupOps, goals: dupGoals)
    }

    // MARK: Perform JSON Import

    @discardableResult
    static func importJSON(
        _ export: ByJoExport,
        context: ModelContext,
        skipDuplicates: Bool = true
    ) throws -> JSONDuplicateCounts {
        let cal = Calendar.current
        let exportAssetNames = Dictionary(uniqueKeysWithValues: export.assets.map { ($0.id, $0.name) })

        // Load existing records for dedup and ID remapping
        var existingCatByName:   [String: CategoryOperation] = [:]
        var existingAssetByName: [String: Asset] = [:]
        var existingOpKeys:      Set<DuplicateKey> = []
        var existingGoalTuples:  [(String, Decimal, String)] = []

        if skipDuplicates {
            let cats  = try context.fetch(FetchDescriptor<CategoryOperation>())
            let assets = try context.fetch(FetchDescriptor<Asset>())
            let ops   = try context.fetch(FetchDescriptor<AssetOperation>())
            let goals = try context.fetch(FetchDescriptor<Goal>())

            for c in cats  { existingCatByName[c.name] = c }
            for a in assets { existingAssetByName[a.name] = a }
            existingOpKeys = Set(ops.compactMap { op in
                guard let assetName = op.asset?.name else { return nil }
                return DuplicateKey(name: op.name, day: cal.startOfDay(for: op.date), amount: op.amount, assetName: assetName)
            })
            existingGoalTuples = goals.compactMap { g in
                guard let assetName = g.asset?.name else { return nil }
                return (g.title, g.targetAmount, assetName)
            }
        }

        // exportId -> model object (either reused or newly inserted)
        var categoryMap: [String: CategoryOperation] = [:]
        var assetMap:    [String: Asset] = [:]

        var catSkipped = 0, assetSkipped = 0, opSkipped = 0, goalSkipped = 0

        for c in export.categories {
            if skipDuplicates, let existing = existingCatByName[c.name] {
                categoryMap[c.id] = existing
                catSkipped += 1
            } else {
                let cat = CategoryOperation(name: c.name)
                context.insert(cat)
                categoryMap[c.id] = cat
            }
        }

        for a in export.assets {
            if skipDuplicates, let existing = existingAssetByName[a.name] {
                assetMap[a.id] = existing
                assetSkipped += 1
            } else {
                let balance = Decimal(string: a.initialBalance) ?? 0
                let type = AssetType(rawValue: a.type) ?? .other
                let asset = Asset(name: a.name, type: type, initialBalance: balance)
                asset.timestamp = a.timestamp
                context.insert(asset)
                assetMap[a.id] = asset
            }
        }

        for op in export.operations {
            let amount = Decimal(string: op.amount) ?? 0
            if skipDuplicates {
                let assetName = exportAssetNames[op.assetId] ?? ""
                let key = DuplicateKey(name: op.name, day: cal.startOfDay(for: op.date), amount: amount, assetName: assetName)
                if existingOpKeys.contains(key) { opSkipped += 1; continue }
            }
            let frequency = RecurrenceFrequency(rawValue: op.frequency) ?? .single
            let operation = AssetOperation(
                name: op.name,
                date: op.date,
                amount: amount,
                asset: assetMap[op.assetId],
                category: op.categoryId.flatMap { categoryMap[$0] },
                note: op.note,
                frequency: frequency,
                swapId: op.swapId.flatMap { UUID(uuidString: $0) },
                seriesId: op.seriesId.flatMap { UUID(uuidString: $0) }
            )
            context.insert(operation)
        }

        for g in export.goals {
            if skipDuplicates {
                let assetName = exportAssetNames[g.assetId] ?? ""
                let targetAmount = Decimal(string: g.targetAmount) ?? 0
                if existingGoalTuples.contains(where: { $0.0 == g.title && $0.1 == targetAmount && $0.2 == assetName }) {
                    goalSkipped += 1; continue
                }
            }
            let goal = Goal(
                title: g.title,
                startingAmount: Decimal(string: g.startingAmount) ?? 0,
                targetAmount: Decimal(string: g.targetAmount) ?? 0,
                dueDate: g.dueDate,
                asset: assetMap[g.assetId]
            )
            goal.completedDate = g.completedDate
            goal.completedStatus = g.completedStatus.flatMap { StatusGoal(rawValue: $0) }
            context.insert(goal)
        }

        try context.save()
        return JSONDuplicateCounts(categories: catSkipped, assets: assetSkipped, operations: opSkipped, goals: goalSkipped)
    }

    // MARK: Temp file helpers

    static func writeToTemp(data: Data, filename: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
