//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Provides a concrete implementation of a `PlatformOperationObserver` that can be used to supply block handlers to the starting and finishing of a
/// `PlatformOperation`.
public struct PlatformBlockObserver: PlatformOperationObserver {

    // MARK: - Supplementary: Type Alias

    public typealias StartHandler = ((PlatformOperation) -> Void)
    public typealias ProduceHandler = ((PlatformOperation, Operation) -> Void)
    public typealias FinishHandler = ((PlatformOperation, [Error]) -> Void)

    // MARK: - Properties

    /// Block to perform when an observed operation starts.
    private let startHandler: StartHandler?

    private let produceHandler: ProduceHandler?

    /// Block to perform when an observed operation finishes.
    private let finishHandler: FinishHandler?

    // MARK: - Lifecycle

    /// Initialize a `PlatformBlockObserver`.
    ///
    /// - Parameter startHandler: Block to perform when an observed operation starts.
    /// - Parameter finishHandler: Block to perform when an observed operation finishes.
    public init(
        startHandler: StartHandler? = nil,
        produceHandler: ProduceHandler? = nil,
        finishHandler: FinishHandler? = nil
    ) {
        self.startHandler = startHandler
        self.produceHandler = produceHandler
        self.finishHandler = finishHandler
    }

    // MARK: - Conformance: PlatformOperationObserver

    public func operationDidStart(operation: PlatformOperation) {
        startHandler?(operation)
    }

    public func operation(_ operation: PlatformOperation, didProduceOperation producedOperation: Operation) {
        produceHandler?(operation, producedOperation)
    }

    public func operationDidFinish(operation: PlatformOperation, errors: [Error]) {
        finishHandler?(operation, errors)
    }

}
