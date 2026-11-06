//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Formats phone numbers and places from the telephony service for display.
enum PhoneNumberDisplay {

    /// Formats an E.164 number for reading, e.g. "+13853252157" as "+1 (385) 325-2157". Only North American numbers are
    /// formatted; others are returned unchanged, as their grouping varies by country.
    static func number(_ e164: String) -> String {
        let digits = e164.dropFirst()
        guard e164.hasPrefix("+1"), digits.count == 11, digits.allSatisfy(\.isNumber) else {
            return e164
        }
        let national = Array(digits.dropFirst())
        return "+1 (\(String(national[0..<3]))) \(String(national[3..<6]))-\(String(national[6..<10]))"
    }

    /// Joins a locality and region for display, e.g. "SPRINGVILLE" and "UT" as "Springville, UT". The service returns
    /// names in upper case; short regions are kept as they are, since they're usually codes.
    static func place(locality: String?, region: String?) -> String? {
        let parts = [
            locality.map { $0.capitalized(with: .current) },
            region.map { $0.count <= 3 ? $0 : $0.capitalized(with: .current) }
        ]
        let place = parts.compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
        return place.isEmpty ? nil : place
    }
}
