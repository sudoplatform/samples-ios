//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoVPN

class ServerChangeBox: UIView {

    // MARK: - Outlets

    @IBOutlet var flagImageView: UIImageView!
    @IBOutlet var countryLabel: UILabel!

    // MARK: - Properties

    var server: SudoVPNServer? {
        didSet {
            if let server = server {
                let model = ServerModel(vpnServer: server)
                updateViewWithServer(model)
            } else {
                updateViewWithServer(nil)
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
            view.setDefaultView()
            return view
        }
        return super.awakeAfter(using: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    // MARK: - Methods

    private func updateViewWithServer(_ server: ServerModel?) {
        guard let server = server else {
            setDefaultView()
            return
        }
        flagImageView.image = server.flag?.image(style: .roundedRect)
        countryLabel.text = server.country
    }

    private func setDefaultView() {
        flagImageView.image = UIImage(systemName: "questionmark")
        countryLabel.text = "Unknown"
    }

}
