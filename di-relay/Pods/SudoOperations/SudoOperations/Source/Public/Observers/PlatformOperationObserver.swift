//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Observer protocol for implementers that wish to be notified of significant `PlatformOperation` lifecycle events.
public protocol PlatformOperationObserver {

    /// Invoked when the `PlatformOperation` enters its `executing` State.
    func operationDidStart(operation: PlatformOperation)

    func operation(_ operation: PlatformOperation, didProduceOperation producedOperation: Operation)

    /// Invoked when the `PlatformOperation` is about to transition from `finishing` to `finished`.
    func operationDidFinish(operation: PlatformOperation, errors: [Error])
}
