//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit
import SudoTelephony
import AVFoundation

class ActiveVoiceCallViewController: UITableViewController {
    var callParameters: (localNumber: PhoneNumber, remoteNumber: String)!

    enum State {
        case initial
        case initiating
        case active(ActiveVoiceCall)
        case disconnected
    }
    private var state: State = .initial

    @IBOutlet weak var callStatusLabel: UILabel!
    @IBOutlet weak var localNumberLabel: UILabel!
    @IBOutlet weak var remoteNumberLabel: UILabel!
    @IBOutlet weak var callDurationLabel: UILabel!
    @IBOutlet weak var barButtonItem: UIBarButtonItem!

    @IBOutlet weak var muteSwitch: UISwitch!
    @IBOutlet weak var speakerSwitch: UISwitch!

    private var callDuration: TimeInterval = 0
    private var durationTickTimer: Timer!
    private let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    private var notificationCenterToken: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        callStatusLabel.text = "Initiating"
        callStatusLabel.textColor = .label
        localNumberLabel.text = callParameters.localNumber.phoneNumber
        remoteNumberLabel.text = callParameters.remoteNumber
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if case .initial = state {
            initiateCall()
        }

        // Observe audio route changes and update the speakerphone switch
        notificationCenterToken = NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: OperationQueue.main) { [weak self] (note) in
            guard let self = self else { return }

            let currentOutputs = AVAudioSession.sharedInstance().currentRoute.outputs
            let isSpeakerOn = currentOutputs.filter { $0.portType == AVAudioSession.Port.builtInSpeaker }.count > 0
            self.speakerSwitch.isOn = isSpeakerOn
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let token = notificationCenterToken {
            NotificationCenter.default.removeObserver(token)
        }
    }

    // MARK: Initiate Call

    private func initiateCall() {
        state = .initiating

        // We want to disable the end call button to prevent this view controller from being dismissed while the call is connecting.
        // Since this is the delegate when the call is connected, it won't get the callback and will have no way of ending the call
        // once it connects.
        self.barButtonItem.isEnabled = false

        let telephonyClient = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!

        try! telephonyClient.createVoiceCall(localNumber: callParameters.localNumber, remoteNumber: callParameters.remoteNumber, delegate: self)
    }

    private func handleActiveCall(_ call: ActiveVoiceCall) {
        self.barButtonItem.isEnabled = true
        callStatusLabel.text = "Active"
        callStatusLabel.textColor = .systemGreen
        localNumberLabel.text = call.localPhoneNumber
        remoteNumberLabel.text = call.remotePhoneNumber

        muteSwitch.setOn(call.isMuted, animated: true)

        callDuration = 0
        durationTickTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateDuration), userInfo: nil, repeats: true)

        state = .active(call)
        tableView.reloadData()
    }

    @objc private func updateDuration() {
        callDuration += 1
        if callDuration >= 3600 {
            durationFormatter.allowedUnits = [.hour, .minute, .second]
        }
        callDurationLabel.text = durationFormatter.string(from: callDuration)
    }

    // MARK: Disconnect Call

    @IBAction func endCallTapped(_ sender: UIBarButtonItem) {
        guard case .active(let call) = state else {
            dismiss(animated: true, completion: nil)
            return
        }

        // Disconnect the call.
        call.disconnect { result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self.presentErrorAlert(message: "Failed to disconnect call", error: error)
                }
            case .success: break
            }
        }
    }

    /// Updates the UI to reflect the call disconnecting.
    private func callDisconnected() {
        state = .disconnected
        durationTickTimer.invalidate()
        callStatusLabel.text = "Ended"
        callStatusLabel.textColor = .label
        barButtonItem.title = "Done"
        tableView.reloadData()
    }

    // MARK: Call Controls

    @IBAction func muteSwitchChanged(_ sender: UISwitch) {
        guard case .active(let call) = state else {
            return
        }

        call.setMuted(sender.isOn)
    }

    @IBAction func speakerSwitchChanged(_ sender: UISwitch) {
        guard case .active(let call) = state else {
            return
        }
        call.setAudioOutput(toSpeaker: sender.isOn)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Hide the call controls when the call is not active.
        switch state {
        case .active:
            return 2
        default:
            return 1
        }

    }
}

extension ActiveVoiceCallViewController: ActiveCallDelegate {

    /// Notifies the delegate that the call has connected
    /// - Parameters:
    ///     - call: The `ActiveVoiceCall`
    func activeVoiceCallDidConnect(_ call: ActiveVoiceCall) {
        self.handleActiveCall(call)
    }

    /// Notifies the delegate that the call failed to connect
    /// - Parameters:
    ///     - error: `CallingError` that occurred.
    func activeVoiceCallDidFailToConnect(withError error: CallingError) {
        self.callStatusLabel.text = "Failed"
        self.callStatusLabel.textColor = .systemRed
        self.presentErrorAlert(message: "Failed to initiate call", error: error)
    }

    /// Notifies the delegate that the call has been disconnected
    /// - Parameters:
    ///     - call: The `ActiveVoiceCall`
    ///     - error: Error that caused the call to disconnect if one occurred.
    func activeVoiceCall(_ call: ActiveVoiceCall, didDisconnectWithError error: Error?) {
        self.callDisconnected()
    }

    /// Notifies the delegate that the call has been disconnected
    /// - Parameters:
    ///     - call: The `ActiveVoiceCall`
    ///     - isMuted: Whether outgoing call audio is muted
    func activeVoiceCall(_ call: ActiveVoiceCall, didChangeMuteState isMuted: Bool) {
        self.muteSwitch.setOn(isMuted, animated: true)
    }
}
