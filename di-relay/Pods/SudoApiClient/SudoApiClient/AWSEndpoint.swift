//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore

public extension AWSEndpoint {

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
