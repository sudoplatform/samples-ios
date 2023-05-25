//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Data {
    /// Encodes the data in base64url URL and filename-safe format.
    ///
    /// # Reference
    /// https://en.wikipedia.org/wiki/Base64#Variants_summary_table
    func base64URLEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }

    /// Decodes the given string in base64url URL and filename-safe format.
    ///
    /// # Reference
    /// https://en.wikipedia.org/wiki/Base64#Variants_summary_table
    init?(base64URLEncoded string: String) {
        self.init(base64Encoded: string
            .replacingOccurrences(of: "_", with: "/")
            .replacingOccurrences(of: "-", with: "+"))
    }
}
