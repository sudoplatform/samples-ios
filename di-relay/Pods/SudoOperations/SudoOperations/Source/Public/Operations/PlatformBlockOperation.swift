//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging

public typealias BlockClosure = () -> Void

/// General purpose block `PlatformOperation`.
public class PlatformBlockOperation: PlatformOperation {

    // MARK: - Properties

    /// Closure to be performed by the operation
    private let block: BlockClosure?

    // MARK: - Lifecycle

    /// Initialize a `PlatformBlockOperation`.
    public init(logger: Logger, _ block: BlockClosure? = nil) {
        self.block = block
        super.init(logger: logger)
    }

    // MARK: - Overrides

    public override func execute() {
        guard let block = block else {
            finish()
            return
        }
        block()
        finish()
    }
}
