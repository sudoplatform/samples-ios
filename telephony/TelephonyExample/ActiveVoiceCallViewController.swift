//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit
import SudoTelephony
import AVFoundation
import AVKit

class ActiveVoiceCallViewController: UITableViewController {

    typealias OutgoingCallParameters = (localNumber: PhoneNumber, remoteNumber: String)

    enum State {
        case outgoing(OutgoingCallParameters)
        case initiating
        case active(ActiveVoiceCall)
        case disconnected
    }

    private var state: State!

    @IBOutlet weak var callStatusLabel: UILabel!
    @IBOutlet weak var localNumberLabel: UILabel!
    @IBOutlet weak var remoteNumberLabel: UILabel!
    @IBOutlet weak var callDurationLabel: UILabel!
    @IBOutlet weak var barButtonItem: UIBarButtonItem!

    @IBOutlet weak var muteSwitch: UISwitch!
    @IBOutlet weak var speakerSwitch: UISwitch!

    private var callDuration: TimeInterval = 0
    private var durationTickTimer: Timer?
    private let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    // Use the OS route picker as a bar button item to allow the audio route to be easily selected.
    lazy var routePickerButton: UIBarButtonItem = {
        let pickerview = AVRoutePickerView(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0))
        return UIBarButtonItem(customView: pickerview)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        callStatusLabel.textColor = .label
        self.navigationItem.leftBarButtonItem = self.routePickerButton
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if case .outgoing(let parameters) = state {
            callStatusLabel.text = "Initiating"
            localNumberLabel.text = parameters.localNumber.phoneNumber
            remoteNumberLabel.text = parameters.remoteNumber
            initiateCallWith(parameters)
        }
        else if case .active(let call) = state {
            callStatusLabel.text = "Connecting"
            localNumberLabel.text = call.localPhoneNumber
            remoteNumberLabel.text = call.remotePhoneNumber
            self.handleActiveCall(call)
        }
    }

    // Start with an active call
    func startWithActive(call: ActiveVoiceCall) {
        self.state = .active(call)
    }

    // Start with an outgoing call
    func startWithOutgoingCall(parameters: OutgoingCallParameters) {
        self.state = .outgoing(parameters)
    }

    // MARK: Initiate Call

    private func initiateCallWith(_ parameters: OutgoingCallParameters) {
        state = .initiating

        // We want to disable the end call button to prevent this view controller from being dismissed while the call is connecting.
        // Since this is the delegate when the call is connected, it won't get the callback and will have no way of ending the call
        // once it connects.
        self.barButtonItem.isEnabled = false

        let telephonyClient = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!

        try! telephonyClient.createVoiceCall(localNumber: parameters.localNumber, remoteNumber: parameters.remoteNumber, delegate: self)
    }

    private func handleActiveCall(_ call: ActiveVoiceCall) {
        self.barButtonItem.isEnabled = true
        callStatusLabel.text = "Active"
        callStatusLabel.textColor = .systemGreen
        localNumberLabel.text = call.localPhoneNumber
        remoteNumberLabel.text = call.remotePhoneNumber

        muteSwitch.setOn(call.isMuted, animated: true)

        callDuration = 0
        durationTickTimer?.invalidate()
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
        durationTickTimer?.invalidate()
        durationTickTimer = nil
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
        DispatchQueue.main.async {
            self.callStatusLabel.text = "Failed"
            self.callStatusLabel.textColor = .systemRed
            self.presentErrorAlert(message: "Failed to initiate call", error: error)
            self.barButtonItem.isEnabled = true
        }
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

    func activeVoiceCallAudioRouteDidChange(_ call: ActiveVoiceCall) {
        self.speakerSwitch.isOn = call.isOnSpeaker
    }
}
