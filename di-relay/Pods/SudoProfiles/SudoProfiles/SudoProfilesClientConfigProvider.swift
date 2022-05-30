//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSAppSync
import AWSCore

/// `AWSAppSyncServiceConfigProvider` implementation that converts Sudo platform
/// configuration to AWS AppSync configuration.
public struct SudoProfilesClientConfigProvider: AWSAppSyncServiceConfigProvider {

    public struct Config {
        // AWS region hosting the Sudo service.
        static let region = "region"
        // API URL.
        static let apiUrl = "apiUrl"
    }

    public let clientDatabasePrefix: String? = nil

    public let endpoint: URL

    public let region: AWSRegionType

    public let authType: AWSAppSyncAuthType = .amazonCognitoUserPools

    public let apiKey: String? = nil

    /// Initializes `SudoProfilesClientConfigProvider` with the API endpoint URL
    /// and AWS region type.
    ///
    /// - Parameters:
    ///   - endpoint: URL for Sudo service API endpoint.
    ///   - region: AWS region.
    public init(endpoint: URL, region: AWSRegionType) {
        self.endpoint = endpoint
        self.region = region
    }

    /// Initializes `SudoProfilesClientConfigProvider` with the API endpoint URL
    /// and AWS region type.
    ///
    /// - Parameter config: Configuration parameters for Sudo service API endpoint.
    public init?(config: [String: Any]) {
        guard let apiUrl = config[Config.apiUrl] as? String,
            let endpoint = URL(string: apiUrl),
            let region = config[Config.region] as? String else {
                return nil
        }

        guard let regionType = AWSEndpoint.regionTypeFrom(name: region) else {
            return nil
        }

        self.init(endpoint: endpoint, region: regionType)
    }

}

extension AWSEndpoint {

    static func regionTypeFrom(name: String) -> AWSRegionType? {
        var regionType: AWSRegionType?
        switch name {
        case "us-east-1":
            // N.Virginia.
            regionType = AWSRegionType.USEast1
        case "us-east-2":
            // Ohio.
            regionType = AWSRegionType.USEast2
        case "us-west-2":
            // Oregon.
            regionType = AWSRegionType.USWest2
        case "eu-central-1":
            // Frankfurt.
            regionType = AWSRegionType.EUCentral1
        case "eu-west-1":
            // Ireland.
            regionType = AWSRegionType.EUWest1
        case "eu-west-2":
            // London.
            regionType = AWSRegionType.EUWest2
        case "ap-southeast-2":
            // Sydney.
            regionType = AWSRegionType.APSoutheast2
        default:
            break
        }

        return regionType
    }

}
