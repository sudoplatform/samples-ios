//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoTelephony

class MessageDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var message: PhoneMessage!
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }
    
    @IBAction func deleteMessage(_ sender: UIBarButtonItem) {
        let telephonyClient = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!
        
        let completion: (Result<String, SudoTelephonyClientError>) -> Void = { result in
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    switch result {
                    case .success:
                        let alert = UIAlertController(title: "Message Deleted", message: nil, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            self.performSegue(withIdentifier: "returnToConversationDetails", sender: self)
                        })
                        self.present(alert, animated: true, completion: nil)
                    case .failure(let error):
                        self.presentErrorAlert(message: "Failed to delete message", error: error)
                    }
                }
            }
        }
        
        do {
            self.presentActivityAlert(message: "Deleting Message")
            try telephonyClient.deleteMessage(id: self.message.id, completion: completion)
        } catch {
            presentErrorAlert(message: "Failed to delete message", error: error)
        }
    }
    
    private func downloadAttachment(mediaObject: S3MediaObject, completion: @escaping ((UIImage) -> Void)) {
        let telephonyClient = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!
        
        telephonyClient.downloadData(s3Object: mediaObject) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let image = UIImage(data: data) {
                        completion(image)
                    }
                    else {
                        self.presentErrorAlert(message: "Unable to parse image from message media")
                    }
                case .failure(let error):
                    self.presentErrorAlert(message: "Failed to download data", error: error)
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5 + self.message.media.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let direction = (self.message.direction == PhoneMessage.Direction.inbound) ? "Incoming" : "Outgoing"
            let type = (self.message.media.count > 0) ? "MMS" : "SMS"
            return detailCell(tableView, title: "Type", detail: direction + " " + type)
        case 1:
            let time = DateFormatter.localizedString(from: message.created, dateStyle: .short, timeStyle: .short)
            return detailCell(tableView, title: "Time", detail: time)
        case 2:
            let detail = formatAsUSNumber(number: message.remotePhoneNumber)
            return detailCell(tableView, title: "Remote Number", detail: detail)
        case 3:
            return detailCell(tableView, title: "Status", detail: self.message.state.description)
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "bodyCell") as! MessageBodyCell
            let trimmedBody = self.message.body.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if trimmedBody.count == 0 {
                cell.bodyLabel.text = "(No Body)"
            }
            else {
                cell.bodyLabel.text = trimmedBody
            }
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "imageCell") as! MessageImageCell
            cell.attachmentImageView.image = nil
            let media = message.media[indexPath.row - 5]
            downloadAttachment(mediaObject: media) { image in
                DispatchQueue.main.async {
                    let cell = tableView.cellForRow(at: indexPath) as? MessageImageCell
                    cell?.attachmentImageView.image = image
                }
            }
            return cell
        }
    }

    func detailCell(_ tableView: UITableView, title: String, detail: String) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell")!
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = detail
        return cell
    }

}

class MessageBodyCell: UITableViewCell {
    @IBOutlet var bodyLabel: UILabel!
}

class MessageImageCell: UITableViewCell {
    @IBOutlet var attachmentImageView: UIImageView!
}

extension PhoneMessage.State {
    var description: String {
        switch self {
            case .queued: return "Queued"
            case .sent: return "Sent"
            case .delivered: return "Delivered"
            case .failed: return "Failed"
            case .received: return "Recieved"
            case .undelivered: return "Undelivered"
            case .unknown: return "Unknown"
        }
    }
}
