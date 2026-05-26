//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoVPN

class ServerInformationBox: UIView {

    // MARK: - Supplementary

    struct DisplayModel: Equatable {

        /// The currently selected server.  If `nil`, the fastest available server will be used.
        let server: SudoVPNServer?

        /// The current public IP address of the local user.
        let publicIpAddress: String?

        /// The timestamp when the VPN connected.
        let dateConnected: Date?
    }

    // MARK: - Outlets

    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var regionLabel: UILabel!
    @IBOutlet var loadLabel: UILabel!
    @IBOutlet var serverIpAddressLabel: UILabel!
    @IBOutlet var publicIpAddressLabel: UILabel!

    // MARK: - Properties

    var displayModel: DisplayModel? {
        didSet {
            // Update server info
            if let server = displayModel?.server {
                let model = ServerModel(vpnServer: server)
                updateViewWithServer(model)
            } else {
                updateViewWithServer(nil)
            }
            publicIpAddressLabel.text = displayModel?.publicIpAddress ?? "??"

            // Update connected timestamp info
            guard displayModel?.dateConnected != nil else {
                uptimeTimer?.invalidate()
                uptimeTimer = nil
                updateViewWithTimeConnected(0)
                return
            }
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                guard let dateConnected = self.displayModel?.dateConnected else {
                    self.uptimeTimer?.invalidate()
                    self.updateViewWithTimeConnected(0)
                    self.uptimeTimer = nil
                    return
                }
                let difference = Int(Date().timeIntervalSince(dateConnected))
                self.updateViewWithTimeConnected(difference)
            }
        }
    }

    var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }

    var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }

    var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }

    var uptimeTimer: Timer?

    // MARK: - Lifecycle

    override func awakeAfter(using aDecoder: NSCoder) -> Any? {
        if subviews.isEmpty {
            let view: ServerInformationBox = .fromNib()
            view.backgroundColor = backgroundColor
            view.frame = frame
            view.translatesAutoresizingMaskIntoConstraints = false
            view.setDefaultView()
            return view
        }
        return super.awakeAfter(using: aDecoder)
    }

    // MARK: - Methods

    private func updateViewWithServer(_ server: ServerModel?) {
        guard let server else {
            setDefaultView()
            return
        }
        regionLabel.text = server.region ?? "Unknown"
        serverIpAddressLabel.text = server.ipAddress ?? "??"
        if let load = server.load {
            loadLabel.text = "\(load)%"
        } else {
            loadLabel.text = "?? %"
        }
    }

    private func updateViewWithTimeConnected(_ timeConnected: Int) {
        guard timeConnected >= 0 else {
            timeLabel.text = "-:-:-"
            return
        }
        let hourComponent = Int(floor(Double(timeConnected) / 3600.0))
        let minuteModulo = timeConnected % 3600
        let minuteComponent = Int(floor(Double(minuteModulo) / 60 ))
        let secondComponent = minuteModulo % 60
        let format = "\(hourComponent):\(String(format: "%02d", minuteComponent)):\(String(format: "%02d", secondComponent))"
        timeLabel.text = format
    }

    private func setDefaultView() {
        timeLabel.text = "0:00:00"
        regionLabel.text = "Unknown"
        loadLabel.text = "?? %"
        serverIpAddressLabel.text = "??"
        publicIpAddressLabel.text = "??"
    }
}
