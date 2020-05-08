//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

/// Internal prefix used by the image catalouge.
private let cardIconPrefix: String = "card-icon-"

/// Enumeration of supported provider/networks a card or funding source can be owned by
enum CardNetwork: String, Equatable {
    case amex
    case diners
    case discover
    case jcb
    case mastercard
    case unionpay
    case visa
    case other
    case unknown

    // MARK: - Convenience

    var displayTitle: String {
        switch self {
        case .mastercard:
            return "Mastercard Credit"
        case .visa:
            return rawValue.uppercased()
        default:
            return rawValue.capitalized
        }
    }

    var brandingIcon: UIImage? {
        let imageName = "\(cardIconPrefix)\(rawValue)".lowercased()
        let icon = UIImage(named: imageName, in: Bundle.main, compatibleWith: nil)
        if self == .unknown {
            return icon?.withRenderingMode(.alwaysTemplate)
        }
        return icon?.withRenderingMode(.alwaysOriginal)
    }
}
