//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import CoreServices
import SudoTelephony

class CreateMessageViewController: UIViewController, UITextViewDelegate {

    var localNumber: PhoneNumber!
    var remoteNumber: String?

    @IBOutlet weak var recipientTextField: UITextField!
    @IBOutlet weak var bodyTextView: UITextView!
    @IBOutlet weak var deleteAttachmentButton: UIButton!
    @IBOutlet weak var insertAttachmentButton: UIButton!
    @IBOutlet weak var attachmentPreview: UIImageView!
    @IBOutlet weak var sendButton: UIBarButtonItem!

    private var attachmentImageURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        attachmentPreview.isHidden = true
        deleteAttachmentButton.isHidden = true

        sendButton.isEnabled = false

        recipientTextField.text = remoteNumber

        // make UITextView look like UITextField
        bodyTextView.layer.cornerRadius = 5
        bodyTextView.layer.borderWidth = 1
        bodyTextView.layer.borderColor = UIColor(named: "borderGray")?.cgColor
    }

    @IBAction func sendMessage(_ sender: UIBarButtonItem) {
        let remoteNumber = recipientTextField.text!
        let message = bodyTextView.text!

        let telephonyClient = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!

        let completion: (Result<PhoneMessage, SudoTelephonyClientError>) -> Void = { result in
            DispatchQueue.main.async {
                // dismiss activity alert
                self.dismiss(animated: true) {
                    switch result {
                    case .success:
                        let alert = UIAlertController(title: "Success", message: nil, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            self.performSegue(withIdentifier: "returnToConversationDetails", sender: self)
                        })
                        self.present(alert, animated: true, completion: nil)
                    case .failure(let error):
                        self.presentErrorAlert(message: "Failed to send message", error: error)
                    }
                }
            }
        }

        do {
            view.endEditing(true)

            presentActivityAlert(message: "Sending message")

            if let attachmentImageURL = attachmentImageURL {
                try telephonyClient.sendMMSMessage(localNumber: self.localNumber, remoteNumber: remoteNumber, body: message, localUrl: attachmentImageURL, completion: completion)
            } else {
                try telephonyClient.sendSMSMessage(localNumber: self.localNumber, remoteNumber: remoteNumber, body: message, completion: completion)
            }
        } catch let error {
            dismiss(animated: true) {
                self.presentErrorAlert(message: "Failed to send message", error: error)
            }
        }
    }

    private func updateSendButtonEnabled() {
        sendButton.isEnabled = !(recipientTextField.text ?? "").isEmpty &&
            (!(bodyTextView.text ?? "").isEmpty || attachmentImageURL != nil)
    }

    @IBAction func recipientChanged(_ sender: UITextField, forEvent event: UIEvent) {
        updateSendButtonEnabled()
    }

    @objc func textViewDidChange(_ textView: UITextView) {
        updateSendButtonEnabled()
    }

    @IBAction func deleteAttachment() {
        self.attachmentImageURL = nil
        self.attachmentPreview.image = nil
        self.attachmentPreview.isHidden = true
        self.deleteAttachmentButton.isHidden = true
        self.insertAttachmentButton.isHidden = false
        updateSendButtonEnabled()
    }

    @IBAction func insertAttachment() {
        class BlockImagePickerControllerDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
            private let didFinishPickingMediaWithInfo: ([UIImagePickerController.InfoKey : Any]?) -> Void

            init(didFinishPickingMediaWithInfo: @escaping ([UIImagePickerController.InfoKey : Any]?) -> Void) {
                self.didFinishPickingMediaWithInfo = didFinishPickingMediaWithInfo
            }

            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                self.didFinishPickingMediaWithInfo(info)
            }

            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                self.didFinishPickingMediaWithInfo(nil)
            }
        }

        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
            && (UIImagePickerController.availableMediaTypes(for: .photoLibrary) ?? []).contains(kUTTypeImage as String) {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.mediaTypes = [kUTTypeImage as String]
            var delegate: BlockImagePickerControllerDelegate?
            delegate = BlockImagePickerControllerDelegate { [weak self] info in
                delegate = nil
                self?.dismiss(animated: true)

                guard let self = self else { return }
                guard let image = info?[.editedImage] as? UIImage ?? info?[.originalImage] as? UIImage,
                    let imageURL = image.resizeForMMS()?.saveToTemporaryURL() else {
                        self.presentErrorAlert(message: "Could not retrieve image URL.")
                        return
                }

                self.attachmentImageURL = imageURL
                self.attachmentPreview.image = image
                self.attachmentPreview.isHidden = false
                self.deleteAttachmentButton.isHidden = false
                self.insertAttachmentButton.isHidden = true
                self.updateSendButtonEnabled()
            }
            picker.delegate = delegate
            self.present(picker, animated: true)
        } else {
            self.presentErrorAlert(message: "Failed to add attachment")
        }
    }
}
