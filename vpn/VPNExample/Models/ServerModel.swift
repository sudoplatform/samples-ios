//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import FlagKit
import SudoVPN

struct ServerModel {

    // MARK: - Properties

    var country: String
    var flag: Flag?
    var coordinates: SudoVPNCoordinates?
    var region: String?
    var load: Int?
    var ipAddress: String?

    // MARK: - Lifecycle

    init(vpnServer: SudoVPNServer) {
        if let localizedString = Locale.current.localizedString(forRegionCode: vpnServer.country) {
            country = localizedString
        } else {
            country = vpnServer.country
        }
        // Handle UK transformation
        if vpnServer.country.uppercased() == "UK" {
            self.flag = Flag(countryCode: "GB")
        } else if let flag = Flag(countryCode: vpnServer.country.uppercased()) {
            self.flag = flag
        }
        self.coordinates = vpnServer.coordinates
        self.region = vpnServer.region
        self.load = vpnServer.load
        self.ipAddress = vpnServer.ipAddress
    }
}
