//
//  AssetType.swift
//  ByJo
//

import Foundation

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
    case pensionPlan = "Pension Plan"
    case annuity = "Annuity"

    // Debts and Liabilities
    case mortgage = "Mortgage"
    case creditCardDebt = "Credit Card Debt"
    case personalLoan = "Personal Loan"
    case studentLoan = "Student Loan"
    case autoLoan = "Auto Loan"

    // Other
    case businessOwnership = "Business Ownership"
    case trustFund = "Trust Fund"
    case intellectualProperty = "Intellectual Property"
    case peerToPeerLending = "Peer-to-Peer Lending"
    case crowdfundingInvestment = "Crowdfunding Investment"
    case other = "Other"

    var displayName: String {
        NSLocalizedString(rawValue, comment: "")
    }
}
