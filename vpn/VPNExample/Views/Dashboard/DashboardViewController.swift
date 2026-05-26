//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import FlagKit
import SudoVPN

@MainActor
class DashboardViewController: UIViewController, SudoVPNSubscriber {

    // MARK: - Outlets

    @IBOutlet var powerButton: UIButton!
    @IBOutlet var connectedStatusLabel: UILabel!
    @IBOutlet var serverInfoBox: ServerInformationBox!
    @IBOutlet var serverChangeBox: ServerChangeBox!
    @IBOutlet var learnMoreButton: UIButton!

    // MARK: - Supplementary

    enum Segue: String, Segueable {
        case navigateToServerList
        case navigateToSettings
    }

    typealias PowerButtonColors = (background: UIColor, tint: UIColor, border: UIColor)

    // MARK: - Properties

    private(set) var server: SudoVPNServer?

    nonisolated(unsafe) static var lastViewedServer: SudoVPNServer?

    var vpnClient = AppDelegate.dependencies.vpnClient

    let subscriberId = UUID().uuidString

    var updateViewTask: Task<Void, Never>?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configurePowerButton()
        configureServerInfoBox()
        configureServerChangeBox()
        Task {
            try? await vpnClient.prepare()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task {
            await vpnClient.subscribe(id: subscriberId, subscriber: self)
            let state = await vpnClient.state
            updateConnectionState(state)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Task {
            await vpnClient.unsubscribe(id: subscriberId)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        powerButton.layer.cornerRadius = powerButton.frame.width / 2
    }

    // MARK: - Actions

    @IBAction func connectButtonTapped() {
        Task {
            let state = await vpnClient.state
            switch state {
            case .disconnecting, .disconnected:
                await connect()

            case .connected, .connecting, .reconnecting:
                await disconnect()
            }
        }
    }

    @IBAction func serverChangeBoxTapped() {
        navigateToServerList()
    }

    @IBAction func learnMoreTapped() {
        guard let docURL = URL(string: "https://docs.sudoplatform.com/guides/virtual-private-network/manage-servers") else {
            return
        }
        UIApplication.shared.open(docURL, options: [:], completionHandler: nil)
    }

    /// Action associated with returning to this view from a segue.
    @IBAction func returnToDashboard(segue: UIStoryboardSegue) {
        updateView()
    }

    @IBAction func didTapSettings() {
        performSegue(withSegue: Segue.navigateToSettings, sender: self)
    }

    // MARK: - Helpers: Configuration

    func configureNavigationBar() {
        let settingsBarButton = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(didTapSettings))
        navigationItem.rightBarButtonItem = settingsBarButton
    }

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
    }

    // MARK: Helpers: Navigation

    func navigateToServerList() {
        performSegue(withSegue: Segue.navigateToServerList, sender: self)
    }

    // MARK: Helpers

    func connect() async {
        do {
            try await vpnClient.connect()
        } catch SudoVPNError.cancelled {
            // no-op
        } catch {
            presentErrorAlert(message: "Failed to connect", error: error)
        }
    }

    func disconnect() async {
        do {
            try await vpnClient.disconnect(isUserInitiated: true)
        } catch SudoVPNError.cancelled {
            // no-op
        } catch {
            presentErrorAlert(message: "Failed to disconnect", error: error)
        }
    }

    func updateConnectionState(_ state: SudoVPNState) {
        updateLabelState(state)
        updateButtonState(state)
        updateView()
    }

    func updateLabelState(_ state: SudoVPNState) {
        connectedStatusLabel.text = switch state {
        case .connecting:
            "Connecting"
        case .connected:
            "Connected"
        case .disconnecting:
            "Disconnecting"
        case .disconnected:
            "Disconnected"
        case .reconnecting:
            "Reconnecting"
        }
    }

    func updateButtonState(_ state: SudoVPNState) {
        switch state {
        case .disconnected:
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

    func updateView() {
        updateViewTask?.cancel()
        updateViewTask = Task {
            let state = await vpnClient.state
            let configuration = await vpnClient.configuration
            let isReady = await vpnClient.isReady
            let connectedDate = await vpnClient.connectedDate
            let ipAddress = await fetchPublicIPAddress()
            guard !Task.isCancelled else {
                return
            }
            serverInfoBox.displayModel = .init(server: configuration?.server, publicIpAddress: ipAddress, dateConnected: connectedDate)
            serverChangeBox.displayModel = .init(server: configuration?.server, state: state, isLoading: !isReady)
        }
    }

    func fetchPublicIPAddress() async -> String? {
        guard
            let url = URL(string: "https://api.ipify.org"),
            let (data, response) = try? await URLSession.shared.data(from: url),
            let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200,
            let publicIpAddress = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return publicIpAddress
    }

    // MARK: - SudoVPNObserving

    func vpnStateDidChange(_ state: SudoVPNState) {
        updateConnectionState(state)
    }

    func vpnConfigurationDidChange(_ configuration: SudoVPNConfiguration?) {
        updateView()
    }
}
