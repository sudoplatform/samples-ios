//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging

/// Protocol that encapsulates the APIs common to all configuration manager implementations.
/// A configuration manager is responsible for locating the platform configuration file (sudoplatformconfig.json)
/// in the app bundle, parsing it and returning the configuration set specific to a given namespace.
public protocol SudoConfigManager: class {

    /// Returns the configuration set under the specified namespace.
    ///
    /// - Parameter namespace: Configuration namespace.
    /// - Returns: Dictionary of configuration parameters or nil if the namespace does not exists.
    func getConfigSet(namespace: String) -> [String: Any]?

}

/// Default `SudoConfigManager` implementation.
public class DefaultSudoConfigManager: SudoConfigManager {

    public struct Constants {
        public static let defaultConfigFileName = "sudoplatformconfig"
        public static let defaultConfigFileExtension = "json"
    }

    private let logger: Logger

    private var config: [String: Any] = [:]

    /// Initializes a `DefaultSudoConfigManager` instance.`
    ///
    /// - Parameter logger: Logger used for logging.
    /// - Parameter configFileName: Configuration file name. Defaults to "sudoplatformconfig".
    /// - Parameter configFileExtension: Configuration file extension. Defaults to "json".
    public init?(logger: Logger? = nil, configFileName: String = Constants.defaultConfigFileName, configFileExtension: String = Constants.defaultConfigFileExtension) {
        self.logger = logger ?? Logger.sudoConfigManagerLogger

        guard let url = Bundle.main.url(forResource: configFileName, withExtension: configFileExtension) else {
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
    }

    public init(logger: Logger? = nil, config: [String: Any]) {
        self.logger = logger ?? Logger.sudoConfigManagerLogger
        self.config = config

        self.logger.info("Loaded the config: \(config)")
    }

    public func getConfigSet(namespace: String) -> [String: Any]? {
        return self.config[namespace] as? [String: Any]
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
