//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import FlagKit
import SudoVPN

class ServerSelectedViewController: UIViewController, SudoVPNObserving {

    // MARK: - Outlets
    @IBOutlet var powerButton: UIButton!
    @IBOutlet var connectedStatusLabel: UILabel!
    @IBOutlet var serverInfoBox: ServerInformationBox!
    @IBOutlet var serverChangeBox: ServerChangeBox!
    @IBOutlet var learnMoreButton: UIButton!

    // MARK: - Supplementary

    enum Segue: String, Segueable {
        case returnToServerList
    }

    typealias PowerButtonColors = (background: UIColor, tint: UIColor, border: UIColor)

    // MARK: - Properties

    private(set) var server: SudoVPNServer?

    static var lastViewedServer: SudoVPNServer?

    var currentProtocol: SudoVPNProtocol {
        guard
            let data = UserDefaults.standard.data(forKey: "currentProtocol"),
            let userSetting = try? JSONDecoder().decode(SudoVPNProtocol.self, from: data)
        else {
            return self.vpnClient.defaultProtocol
        }
        return userSetting
    }

    var currentOnDemand: Bool {
        get {
            guard
                let data = UserDefaults.standard.data(forKey: "currentOnDemand"),
                let userSetting = try? JSONDecoder().decode(Bool.self, from: data)
            else {
                return false
            }
            return userSetting
        }
        set {
            guard let encodedData = try? JSONEncoder().encode(newValue) else {
                NSLog("Failed to set on demand flag")
                return
            }
            UserDefaults.standard.setValue(encodedData, forKey: "currentOnDemand")
        }
    }

    var vpnClient = AppDelegate.dependencies.vpnClient

    override func viewDidLoad() {
        super.viewDidLoad()
        configurePowerButton()
        configureServerInfoBox()
        configureServerChangeBox()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.vpnClient.addObserver(self)
        updateView()
        updateConnectionState(vpnClient.state)
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.vpnClient.removeObserver(self)
        super.viewWillDisappear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        powerButton.layer.cornerRadius = powerButton.frame.width / 2
    }

    // MARK: - Actions

    @IBAction func connectButtonTapped() {
        switch vpnClient.state {
        case .error, .disconnecting, .disconnected:
            Task.detached(priority: .medium) { [weak self] in
                guard let weakSelf = self else { return }
                await weakSelf.updateConnectionState(.connecting)
                // Set the SudoVPNConfiguration server as 'nil' if fastest available selected.
                // The configuration object required in `vpnClient.connect()`` requires a nil
                // server to auto-detect user location.
                let server = await weakSelf.server?.country == Constants.FastestAvailableName ? nil : weakSelf.server
                let configuration = await SudoVPNConfiguration(
                    server: server,
                    protocolType: weakSelf.currentProtocol,
                    onDemand: weakSelf.currentOnDemand
                )
                do {
                    try await weakSelf.vpnClient.connect(withConfiguration: configuration)
                } catch {
                    await weakSelf.presentErrorAlert(message: "Failed to connect", error: error)
                }
            }
        case .connected, .connecting, .reconnecting:
            Task.detached(priority: .medium) { [weak self] in
                guard let weakSelf = self else { return }
                await weakSelf.updateConnectionState(.disconnecting)
                do {
                    try await weakSelf.vpnClient.disconnect(isUserInitiated: true)
                } catch {
                    await weakSelf.presentErrorAlert(message: "Failed to disconnect", error: error)
                }
            }
            // If we are explicitly disconnecting then we should set onDemand to false to
            // maintain consistent behaviour with the SDK
            self.currentOnDemand = false
        }
    }

    @IBAction func serverChangeBoxTapped() {
        returnToServerList()
    }

    @IBAction func learnMoreTapped() {
        guard let docURL = URL(string: "https://docs.sudoplatform.com/guides/virtual-private-network/manage-servers") else {
            return
        }
        UIApplication.shared.open(docURL, options: [:], completionHandler: nil)
    }

    // MARK: - Setters

    func setServer(_ server: SudoVPNServer) async {
        switch vpnClient.state {
        case .connecting, .connected, .reconnecting:
            do {
                try await vpnClient.disconnect(isUserInitiated: false)
                self.currentOnDemand = false
                self.server = server
            } catch {
                // Do nothing.
            }
        default:
            self.server = server
        }
    }

    // MARK: - Helpers: Configuration

    func configurePowerButton() {
        powerButton.backgroundColor = .white
        powerButton.translatesAutoresizingMaskIntoConstraints = false
        powerButton.layer.cornerRadius = powerButton.frame.width / 2
        powerButton.clipsToBounds = true
        let imageView = UIImageView(image: UIImage(systemName: "power"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        powerButton.addSubview(imageView)
        powerButton.layer.borderWidth = 1
        powerButton.layer.borderColor = UIColor.link.cgColor
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100),
            NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100),
            NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: powerButton, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: imageView, attribute: .centerY, relatedBy: .equal, toItem: powerButton, attribute: .centerY, multiplier: 1, constant: 0)
        ])
    }

    func configureServerInfoBox() {
        serverInfoBox.backgroundColor = .systemGray6
        serverInfoBox.layer.borderColor = UIColor.lightGray.cgColor
        serverInfoBox.layer.borderWidth = 1
    }

    func configureServerChangeBox() {
        serverChangeBox.layer.borderColor = UIColor.lightGray.cgColor
        serverChangeBox.layer.borderWidth = 1
        serverChangeBox.backgroundColor = .systemBackground
        serverChangeBox.isUserInteractionEnabled = true
    }

    // MARK: Helpers: Navigation

    func returnToServerList() {
        performSegue(withSegue: Segue.returnToServerList, sender: self)
    }

    // MARK: Helpers

    func updateConnectionState(_ state: SudoVPNState) {
        switch state {
        case .connecting:
            setStateConnecting()
        case .connected:
            setStateConnected()
        case .disconnecting:
            setStateDisconnecting()
        case .disconnected:
            setStateDisconnected()
        case .reconnecting:
            setStateReconnecting()
        case .error:
            setStateError()
        }
        setButtonForState(state)
        updateView()
    }

    func setStateConnecting() {
        connectedStatusLabel.text = "Connecting"
    }

    func setStateConnected() {
        connectedStatusLabel.text = "Connected"
    }

    func setStateDisconnecting() {
        connectedStatusLabel.text = "Disconnecting"
    }

    func setStateDisconnected() {
        connectedStatusLabel.text = "Disconnected"
    }

    func setStateReconnecting() {
        connectedStatusLabel.text = "Reconnecting"
    }

    func setStateError() {
        connectedStatusLabel.text = "Disconnected"
    }

    func setButtonForState(_ state: SudoVPNState) {
        switch state {
        case .error, .disconnected:
            UIView.animate(withDuration: 0.2) {
                self.powerButton.backgroundColor = .white
                self.powerButton.tintColor = .link
            }
        case .disconnecting, .connecting, .reconnecting:
            UIView.animate(withDuration: 0.2) {
                self.powerButton.backgroundColor = .lightGray
                self.powerButton.tintColor = .darkGray
            }
        case .connected:
            UIView.animate(withDuration: 0.2) {
                self.powerButton.backgroundColor = .link
                self.powerButton.tintColor = .white
            }
        }
    }

    private func updateView() {
        serverInfoBox.dateConnected = vpnClient.connectedDate
        let server = vpnClient.configuration?.server ?? self.server
        serverChangeBox.server = server
        serverInfoBox.server = server
    }

    private func setConnectedStatusLabelConnected(_ isConnected: Bool) {
        connectedStatusLabel.text = isConnected ? "Connected" : "Disconnected"
    }

    // MARK: - SudoVPNObserving

    func connectionDidBegin() {
        updateConnectionState(.connecting)
    }

    func connectionSucceeded() {
        updateConnectionState(.connected)
    }

    func connectionWillDisconnect() {
        updateConnectionState(.disconnecting)
    }

    func connectionDidDisconnect() {
        updateConnectionState(.disconnected)
    }

    func connectionWillReconnect() {
        updateConnectionState(.reconnecting)
    }

    func connectionFailed(withError error: Error) {
        updateConnectionState(.error(error.localizedDescription))
    }

    func serverDidChange(_ server: SudoVPNServer) {
        updateView()
    }
}
