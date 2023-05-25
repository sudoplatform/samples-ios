//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension String {
    
    /// Splits this string into chunks of equal length. The last chunk can be smaller if the string's length
    /// is not divisible by the chunk length.
    ///
    /// - Parameter length: Chunk length.
    /// - Returns: Array of string chunks.
    func chunk(length: Int) -> [String] {
        var startIndex = self.startIndex
        var chunks: [String] = []
        
        while startIndex < self.endIndex {
            let endIndex = self.index(startIndex, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            chunks.append(String(self[startIndex..<endIndex]))
            startIndex = endIndex
        }
        
        return chunks
    }
    
}
