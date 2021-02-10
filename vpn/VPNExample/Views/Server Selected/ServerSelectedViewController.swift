//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
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
            // TODO: Return default from VPN Client
            return .ikev2
        }
        return userSetting
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
            updateConnectionState(.connecting)
            let configuration = SudoVPNConfiguration(server: server, protocolType: currentProtocol)
            vpnClient.connect(withConfiguration: configuration) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if case .failure(let error) = result {
                        self.presentErrorAlert(message: "Failed to connect", error: error)
                    }
                }
            }
        case .connected, .connecting, .reconnecting:
            updateConnectionState(.disconnecting)
            vpnClient.disconnect(isUserInitiated: true) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if case .failure(let error) = result {
                        self.presentErrorAlert(message: "Failed to disconnect", error: error)
                    }
                }
            }
        }
    }

    @IBAction func serverChangeBoxTapped() {
        returnToServerList()
    }

    // MARK: - Setters

    func setServer(_ server: SudoVPNServer) {
        switch vpnClient.state {
        case .connecting, .connected, .reconnecting:
            vpnClient.disconnect(isUserInitiated: false) { [weak self] _ in
                self?.server = server
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
