//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging

/// Operation implementation that all other Operations should be subclassed from.
///
/// This class requires that it is enqueued to a `PlatformOperationQueue` to be executed.
open class PlatformOperation: Operation {

    // MARK: - Supplementary: KVO State Mechanisms

    private static let stateKeyPath = "state"

    @objc class func keyPathsForValuesAffectingIsReady() -> Set<NSObject> {
        return [stateKeyPath as NSObject]
    }

    @objc class func keyPathsForValuesAffectingIsExecuting() -> Set<NSObject> {
        return [stateKeyPath as NSObject]
    }

    @objc class func keyPathsForValuesAffectingIsFinished() -> Set<NSObject> {
        return [stateKeyPath as NSObject]
    }

    // MARK: - Supplementary: State Enumeration

    /// State of a Platform Operation.
    /// - initialized: Initial state - automatically set when creating a new `PlatformOperation`.
    /// - pending: Ready to begin execution.
    /// - executing: `PlatformOperation` is currently executing.
    /// - finished: `PlatformOperation` has finished executing and in a completed state.
    public enum State: Int, Comparable {
        case initialized
        case pending
        case executing
        case finished

         /// Boolean operation to determine of a `PlatformOperation.State` can transition between states.
         /// This is useful for assertion testing to make sure there is not a bug in the code.
        func canTransitionToState(_ target: State) -> Bool {
            switch (self, target) {
            case (.initialized, .pending),
                 (.pending, .executing),
                 (.pending, .finished),
                 (.executing, .finished):
                return true
            default:
                return false
            }
        }

        // MARK: - Conformance: Comparable

        public static func < (lhs: PlatformOperation.State, rhs: PlatformOperation.State) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - Properties: Diagnostics

    /// Logging mechanism - provides debugging information.
    public let logger: Logger

    /// Operation ID.
    public let id: String = UUID().uuidString

    /// Operation start time.
    public private(set) var startTime = Date(timeIntervalSince1970: 0)

    /// Operation finish time.
    public private(set) var finishTime = Date(timeIntervalSince1970: 0)

    // MARK: - Properties: State/Lifecycle

    /// A lock to protect the access to the `_state` property.
    private let stateLock = NSLock()

    /// Private storage for state of the `PlatformOperation` that is KVO observed.
    private var _state = State.initialized

    /// State of the `PlatformOperation`. Set is protected with `stateLock`.
    public private(set) var state: State {
        get {
            return self.stateLock.withCriticalScope {
                self._state
            }
        }
        set {
            willChangeValue(forKey: PlatformOperation.stateKeyPath)
            self.stateLock.withCriticalScope {
                guard self._state != .finished else {
                    return
                }
                assert(_state.canTransitionToState(newValue), "performing invalid state transition.")
                logger.debug("Operation \(type(of: self)) (\(id)) transitioning from \(_state) to \(newValue).")
                self._state = newValue
            }
            didChangeValue(forKey: PlatformOperation.stateKeyPath)
        }
    }

    /// Array of associated conditions the operation needs to meet before executing.
    /// These are evaluated during `State.evaluatingConditions`.
    private(set) var conditions: [PlatformOperationCondition] = []

    /// Array of observers that are observing this operation.
    private(set) var observers: [PlatformOperationObserver] = []

    /// Errors associated with the execution of this operation.
    private(set) public var errors: [Error] = []

    // MARK: - Properties: Operation

    override open var isExecuting: Bool {
        return self.state == .executing
    }

    override open var isFinished: Bool {
        return self.state == .finished
    }

    // MARK: - Lifecycle

    /// Initialize a Platform Operation.
    public init(logger: Logger) {
        self.logger = logger
    }

    // MARK: - Methods

    /// Transitions `PlatformOperation` to `pending` state to begin evaluating conditions.
    final func willEnqueue() {
        state = .pending
    }

    /// Executes the operation. Subclasses must override this method.
    ///
    /// When subclassing, ensure that `finish()` is called somehow to avoid definite deadlock.
    open func execute() {
        fatalError("Must override!")
    }

    /// Optional override to perform work when the operation is finishing.
    open func finished(_ errors: [Error]) {
        // No Op.
    }

    /// Performs the finish work of the operation.
    public final func finish(_ errors: [Error] = []) {
        guard !isFinished else {
            return
        }
        let combinedErrors = errors + self.errors
        self.errors = combinedErrors

        self.finishTime = Date()
        let elapsed = finishTime.timeIntervalSince(self.startTime)
        self.logger.info("\(type(of: self)) (id=\(self.id)) finished in \(elapsed) sec. Errors: \(combinedErrors)")

        finished(combinedErrors)
        observers.forEach { $0.operationDidFinish(operation: self, errors: combinedErrors)}

        state = .finished
    }

    /// Convenience method to cancel with an error. If no error is supplied, the internal error management will not be affected.
    public func cancelWithError(_ error: Error? = nil) {
        if let error = error {
            errors.append(error)
        }
        cancel()
    }

    /// Convenienvce method to finish with an error. If no error is supplied, the internal error management will not be affected.
    public final func finishWithError(_ error: Error?) {
        if let error = error {
            finish([error])
        } else {
            finish()
        }
    }

    public final func produceOperation(_ operation: Operation) {
        observers.forEach {
            $0.operation(self, didProduceOperation: operation)
        }
    }

    /// Add a condition to the `PlatformOperation`.
    public func addCondition(_ condition: PlatformOperationCondition) {
        assert(state < .executing, "Cannot modify conditions after execution has begun.")
        conditions.append(condition)
    }

    /// Add a observer to the `PlatformOperation`.
    public func addObserver(_ observer: PlatformOperationObserver) {
        assert(state < .executing, "Cannot modify observers after execution has begun.")
        observers.append(observer)
    }

    // MARK: - Methods: Operation

    public override func addDependency(_ op: Operation) {
        assert(state < .executing, "Dependencies cannot be modified after execution has begun.")
        super.addDependency(op)
    }

    public override final func start() {
        logger.debug("state: \(state)")
        guard !isCancelled else {
            finish()
            return
        }
        super.start()
    }

    public override final func main() {
        assert(state == .pending, "This operation must be performed on an operation queue.")
        guard errors.isEmpty, !isCancelled else {
            finish()
            return
        }
        logger.debug("Operation \(id) evaluating conditions.")
        PlatformOperationConditionEvaluator.evaluate(conditions: conditions, operation: self) { [unowned self] failures in
            guard failures.isEmpty else {
                self.finish(failures)
                return
            }
            self.startTime = Date()
            self.logger.info("\(type(of: self)) started")
            self.state = .executing
            self.observers.forEach {
                $0.operationDidStart(operation: self)
            }
            self.execute()
        }
    }

}
