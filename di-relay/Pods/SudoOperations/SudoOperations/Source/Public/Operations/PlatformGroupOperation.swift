//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging

/// Performs multiple related children operations.
open class PlatformGroupOperation: PlatformOperation, PlatformOperationQueueDelegate {

    // MARK: - Properties

    /// Queue that performs the associated `PlatformOperation`'s.
    private let internalQueue: PlatformOperationQueue

    /// First operation in the queue, used to manage run order and internal dependencies.
    private let startingOperation = BlockOperation()

    /// Final operation in the queue, used to manage run order and internal dependencies.
    private let finishingOperation = BlockOperation()

    /// Array of errors that have been aggregrated during the internal run of the associated `PlatformOperation`'s.
    ///
    /// These errors are added to the underlying `PlatformOperation` errors on completion of this operation.
    private(set) public var aggregatedErrors: [Error] = []

    /// Convenience variable to determine if any errors occurred on the operation.
    public var errorsOccurred: Bool {
        return !aggregatedErrors.isEmpty
    }

    // MARK: - Lifecycle

    /// Initialize a PlatformGroupOperation.
    ///
    /// - Parameter logger: Diagnostic log.
    /// - Parameter operations: Operations to add to the Group Operation.
    public convenience init(logger: Logger, operations: Operation...) {
        self.init(logger: logger, operations: operations)
    }

    /// Initialize a PlatformGroupOperation.
    ///
    /// - Parameter logger: Diagnostic log.
    /// - Parameter operations: Operations to add to the Group Operation.
    /// - Parameter internalQueue: Queue used internally to execute the children platform operations.
    public init(logger: Logger, operations: [Operation], internalQueue: PlatformOperationQueue = PlatformOperationQueue()) {
        self.internalQueue = internalQueue
        super.init(logger: logger)

        internalQueue.isSuspended = true
        internalQueue.delegate = self
        internalQueue.addOperation(startingOperation)

        operations.forEach {
            internalQueue.addOperation($0)
        }
    }

    // MARK: - Methods

    /// Adds the specified operation to the receiver.
    ///
    /// For more details, see `PlatformOperationQueue.addOperation(:)`.
    ///
    /// - Parameter operation: The operation to be added to the queue.
    public func addOperation(_ operation: Operation) {
        internalQueue.addOperation(operation)
    }

    /// Adds the specified operations to the receiver.
    ///
    /// For more details, see `PlatformOperationQueue.addOperations(:waitUntilFinished:)`.
    ///
    /// - Parameter operation: The operations to be added to the queue.
    public func addOperations(_ operations: [Operation]) {
        internalQueue.addOperations(operations, waitUntilFinished: false)
    }

    /// Aggregate an error to the Operation.
    ///
    /// - Parameter error: Error to aggregate.
    public final func addErrorToAggregate(error: Error) {
        aggregatedErrors.append(error)
    }

    /// Aggregate an error to the Operation.
    ///
    /// - Parameter error: Error to aggregate.
    @available(*, deprecated, message: "Please use addErrorToAggregate(error:) instead.")
    public final func aggregateError(error: Error) {
        addErrorToAggregate(error: error)
    }

    /// Called when an internal operation finishes. By default, this method has no behaviour and is intended to be subclassed.
    open func operationDidFinish(_ operation: Operation, withErrors errors: [Error]) {
        // No op.
    }

    // MARK: - Methods: PlatformOperation

    /// Calls cancel on the internal queue operations.
    open override func cancel() {
        internalQueue.cancelAllOperations()
        super.cancel()
    }

    /// Allow internal operations to process.
    open override func execute() {
        internalQueue.isSuspended = false
        internalQueue.addOperation(finishingOperation)
    }

    // MARK: - Conformance: PlatformOperationQueueDelegate

    public final func operationQueue(operationQueue: PlatformOperationQueue, willAddOperation operation: Operation) {
        assert(!finishingOperation.isFinished && !finishingOperation.isExecuting, "cannot add new operations to a group after the group has completed")

        if operation !== finishingOperation {
            finishingOperation.addDependency(operation)
        }

        if operation !== startingOperation {
            operation.addDependency(startingOperation)
        }
    }

    public final func operationQueue(operationQueue: PlatformOperationQueue, operationDidFinish operation: Operation, withErrors errors: [Error]) {
        aggregatedErrors.append(contentsOf: errors)

        if operation === finishingOperation {
            internalQueue.isSuspended = true
            finish(aggregatedErrors)
        } else if operation !== startingOperation {
            operationDidFinish(operation, withErrors: errors)
        }
    }
}
