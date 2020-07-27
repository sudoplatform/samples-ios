//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoTelephony
import AVFoundation

class VoicemailViewController: UITableViewController, AVAudioPlayerDelegate {

    // This view controller can display voicemail data from either
    // an independent voicemail record or a call record.
    // We define helper accessors to retrieve data from either struct.
    var voicemail: Voicemail?
    var callRecord: CallRecord?

    var voicemailId: String { return (voicemail?.id ?? callRecord?.voicemail?.id)! }
    var voicemailMedia: MediaObject {
        return (voicemail?.media ?? callRecord?.voicemail?.media)!
    }
    var voicemailDate: Date { return (voicemail?.created ?? callRecord?.updated)! }
    var localPhoneNumber: String {
        return (voicemail?.localPhoneNumber ?? callRecord?.localPhoneNumber)!
    }
    var remotePhoneNumber: String {
        return (voicemail?.remotePhoneNumber ?? callRecord?.remotePhoneNumber)!
    }
    var voicemailDurationSeconds: UInt {
        return (voicemail?.durationSeconds ?? callRecord?.voicemail?.durationSeconds)!
    }

    var audioPlayer: AVAudioPlayer?

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var yourNumberLabel: UILabel!
    @IBOutlet weak var remoteNumberLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var playLabel: UILabel!
    @IBOutlet weak var speakerLabel: UILabel!

    var playing: Bool = false
    var speakerOn: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        timeLabel.text = DateFormatter.localizedString(from: voicemailDate, dateStyle: .short, timeStyle: .short)
        yourNumberLabel.text = formatAsUSNumber(number: localPhoneNumber)
        remoteNumberLabel.text = formatAsUSNumber(number: remotePhoneNumber)

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        durationLabel.text = formatter.string(from: TimeInterval(voicemailDurationSeconds))!
    }

    @IBAction func deleteTapped(_ sender: Any) {
        self.presentActivityAlert(message: "Deleting voicemail")

        let telephonyClient = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!
        telephonyClient.deleteVoicemail(id: voicemailId) { result in
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    switch result {
                    case .success:
                        self.navigationController?.popViewController(animated: true)
                    case .failure(let error):
                        self.presentErrorAlert(message: "Failed to delete voicemail", error: error)
                    }
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        switch indexPath.row {
        case 4,5: return true
        default: return false
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 4: togglePlaying()
        case 5: setSpeakerOn(!speakerOn)
        default: break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func setSpeakerOn(_ on: Bool) {
        speakerOn = on
        let session = AVAudioSession.sharedInstance()
        try? session.overrideOutputAudioPort(on ? .speaker : .none)
        try? session.setCategory(on ? .playback : .playAndRecord,
                                 options: on ? .defaultToSpeaker : [])
        speakerLabel.text = on ? "Speaker On" : "Speaker Off"
    }

    func togglePlaying() {
        guard let player = audioPlayer else {
            downloadAudioAndPlay()
            return
        }

        if player.isPlaying {
            player.stop()
        }
        else {
            player.currentTime = 0
            player.play()
        }
        updatePlayButton(playing: player.isPlaying)
    }

    func updatePlayButton(playing: Bool) {
        playLabel.text = playing ? "Stop" : "Play"
    }

    func downloadAudioAndPlay() {
        downloadAudioFile { fileUrl in
            let player: AVAudioPlayer
            do {
                player = try AVAudioPlayer(contentsOf: fileUrl)
            } catch let error {
                self.presentErrorAlert(message: "Unable to read audio file", error: error)
                return
            }

            player.delegate = self
            self.audioPlayer = player

            self.setSpeakerOn(false)

            player.currentTime = 0
            player.play()
            self.updatePlayButton(playing: player.isPlaying)
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        updatePlayButton(playing: false)
    }

    /// Downloads the voicemail recording data to the filesystem
    func downloadAudioFile(callback: @escaping (URL) -> Void) {
        let storeVoicemailData = { (voicemailData: Data) -> Void in
            let path = FileManager.default
                .temporaryDirectory
                .appendingPathComponent(self.voicemailId)

            do {
                try voicemailData.write(to: path)
                callback(path)
            } catch let error {
                self.presentErrorAlert(message: "Failed to save media file", error: error)
            }
        }

        presentActivityAlert(message: "Downloading")

        let telephonyClient = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!
        telephonyClient.downloadData(for: voicemailMedia) { result in
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    switch result {
                    case .success(let voicemailData):
                        storeVoicemailData(voicemailData)
                    case .failure(let error):
                        self.presentErrorAlert(message: "Failed to download media file", error: error)
                    }
                }
            }
        }
    }
}
