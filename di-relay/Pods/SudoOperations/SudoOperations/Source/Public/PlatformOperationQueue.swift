//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Delegate Protocol to allow inversion of event handling to a delegate.
@objc public protocol PlatformOperationQueueDelegate: NSObjectProtocol {
    /// Called when an `PlatformOperationQueue` will add an operation to its queue.
    @objc optional func operationQueue(operationQueue: PlatformOperationQueue, willAddOperation operation: Operation)

    /// Called when an `PlatformOperationQueue` operation finishes.
    @objc optional func operationQueue(operationQueue: PlatformOperationQueue, operationDidFinish operation: Operation, withErrors errors: [Error])
}

/// Subclass adding behaviour around `PlatformOperation` in a queue.
open class PlatformOperationQueue: OperationQueue {

    public weak var delegate: PlatformOperationQueueDelegate?

    // MARK: - Methods: OperationQueue

    /// Adds the specified operation to the receiver.
    ///
    /// If the operation is a `PlatformOperation`, the operation will have its conditions
    /// and extra functionality, such as delegation.
    ///
    /// - Parameter op: The operation to be added to the queue.
    open override func addOperation(_ op: Operation) {
        guard let operation = op as? PlatformOperation else {
            addOrdinaryOperation(op)
            return
        }

        let operationDelegate = PlatformBlockObserver(
            startHandler: nil,
            produceHandler: { [weak self] in
                self?.addOperation($1)
            },
            finishHandler: { [weak self] in
                if let queue = self {
                    queue.delegate?.operationQueue?(operationQueue: queue, operationDidFinish: $0, withErrors: $1)
                }
            })
        operation.addObserver(operationDelegate)

        let dependencies = operation.conditions.compactMap {
            $0.dependencyForOperation(operation)
        }
        dependencies.forEach {
            operation.addDependency($0)
            self.addOperation($0)
        }
        operation.willEnqueue()

        delegate?.operationQueue?(operationQueue: self, willAddOperation: op)
        super.addOperation(op)
    }

    open override func addOperation(_ block: @escaping () -> Void) {
        let op = BlockOperation(block: block)
        addOrdinaryOperation(op)
    }

    /// Adds the specified operations to the queue.
    ///
    /// See `PlatformOperationQueue.addOperation(:)` for more details.
    ///
    /// # Important
    /// If using `waitUntilFinished`, please ensure the queue is not suspended, or the call will block.
    ///
    /// - Parameters:
    ///   - ops: The operations to be added to the queue.
    ///   - wait: if true, will block and wait until all operations that are passed in have completed.
    open override func addOperations(_ ops: [Operation], waitUntilFinished wait: Bool) {
        // Two separate iterators are necessary to avoid a deadlock for dependent operations.
        ops.forEach {
            addOperation($0)
        }

        if wait {
            ops.forEach {
                $0.waitUntilFinished()
            }
        }
    }

    /// Add a non-`PlatformOperation` to the internal queue.
    ///
    /// This will add a completion block that will call the `delegate`.
    private func addOrdinaryOperation(_ op: Operation) {
        op.completionBlock = { [weak self, weak op] in
            guard let queue = self, let operation = op else {
                return
            }
            queue.delegate?.operationQueue?(operationQueue: queue, operationDidFinish: operation, withErrors: [])
        }
        delegate?.operationQueue?(operationQueue: self, willAddOperation: op)
        super.addOperation(op)
    }
}
