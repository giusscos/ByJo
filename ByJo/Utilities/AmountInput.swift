//
//  AmountInput.swift
//  ByJo
//

import Foundation

extension String {
    /// An amount typed by the user, ready for `Decimal(string:)`.
    ///
    /// The decimal pad follows the region: in Saudi Arabia and other Arabic regions it types
    /// Eastern Arabic digits (٢٥٠٠) and the Arabic decimal separator (٫), and in Persian
    /// regions it types Extended Arabic-Indic digits (۲۵۰۰). `Decimal(string:)` only reads
    /// ASCII digits, so those become 0–9 here, and a comma or Arabic separator becomes a dot.
    var normalizedAmountInput: String {
        var result = ""
        result.reserveCapacity(count)
        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x0660...0x0669: // Arabic-Indic digits
                result.unicodeScalars.append(Unicode.Scalar(scalar.value - 0x0660 + 0x30)!)
            case 0x06F0...0x06F9: // Extended Arabic-Indic (Persian) digits
                result.unicodeScalars.append(Unicode.Scalar(scalar.value - 0x06F0 + 0x30)!)
            case 0x066B, 0x002C: // Arabic decimal separator, comma
                result.append(".")
            case 0x066C, 0x200E, 0x200F, 0x061C: // Arabic thousands separator, direction marks
                continue
            default:
                result.unicodeScalars.append(scalar)
            }
        }
        return result
    }
}
