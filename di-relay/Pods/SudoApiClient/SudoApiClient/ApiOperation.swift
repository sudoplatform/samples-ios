//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging
import AWSAppSync
import SudoUser

public enum ApiOperationError: Error {
    /// One of preconditions of the operation was not met.
    case preconditionFailure

    /// Operation failed due to the user not being signed in.
    case notSignedIn

    /// Operation failed due to authorization error. This maybe due to the authentication token being
    /// invalid or other security controls prevent the user from accessing the API.
    case notAuthorized

    /// Operation failed due to it requiring tokens to be refreshed but something else is already in
    /// middle of refreshing the tokens.
    case refreshTokensOperationAlreadyInProgress

    /// Operation failed due to the backend entitlements error. This maybe due to the user not having
    /// sufficient entitlements or exceeding some other service limit.
    case insufficientEntitlements

    /// Operation failed due to it exceeding some limits imposed for the API. For example, this error
    /// can occur if the resource size exceeds the database record size limit.
    case limitExceeded

    /// Operation failed because the user account is locked.
    case accountLocked

    /// Operation failed due to an invalid request. This maybe due to the version mismatch between the
    /// client and the backend.
    case invalidRequest

    /// Indicates that an internal server error caused the operation to fail. The error is possibly transient
    /// and retrying at a later time may cause the operation to complete successfully
    case serviceError

    /// Indicates that there were too many attempts at sending API requests within a short period of
    /// time.
    case rateLimitExceeded

    /// Indicates the version of the object that is getting updated does not match the current version of the
    /// object in the backend. The caller should retrieve the current version of the object and reconcile the
    /// difference.
    case versionMismatch

    /// GraphQL endpoint returned an error.
    case graphQLError(cause: GraphQLError)

    /// GraphQL request failed due to connectivity, availability or access error.
    case requestFailed(response: HTTPURLResponse?, cause: Error?)

    /// AppSyncClient client returned an unexpected error.
    case appSyncClientError(cause: Error)

    /// Indicates that a fatal error occurred. This could be due to coding error, out-of-memory  condition
    /// or other conditions that is beyond control this library.
    case fatalError(description: String)

    static func fromGraphQLError(error: GraphQLError) -> ApiOperationError {
        guard let errorType = error[ApiOperation.SudoPlatformServiceError.type] as? String else {
          return .fatalError(description: "GraphQL operation failed but error type was not found in the response. \(error)")
        }

        switch errorType {
        case ApiOperation.SudoPlatformServiceError.insufficientEntitlementsError:
            return .insufficientEntitlements
        case ApiOperation.SudoPlatformServiceError.limitExceededError:
            return .limitExceeded
        case ApiOperation.SudoPlatformServiceError.conditionalCheckFailedException:
            return .versionMismatch
        case ApiOperation.SudoPlatformServiceError.accountLockedError:
            return .accountLocked
        case ApiOperation.SudoPlatformServiceError.decodingError:
            return .invalidRequest
        case ApiOperation.SudoPlatformServiceError.serviceError:
            return .serviceError
        default:
            return .graphQLError(cause: error)
        }
    }

    static func fromAppSyncClientError(error: Error) -> ApiOperationError {
        switch error {
        case AWSAppSyncClientError.authenticationError(let cause):
            switch cause {
            case GraphQLAuthProviderError.notSignedIn:
                return .notSignedIn
            case GraphQLAuthProviderError.notAuthorized:
                return .notAuthorized
            case GraphQLAuthProviderError.refreshTokensOperationAlreadyInProgress:
                return .refreshTokensOperationAlreadyInProgress
            default:
                return .fatalError(description: "Unexpected authentication error: \(cause)")
            }
        case AWSAppSyncClientError.requestFailed(_, let response, let cause):
            if let statusCode = response?.statusCode {
                if statusCode == 401 {
                    return .notAuthorized
                }
            }
            return .requestFailed(response: response, cause: cause)
        default:
            return .appSyncClientError(cause: error)
        }
    }
}

public enum ApiOperationState: Int {
    case ready = 0
    case executing
    case finished
}

/// Custom base operation for Sudo Platform API  operations. Provides common functionality
/// that all subclasses are expected to provide.
open class ApiOperation: Operation {

    struct SudoPlatformServiceError {
        static let type = "errorType"
        static let insufficientEntitlementsError = "sudoplatform.InsufficientEntitlementsError"
        static let decodingError = "sudoplatform.DecodingError"
        static let accountLockedError = "sudoplatform.AccountLockedError"
        static let limitExceededError = "sudoplatform.LimitExceededError"
        static let conditionalCheckFailedException = "DynamoDB:ConditionalCheckFailedException"
        static let serviceError = "sudoplatform.ServiceError"
    }

    private struct Constants {
        static let IsExecuting = "isExecuting"
        static let IsFinished = "isFinished"
        static let IsCancelled = "isCancelled"
    }

    let queue = DispatchQueue(label: "com.sudoplatform.api.client.operation")

    let logger: Logger

    private let stateLock = NSLock()

    private var _state: ApiOperationState = .ready

    /// Operation state.
    public private(set) var state: ApiOperationState {
        get {
            return self.stateLock.withCriticalScope { self._state }
        }
        set {
            self.stateLock.withCriticalScope {
                if self._state != newValue {
                    self._state = newValue
                }
            }
        }
    }

    /// Operation ID.
    public var id: String = UUID().uuidString

    /// Time at which the operation was queued.
    public var queuedTime = Date(timeIntervalSince1970: 0)

    /// Operation start time.
    public private(set) var startTime = Date(timeIntervalSince1970: 0)

    /// Operation finish time.
    public private(set) var finishTime = Date(timeIntervalSince1970: 0)

    /// Input parameters
    public var input: [String: Any] = [:]

    /// Output parameters.
    public var output: [String: Any] = [:]

    /// Operation error.
    open var error: Error?

    // Indicates whether or not to copy the output from dependencies as
    // input to this operation.
    public var copyDependenciesOutputAsInput: Bool = false

    override open var isReady: Bool {
        return self.state == .ready
    }

    override open var isExecuting: Bool {
        return self.state == .executing
    }

    private var _cancelled = false

    override open var isCancelled: Bool {
        return self.stateLock.withCriticalScope { _cancelled }
    }

    override open var isFinished: Bool {
        return self.state == .finished
    }

    override open var isAsynchronous: Bool {
        return false
    }

    public init(logger: Logger) {
        self.logger = logger
    }

    /// Marks the operation as completed. Subclasses are expected to
    /// call this method whether the operation has completed successfully
    /// or unsuccessfully.
    open func done() {
        guard !self.isFinished else {
            return
        }

        self.finishTime = Date()
        let isExecuting = self.isExecuting

        if isExecuting {
            self.willChangeValue(forKey: Constants.IsExecuting)
        }

        self.willChangeValue(forKey: Constants.IsFinished)
        self.state = .finished
        self.didChangeValue(forKey: Constants.IsFinished)

        if isExecuting {
            self.didChangeValue(forKey: Constants.IsExecuting)
        }

        let elapsed = self.finishTime.timeIntervalSince(self.startTime)
        let queueTime = (self.queuedTime == Date(timeIntervalSince1970: 0) ? 0.0 : self.finishTime.timeIntervalSince(self.queuedTime))
        self.logger.info("\(type(of: self)) (id=\(self.id)) finished in \(elapsed) sec (queueTime: \(queueTime) sec. error: \(String(describing: self.error))")
    }

    /// Evaluates preconditions to determined whether or not the operation should
    /// be started.
    ///
    /// - Returns: `true` if all preconditions have been met.
    open func evaluatePreconditions() -> Bool {
        if !self.dependencies.isEmpty {
            for operation in self.dependencies {
                guard let operation = operation as? ApiOperation, operation.error == nil else {
                    return false
                }
            }
        }

        return true
    }

    /// Executes the operation. Subclasses must override this method.
    open func execute() {
        fatalError("Must override!")
    }

    override open func start() {
        guard !_cancelled else {
            return self.done()
        }

        if self.state == .ready {
            self.startTime = Date()

            if copyDependenciesOutputAsInput {
                // Copy the dependencies' output as input.
                for dependency in self.dependencies {
                    guard let userOp = dependency as? ApiOperation else {
                        break
                    }

                    self.input.merge(userOp.output) {(_, new) in new}
                }
            }

            guard self.evaluatePreconditions() else {
                self.error = ApiOperationError.preconditionFailure
                self.done()
                return
            }

            self.willChangeValue(forKey: Constants.IsExecuting)
            self.state = .executing
            self.didChangeValue(forKey: Constants.IsExecuting)

            self.logger.info("\(type(of: self)) started.")
            self.execute()
        }
    }

    override open func cancel() {
        // By default you cannot cancel an operation that has already begun executing
        // since it requires more care to unwind a job, e.g rollback changes, clean up
        // associated system resources. It's expected for the subclasses to override
        // cancel if they can support a proper cancel during execution. In addition,
        // it makes no sense to cancel already finished operation so in reality we
        // are only allowing ready operation to be cancelled.
        guard self.isReady else {
            return
        }

        self.willChangeValue(forKey: Constants.IsCancelled)
        self.stateLock.withCriticalScope { _cancelled = true }
        self.didChangeValue(forKey: Constants.IsCancelled)
    }

}
