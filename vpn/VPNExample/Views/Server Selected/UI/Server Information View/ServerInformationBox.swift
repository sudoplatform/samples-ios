//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoVPN

class ServerInformationBox: UIView {

    // MARK: - Outlets

    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var regionLabel: UILabel!
    @IBOutlet var loadLabel: UILabel!
    @IBOutlet var ipAddressLabel: UILabel!

    // MARK: - Properties

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

    var uptimeTimer: Timer?

    var dateConnected: Date? {
        didSet {
            guard dateConnected != nil else {
                uptimeTimer?.invalidate()
                uptimeTimer = nil
                updateViewWithTimeConnected(0)
                return
            }
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                guard let dateConnected = self.dateConnected else {
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

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    // MARK: - Methods

    private func updateViewWithServer(_ server: ServerModel?) {
        guard let server = server else {
            setDefaultView()
            return
        }
        regionLabel.text = server.region ?? "Unknown"
        ipAddressLabel.text = server.ipAddress ?? "??"
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
        ipAddressLabel.text = "??"
    }

}
