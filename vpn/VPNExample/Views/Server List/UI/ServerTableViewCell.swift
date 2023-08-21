//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoVPN
import FlagKit

class ServerTableViewCell: UITableViewCell {

    // MARK: - Supplementary

    struct Country {
        var name: String
        var image: UIImage?

        init(regionCode: String) {
            if let localizedString = Locale.current.localizedString(forRegionCode: regionCode) {
                name = localizedString
            } else {
                name = regionCode
            }
            if let flag = Flag(countryCode: regionCode.uppercased()) {
                image = flag.image(style: .roundedRect)
            }
        }
    }

    // MARK: - Outlets

    @IBOutlet var countryImageView: UIImageView!
    @IBOutlet var regionLabel: UILabel!
    @IBOutlet var loadLabel: UILabel!

    // MARK: - Methods

    func setServer(_ server: SudoVPNServer) {
        let model = ServerModel(vpnServer: server)
        if let countryImage = model.flag?.image(style: .roundedRect) {
            countryImageView.image = countryImage
        } else {
            countryImageView.image = UIImage(systemName: "eye")
        }
        regionLabel.text = model.region ?? model.country
        if let load = model.load {
            loadLabel.text = "\(load)%"
        } else {
            loadLabel.text = nil
        }
    }

}
