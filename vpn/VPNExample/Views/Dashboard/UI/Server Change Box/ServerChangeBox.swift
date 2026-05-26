//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoVPN

class ServerChangeBox: UIView {

    // MARK: - Supplementary

    struct DisplayModel: Equatable {

        /// The currently selected server.  If `nil`, the fastest available server will be used.
        let server: SudoVPNServer?

        /// The current VPN connection status.
        let state: SudoVPNState

        /// Whether the server information is currently loading.
        let isLoading: Bool
    }

    // MARK: - Outlets

    @IBOutlet var flagImageView: UIImageView!

    @IBOutlet var countryLabel: UILabel!

    @IBOutlet var disclosureIndicator: UIImageView!

    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    // MARK: - Properties

    var displayModel: DisplayModel? {
        didSet {
            if displayModel?.isLoading == true {
                flagImageView.isHidden = true
                countryLabel.isHidden = true
                disclosureIndicator.isHidden = true
                activityIndicator.startAnimating()
                isUserInteractionEnabled = false
                return
            }
            activityIndicator.stopAnimating()
            flagImageView.isHidden = false
            countryLabel.isHidden = false

            let isEnabled = displayModel?.state == .disconnected
            disclosureIndicator.isHidden = !isEnabled
            isUserInteractionEnabled = isEnabled

            let serverModel: ServerModel? = if let server = displayModel?.server {
                ServerModel(vpnServer: server)
            } else {
                nil
            }
            if let serverModel, serverModel.country != Constants.FastestAvailableName {
                flagImageView.image = serverModel.flag?.image(style: .roundedRect)
                countryLabel.text = serverModel.region
            } else {
                flagImageView.image = UIImage(systemName: Constants.FastestAvailableIconName)
                countryLabel.text = Constants.FastestAvailableName
            }
        }
    }

    // MARK: - Lifecycle

    override func awakeAfter(using aDecoder: NSCoder) -> Any? {
        if subviews.isEmpty {
            let view: Self = .fromNib()
            view.backgroundColor = backgroundColor
            view.frame = frame
            view.translatesAutoresizingMaskIntoConstraints = false
            view.displayModel = nil
            return view
        }
        return super.awakeAfter(using: aDecoder)
    }
}
