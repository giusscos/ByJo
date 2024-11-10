//
//  Asset.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import SwiftData

@Model
class Asset {
    var id: UUID = UUID()
    var name: String = ""
    var currency: CurrencyCode = CurrencyCode.usd
    var icon: String = ""
    var type: AssetType = AssetType.cash
    var initialBalance: Decimal = 0
    var timestamp: Date = Date.now
    
    @Relationship(deleteRule: .cascade) var operations: [AssetOperation]?
    @Relationship(deleteRule: .cascade) var goals: [Goal]?
    
    init(name: String, currency: CurrencyCode = CurrencyCode.usd, icon: String = "💰", type: AssetType = AssetType.cash, initialBalance: Decimal) {
        self.id = UUID()
        self.name = name
        self.currency = currency
        self.icon = icon
        self.type = type
        self.initialBalance = initialBalance
        self.timestamp = Date.now
    }
    
    func calculateCurrentBalance() -> Decimal {
        return operations?.reduce(initialBalance) { $0 + $1.amount } ?? initialBalance
    }
}

enum CurrencyCode: String, CaseIterable, Codable {
    case usd = "USD"  // United States Dollar
    case eur = "EUR"  // Euro
    case gbp = "GBP"  // British Pound Sterling
    case jpy = "JPY"  // Japanese Yen
    case cad = "CAD"  // Canadian Dollar
    case aud = "AUD"  // Australian Dollar
    case chf = "CHF"  // Swiss Franc
    case cny = "CNY"  // Chinese Yuan
    case inr = "INR"  // Indian Rupee
    case rub = "RUB"  // Russian Ruble
    case brl = "BRL"  // Brazilian Real
    case zar = "ZAR"  // South African Rand
    case mxn = "MXN"  // Mexican Peso
    case krw = "KRW"  // South Korean Won
    case sek = "SEK"  // Swedish Krona
    case nok = "NOK"  // Norwegian Krone
    case dkk = "DKK"  // Danish Krone
    case hkd = "HKD"  // Hong Kong Dollar
    case sgd = "SGD"  // Singapore Dollar
    case nzd = "NZD"  // New Zealand Dollar
    case thb = "THB"  // Thai Baht
    case tryy = "TRY" // Turkish Lira
    case myr = "MYR"  // Malaysian Ringgit
    case idr = "IDR"  // Indonesian Rupiah
    case php = "PHP"  // Philippine Peso
    case pln = "PLN"  // Polish Zloty
    case huf = "HUF"  // Hungarian Forint
    case czk = "CZK"  // Czech Koruna
    case ils = "ILS"  // Israeli New Shekel
    case aed = "AED"  // United Arab Emirates Dirham
    case sar = "SAR"  // Saudi Riyal
    case kwd = "KWD"  // Kuwaiti Dinar
    case bdt = "BDT"  // Bangladeshi Taka
    case lkr = "LKR"  // Sri Lankan Rupee
    case vnd = "VND"  // Vietnamese Dong
    case egp = "EGP"  // Egyptian Pound
    case ngn = "NGN"  // Nigerian Naira
    case ars = "ARS"  // Argentine Peso
    case clp = "CLP"  // Chilean Peso
    case pkr = "PKR"  // Pakistani Rupee
    case ron = "RON"  // Romanian Leu
    case uah = "UAH"  // Ukrainian Hryvnia
    case bgn = "BGN"  // Bulgarian Lev
    case hrk = "HRK"  // Croatian Kuna
    case rsd = "RSD"  // Serbian Dinar
    case isk = "ISK"  // Icelandic Króna
    case jod = "JOD"  // Jordanian Dinar
    case omr = "OMR"  // Omani Rial
    case qar = "QAR"  // Qatari Riyal
    case mvr = "MVR"  // Maldivian Rufiyaa
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy, .cny: return "¥"
        case .cad: return "CA$"
        case .aud: return "A$"
        case .chf: return "CHF"
        case .inr: return "₹"
        case .rub: return "₽"
        case .brl: return "R$"
        case .zar: return "R"
        case .mxn: return "Mex$"
        case .krw: return "₩"
        case .sek, .nok, .dkk: return "kr"
        case .hkd: return "HK$"
        case .sgd: return "S$"
        case .nzd: return "NZ$"
        case .thb: return "฿"
        case .tryy: return "₺"
        case .myr: return "RM"
        case .idr: return "Rp"
        case .php: return "₱"
        case .pln: return "zł"
        case .huf: return "Ft"
        case .czk: return "Kč"
        case .ils: return "₪"
        case .aed: return "د.إ"
        case .sar: return "﷼"
        case .kwd: return "د.ك"
        case .bdt: return "৳"
        case .lkr: return "රු"
        case .vnd: return "₫"
        case .egp: return "£"
        case .ngn: return "₦"
        case .ars: return "$"
        case .clp: return "$"
        case .pkr: return "₨"
        case .ron: return "lei"
        case .uah: return "₴"
        case .bgn: return "лв"
        case .hrk: return "kn"
        case .rsd: return "дин"
        case .isk: return "kr"
        case .jod: return "د.ا"
        case .omr: return "﷼"
        case .qar: return "﷼"
        case .mvr: return "Rf"
        }
    }
}

enum AssetType: String, CaseIterable, Codable {
    // Cash and Bank Accounts
    case cash = "Cash"
    case bankAccount = "Bank Account"
    case savingsAccount = "Savings Account"
    case checkingAccount = "Checking Account"
    
    // Investments
    case stocks = "Stocks"
    case bonds = "Bonds"
    case mutualFunds = "Mutual Funds"
    case etfs = "ETFs"
    case reit = "REIT"
    case crypto = "Cryptocurrency"
    case commodities = "Commodities"
    case pensionFund = "Pension Fund"
    case privateEquity = "Private Equity"
    case hedgeFund = "Hedge Fund"
    
    // Real Estate
    case primaryResidence = "Primary Residence"
    case rentalProperty = "Rental Property"
    case vacationHome = "Vacation Home"
    case commercialProperty = "Commercial Property"
    case land = "Land"
    
    // Tangible Assets
    case vehicle = "Vehicle"
    case art = "Art"
    case collectibles = "Collectibles"
    case jewelry = "Jewelry"
    case preciousMetals = "Precious Metals"
    
    // Insurance
    case lifeInsurance = "Life Insurance"
    case healthInsurance = "Health Insurance"
    case disabilityInsurance = "Disability Insurance"
    
    // Retirement Accounts
    case ira = "IRA"
    case rothIra = "Roth IRA"
//    case 401k = "401(k)"
    case pensionPlan = "Pension Plan"
    case annuity = "Annuity"
    
    // Debts and Liabilities
    case mortgage = "Mortgage"
    case creditCardDebt = "Credit Card Debt"
    case personalLoan = "Personal Loan"
    case studentLoan = "Student Loan"
    case autoLoan = "Auto Loan"
    
    // Other Investments and Miscellaneous Accounts
    case businessOwnership = "Business Ownership"
    case trustFund = "Trust Fund"
    case intellectualProperty = "Intellectual Property"
    case peerToPeerLending = "Peer-to-Peer Lending"
    case crowdfundingInvestment = "Crowdfunding Investment"
    case other = "Other"
}
