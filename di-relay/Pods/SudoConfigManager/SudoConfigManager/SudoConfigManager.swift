//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging
import AWSCore
import AWSS3

/// Result returned by `validateConfig` API if an incompatible client config is found
/// when compared to the deployed backend services.
public struct ServiceCompatibilityInfo {
    /// Name of the service associated with the compatibility info. This matches one of
    /// the service name present in sudoplatformconfig.json.
    let name: String
    /// Version of the service config present in sudoplatformconfig.json. It defaults
    /// to 1 if not present.
    let configVersion: Int
    /// Minimum supported service config version currently supported by the backend.
    let minSupportedVersion: Int?
    /// Any service config version less than or equal to this version is considered
    /// deprecated and the backend may remove the support for those versions after
    /// a grace period.
    let deprecatedVersion: Int?
    /// After this time any deprecated service config versions will no longer be compatible
    /// with the backend. It is recommended to warn the user prior to the deprecation
    /// grace.
    let deprecationGrace: Date?
}

/// List of errors returned `SudoConfigManger` implementations.
public enum SudoConfigManagerError: Error {
    /// Indicates that a compatibility issue was found against the currently deployed set of
    /// backend services.
    case compatibilityIssueFound(
        // List of incompatible services. The client must be upgraded
        // to the latest version in order to use these services.
        incompatible: [ServiceCompatibilityInfo],
        // List of services that will be made incompatible with the
        // current version of the client. The users should be warned
        // that after the specified grace period these services will
        // be made incompatible.
        deprecated: [ServiceCompatibilityInfo]
    )
    /// Backed service is temporarily unavailable due to network or service availability issues.
    case serviceError(cause: Error)
    /// Indicates that a fatal error occurred. This could be due to coding error, out-of-memory
    /// condition or other conditions that is beyond control of `S3Client` implementation.
    case fatalError(description: String)
}

/// Protocol that encapsulates the APIs common to all configuration manager implementations.
/// A configuration manager is responsible for locating the platform configuration file (sudoplatformconfig.json)
/// in the app bundle, parsing it and returning the configuration set specific to a given namespace.
public protocol SudoConfigManager: AnyObject {

    /// Returns the configuration set under the specified namespace.
    ///
    /// - Parameter namespace: Configuration namespace.
    /// - Returns: Dictionary of configuration parameters or nil if the namespace does not exists.
    func getConfigSet(namespace: String) -> [String: Any]?
    
    /// Validates the client configuration (sudoplatformconfig.json) against the currently deployed set of
    /// backend services. If the client configuration is valid, i.e. the client is compatible will all deployed
    /// backend services, then the call will complete with `success` result. If any part of the client
    /// configuration is incompatible then a detailed information on the incompatible service will be
    /// returned in `failure` result. See `SudoConfigManagerError.compatibilityIssueFound`
    /// for more detail.
    ///
    /// - Returns: Validation result. `success` if all valid and `failure` with the details of incompatible
    ///     or deprecated service configurations if at least one if invalid.
    func validateConfig(completion: @escaping(Swift.Result<Void, Error>) -> Void) throws
    
}

/// Default `SudoConfigManager` implementation.
public class DefaultSudoConfigManager: SudoConfigManager {

    public struct Constants {
        public static let defaultConfigFileName = "sudoplatformconfig"
        public static let defaultConfigFileExtension = "json"
    }

    /// Configuration parameter names.
    public struct Config {

        // Configuration namespace.
        struct Namespace {
            // Identity service related configuration.
            static let identityService = "identityService"
        }

        struct IdentityService {
            // AWS region hosting the identity service.
            static let region = "region"
            // Service info bucket.
            static let serviceInfoBucket = "serviceInfoBucket"
        }

    }
    
    private let logger: Logger
    
    private var s3Client: S3Client? = nil
    
    private var config: [String: Any] = [:]
    
    private let operationQueue = OperationQueue()

    /// Initializes a `DefaultSudoConfigManager` instance.`
    ///
    /// - Parameter logger: Logger used for logging.
    /// - Parameter configFileName: Configuration file name. Defaults to "sudoplatformconfig".
    /// - Parameter configFileExtension: Configuration file extension. Defaults to "json".
    /// - Parameter bundle: Bundle in which to look for the config file.
    /// - Parameter s3Client: S3 client to use for unit testing.
    public init?(logger: Logger? = nil, configFileName: String = Constants.defaultConfigFileName, configFileExtension: String = Constants.defaultConfigFileExtension, bundle: Bundle = Bundle.main, s3Client: S3Client? = nil) {
        self.logger = logger ?? Logger.sudoConfigManagerLogger

        guard let url = bundle.url(forResource: configFileName, withExtension: configFileExtension) else {
            self.logger.error("Configuration file missing.")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            guard let config = data.toJSONObject() as? [String: Any] else {
                self.logger.error("Configuration file was not a valid JSON file.")
                return
            }

            self.config = config

            self.logger.info("Loaded the config: \(config)")
        } catch let error {
            self.logger.error("Cannot read the configuration file: \(error).")
        }
        
        if let identityServiceConfig = self.config[Config.Namespace.identityService] as? [String: Any],
           let region = identityServiceConfig[Config.IdentityService.region] as? String,
           let bucket = identityServiceConfig[Config.IdentityService.serviceInfoBucket] as? String {
            do {
                self.s3Client = try s3Client ?? DefaultS3Client(region: region, bucket: bucket)
            } catch {
                self.logger.error("Failed to initialize S3 client: \(error)")
            }
        }
    }

    public init(logger: Logger? = nil, config: [String: Any], s3Client: S3Client? = nil) {
        self.logger = logger ?? Logger.sudoConfigManagerLogger
        self.config = config
        
        self.logger.info("Loaded the config: \(config)")

        if let identityServiceConfig = self.config[Config.Namespace.identityService] as? [String: Any],
           let region = identityServiceConfig[Config.IdentityService.region] as? String,
           let bucket = identityServiceConfig[Config.IdentityService.serviceInfoBucket] as? String {
            do {
                self.s3Client = try s3Client ?? DefaultS3Client(region: region, bucket: bucket)
            } catch {
                self.logger.error("Failed to initialize S3 client: \(error)")
            }
        }
    }

    public func getConfigSet(namespace: String) -> [String: Any]? {
        return self.config[namespace] as? [String: Any]
    }
    
    public func validateConfig(completion: @escaping(Swift.Result<Void, Error>) -> Void) throws {
        guard let s3Client = self.s3Client else {
            return completion(.success(()))
        }
        
        let listOp = ListJSONS3Objects(s3Client: s3Client)
        listOp.completionBlock = {
            if let error = listOp.error {
                return completion(.failure(error))
            }
            
            // Only fetch the service info docs for the services that are present in client config
            // to minimize the network calls.
            let servicesInfoToFetch = Array(Set(listOp.keys).intersection(Set(self.config.keys.map { "\($0).json"})))
            let getOps = servicesInfoToFetch.map { DownloadJSONS3Object(s3Client: s3Client, key: $0) }
            self.operationQueue.addOperations(getOps, waitUntilFinished: true)
            
            var incompatible: [ServiceCompatibilityInfo] = []
            var deprecated: [ServiceCompatibilityInfo] = []
            
            for getOp in getOps {
                if let error = getOp.error {
                    return completion(.failure(error))
                }
                
                if let serviceName = getOp.jsonObject.keys.first,
                   let serviceInfo = getOp.jsonObject[serviceName] as? [String: Any] {
                    if let serviceConfig = self.config[serviceName] as? [String: Any] {
                        let currentVersion = serviceConfig["version"] as? Int ?? 1
                        let compatibilityInfo = ServiceCompatibilityInfo(
                            name: serviceName,
                            configVersion: currentVersion,
                            minSupportedVersion: serviceInfo["minVersion"] as? Int,
                            deprecatedVersion: serviceInfo["deprecated"] as? Int,
                            deprecationGrace: (serviceInfo["deprecationGrace"] as? Int).map { Date(millisecondsSinceEpoch: Double($0)) }
                        )
                        
                        // If the service config in `sudoplatformconfig.json` is less than the
                        // minimum supported version then the client is incompatible.
                        if currentVersion < (compatibilityInfo.minSupportedVersion ?? 0) {
                            incompatible.append(compatibilityInfo)
                        }
                        
                        // If the service config is less than or equal to the deprecated version
                        // then it will be made incompatible after the deprecation grace.
                        if currentVersion <= (compatibilityInfo.deprecatedVersion ?? 0) {
                            deprecated.append(compatibilityInfo)
                        }
                    }
                }
            }
            
            if(incompatible.isEmpty && deprecated.isEmpty) {
                completion(.success(()))
            } else {
                completion(.failure(SudoConfigManagerError.compatibilityIssueFound(incompatible: incompatible, deprecated: deprecated)))
            }
        }
        self.operationQueue.addOperation(listOp)
    }

}

/// Creates and manages `SudoConfigManager` instances. By default it has 1 `SudoConfigManager`
/// instance named "default" that holds the config loaded from `sudoplatformconfig.json` file located in the app
/// bundle.
public class SudoConfigManagerFactory {

    public struct Constants {
        public static let defaultConfigManagerName = "default"
    }

    public static let instance = SudoConfigManagerFactory()

    private var configManagers: [String: SudoConfigManager] = [:]

    private init() {
        self.configManagers[Constants.defaultConfigManagerName] = DefaultSudoConfigManager()
    }

    /// Registers a new `SudoConfigManager`of the specified name with the provided configuration.
    ///
    /// - Parameters:
    ///   - name: `SudoConfigManager` instance name.
    ///   - config: Configuration to load into the new `SudoConfigManager` instance.
    ///   - logger: Logger to use for the new `SudoConfigManager` instance..
    public func registerConfigManager(name: String, config: [String: Any], logger: Logger? = nil) {
        self.configManagers[name] = DefaultSudoConfigManager(logger: logger, config: config)
    }

    /// Returns the `SudoConfigManager` instance of the specified name.
    ///
    /// - Parameter name: `SudoConfigManager` instance name.
    /// - Returns: `SudoConfigManager` instance or nil if it is not found.
    public func getConfigManager(name: String) -> SudoConfigManager? {
        return self.configManagers[name]
    }

}
