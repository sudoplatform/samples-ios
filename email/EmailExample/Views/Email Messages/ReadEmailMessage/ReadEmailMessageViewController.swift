//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import UniformTypeIdentifiers
import SudoEmail

class ReadEmailMessageViewController: UIViewController, ActivityAlertViewControllerDelegate {

    // MARK: - Outlets

    @IBOutlet var fromLabel: UILabel!
    @IBOutlet var dateLabel: DateLabel!

    @IBOutlet var toMessageStackView: UIStackView!
    @IBOutlet var ccMessageStackView: UIStackView!

    @IBOutlet var subjectLabel: UILabel!

    @IBOutlet var bodyLabel: UILabel!

    // MARK: - Supplementary

    /// Segues that are performed in `EmailMessageListViewController`.
    enum Segue: String {
        /// Used to navigate to the `SendEmailMessageViewController` for replying.
        case replyToEmailMessage
        /// Used to navigate to the `SendEmailMessageViewController` for forwarding.
        case forwardEmailMessage
        /// Used to navigate back to the `EmailMessageListViewController`.
        case returnToEmailMessageList
    }

    // MARK: - Properties

    /// If true, the message is loaded.
    var messageLoaded = false

    /// `EmailAddress` that was selected from a previous view.
    var emailAddress: EmailAddress!

    /// Message of a `EmailMessage` that was selected from the previous view.
    var emailMessage: EmailMessage!

    var scheduledAt: Date?

    /// Attachments belonging to the email message.
    var attachments: [EmailAttachment] = []

    /// The controller for the attachment list views.
    var attachmentsListController: EmailAttachmentsListController?

    // MARK: - Properties: Computed

    /// Email client used to get and create email addresses.
    var emailClient: SudoEmailClient = AppDelegate.dependencies.emailClient

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureHeaderView()
        configureBodyView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let emailMessage = emailMessage else {
            Task { @MainActor in
                presentErrorAlert(message: "An error has occurred: no email message found") { _ in
                    self.performSegue(withIdentifier: Segue.returnToEmailMessageList.rawValue, sender: self)
                }
            }
            return
        }
        guard let emailAddress = emailAddress, !emailAddress.emailAddress.isEmpty else {
            Task { @MainActor in
                presentErrorAlert(message: "An error has occurred: no email address found") { _ in
                    self.performSegue(withIdentifier: Segue.returnToEmailMessageList.rawValue, sender: self)
                }
            }
            return
        }
        if !messageLoaded {
            loadEmailMessage(emailMessage)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueType = Segue(rawValue: segue.identifier ?? "")
        switch segueType {
        case .replyToEmailMessage:
            guard let sendEmailMessage = segue.destination as? SendEmailMessageViewController else {
                return
            }
            sendEmailMessage.emailAddress = emailAddress
            sendEmailMessage.replyingMessageId = emailMessage.id
            guard let inputData = constructReplyInput() else {
                return
            }
            sendEmailMessage.inputData = inputData
        case .forwardEmailMessage:
            guard let sendEmailMessage = segue.destination as? SendEmailMessageViewController else {
                return
            }
            sendEmailMessage.emailAddress = emailAddress
            sendEmailMessage.forwardingMessageId = emailMessage.id
            guard let inputData = constructForwardInput() else {
                return
            }
            sendEmailMessage.inputData = inputData
        default:
            break
        }
    }

    // MARK: - Actions

    /// Action associated with replying to a message.
    ///
    /// This action will reply to the message using the sendEmailMessage view.
    @objc func replyToMessage(_ sender: ReadEmailMessageViewController) {
        performSegue(withIdentifier: Segue.replyToEmailMessage.rawValue, sender: self)
    }

    /// Action associated with forwarding a message.
    ///
    /// This action will forward the message using the sendEmailMessage view.
    @objc func forwardMessage(_ sender: ReadEmailMessageViewController) {
        performSegue(withIdentifier: Segue.forwardEmailMessage.rawValue, sender: self)
    }

    /// Action associalted with blocking an email address
    ///
    /// This action will block the sender of the email being read
    @objc func blockSenderAddress() {
        presentActivityAlert(message: "Blocking Email Address")
        let address = emailMessage.from[0].address
        Task.init {
            do {
                let blockRes = try await emailClient.blockEmailAddresses(addresses: [address])
                switch blockRes.status {
                case .success:
                    self.dismissActivityAlert()
                    presentAlert(title: "Success", message: "\(address) has been blocked") { _ in
                        self.performSegue(withIdentifier: Segue.returnToEmailMessageList.rawValue, sender: self)
                    }
                case .failure:
                    self.dismissActivityAlert()
                    presentErrorAlert(message: "Error blocking email address")
                default:
                    self.dismissActivityAlert()
                    // no-op - Should never reach this as only passing one address
                    NSLog("Unexpected block result \(blockRes)")
                }
            } catch {
                NSLog("Error blocking email address \(error)")
                self.dismissActivityAlert()
                presentErrorAlert(message: "Error blocking email address")
            }
        }
    }

    // MARK: - Operations

    func readEmailMessage(messageId: String) async throws -> EmailMessageWithBody? {
        let getEmailMessageInput = GetEmailMessageWithBodyInput(id: messageId, emailAddressId: self.emailAddress.id)
        return try await emailClient.getEmailMessageWithBody(withInput: getEmailMessageInput)
    }

    func readDraftEmailMessage(messageId: String) async throws -> Data {
        let getDraftInput = GetDraftEmailMessageInput(id: messageId, emailAddressId: self.emailAddress.id)
        guard let draftEmailMessage = try await emailClient.getDraftEmailMessage(withInput: getDraftInput) else {
            throw SudoEmailError.emailMessageNotFound
        }
        return draftEmailMessage.rfc822Data
    }

    // MARK: - Helpers: Configuration

    func configureNavigationBar() {
        let replyImage = UIImage(systemName: "arrowshape.turn.up.left")
        let replyButton = UIBarButtonItem(image: replyImage, style: .plain, target: self, action: #selector(replyToMessage))
        replyButton.accessibilityIdentifier = "replyButton"

        let forwardImage = UIImage(systemName: "arrowshape.turn.up.right")
        let forwardButton = UIBarButtonItem(image: forwardImage, style: .plain, target: self, action: #selector(forwardMessage))
        forwardButton.accessibilityIdentifier = "forwardButton"

        let blockImage = UIImage(systemName: "nosign")
        let blockButton = UIBarButtonItem(image: blockImage, style: .plain, target: self, action: #selector(blockSenderAddress))
        blockButton.accessibilityIdentifier = "blockButton"

        navigationItem.rightBarButtonItems = [replyButton, forwardButton, blockButton]
    }

    func configureHeaderView() {
        // clear out placeholder data from XIB.
        toMessageStackView.arrangedSubviews.forEach {
            toMessageStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        ccMessageStackView.arrangedSubviews.forEach {
            ccMessageStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        fromLabel.text = nil
        fromLabel.adjustsFontSizeToFitWidth = true
        fromLabel.minimumScaleFactor = 0.7
        dateLabel.date = nil
    }

    func configureBodyView() {
        subjectLabel.text = nil
        bodyLabel.text = nil
    }

    func configureAttachmentsListView() {
        guard let siblingView = self.bodyLabel, let containingView = siblingView.superview else { return }
        self.attachmentsListController = EmailAttachmentsListController(
            containingView: containingView,
            siblingView: siblingView,
            onListItemClickedHandler: { self.saveAttachment(attachmentName: $0) }
        )
        guard let attachmentsListController = self.attachmentsListController else { return }

        let margin = containingView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            siblingView.topAnchor.constraint(equalTo: attachmentsListController.attachmentsListView!.bottomAnchor, constant: 5.0),
            siblingView.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
            siblingView.trailingAnchor.constraint(equalTo: margin.trailingAnchor),
            siblingView.bottomAnchor.constraint(equalTo: margin.bottomAnchor)
        ])

        attachmentsListController.setAttachments(attachments: Set(self.attachments))
    }

    // MARK: - Helpers

    /// Firstly, attempts to load the email message via a remote call.
    ///
    /// On any failure, a "Failed to get Email Message" UIAlert message will be presented to the user.
    func loadEmailMessage(_ message: EmailMessage) {
        presentCancellableActivityAlert(message: "Loading", delegate: self) {
            Task.detached(priority: .medium) {
                do {
                    // Handle draft messages
                    if message.folderId.contains("DRAFTS") {
                        let rfc822Data = try await self.readDraftEmailMessage(messageId: message.id)
                        let parsedMessage = try RFC822Util.fromPlainText(rfc822Data)
                        Task { @MainActor in
                            self.bodyLabel.text = parsedMessage.body
                            self.dismissActivityAlert()
                            self.performSegue(withIdentifier: Segue.replyToEmailMessage.rawValue, sender: self)
                        }
                        return
                    }
                    // Handle sent messages
                    let parsedMessage: EmailMessageWithBody
                    do {
                        guard let emailMessageWithBody = try await self.readEmailMessage(messageId: message.id) else {
                            throw SudoEmailError.serviceError
                        }
                        parsedMessage = emailMessageWithBody
                    } catch {
                        Task { @MainActor in
                            self.dismissActivityAlert()
                            self.presentErrorAlert(message: "Failed load email message", error: error) { _ in
                                self.performSegue(withIdentifier: Segue.returnToEmailMessageList.rawValue, sender: self)
                            }
                        }
                        return
                    }
                    // Get body and attachments, and verify
                    let body: String
                    if parsedMessage.isHtml {
                        if let data = parsedMessage.body.data(using: .utf8) {
                            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                                .documentType: NSAttributedString.DocumentType.html,
                                .characterEncoding: String.Encoding.utf8.rawValue
                            ]
                            let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil)
                            body = attributedString?.string ?? parsedMessage.body
                        } else {
                            body = parsedMessage.body
                        }
                    } else {
                        body = parsedMessage.body
                    }
                    let attachments = parsedMessage.attachments
                    let inlineAttachments = parsedMessage.inlineAttachments
                    if message.hasAttachments && attachments.isEmpty && inlineAttachments.isEmpty {
                       Task { @MainActor in
                           self.dismissActivityAlert()
                           self.presentErrorAlert(message: "Failed to load email attachments") { _ in
                               self.performSegue(withIdentifier: Segue.returnToEmailMessageList.rawValue, sender: self)
                           }
                       }
                       return
                    }
                    // Populate views with message data
                    Task { @MainActor in
                        let toLabels: [UILabel] = message.to.map {
                            let label = UILabel()
                            label.font = UIFont.systemFont(ofSize: 14.0)
                            label.text = ($0.displayName != nil) ? "\($0.displayName ?? "") <\($0.address)>" : $0.address
                            label.adjustsFontSizeToFitWidth = true
                            label.minimumScaleFactor = 0.7
                            return label
                        }
                        let ccLabels: [UILabel] = message.cc.map {
                            let label = UILabel()
                            label.font = UIFont.systemFont(ofSize: 14.0)
                            label.text = ($0.displayName != nil) ? "\($0.displayName ?? "") <\($0.address)>" : $0.address
                            label.adjustsFontSizeToFitWidth = true
                            label.minimumScaleFactor = 0.7
                            return label
                        }
                        self.fromLabel.text = (message.from.first?.displayName != nil) ?
                        "\(message.from.first?.displayName ?? "") <\(message.from.first?.address ?? "")>" : message.from.first?.address
                        toLabels.forEach {
                            self.toMessageStackView.addArrangedSubview($0)
                        }
                        ccLabels.forEach {
                            self.ccMessageStackView.addArrangedSubview($0)
                        }
                        self.ccMessageStackView.isHidden = self.ccMessageStackView.arrangedSubviews.isEmpty
                        self.dateLabel.date = message.createdAt
                        self.subjectLabel.text = message.subject
                        self.bodyLabel.text = body
                        self.attachments = attachments
                        if !self.attachments.isEmpty { self.configureAttachmentsListView() }
                        self.messageLoaded = true
                    }
                    await self.dismissActivityAlert()
                }
            }
        }
    }

    func constructReplyInput() -> SendEmailInputData? {
        var to = ""
        if !emailMessage.to.isEmpty {
            to = RFC822Util.toRfc822Address(messageAddresses: emailMessage.to)
        }
        var replyTo = ""
        if !emailMessage.from.isEmpty {
            replyTo = RFC822Util.toRfc822Address(messageAddresses: emailMessage.from.map { EmailAddressAndName(address: $0.address) })
        }
        var replyCc = ""
        if !emailMessage.cc.isEmpty {
            replyCc = RFC822Util.toRfc822Address(messageAddresses: emailMessage.cc.map { EmailAddressAndName(address: $0.address) })
        }
        var replySubject = ""
        if let subject = emailMessage.subject {
            if subject.starts(with: "Re:") {
                replySubject = subject
            } else {
                replySubject = "Re: \(subject)"
            }
        }
        var replyBody = ""
        if let bodyText = bodyLabel.text {
            replyBody = "\n\n---------------\n\n\(bodyText)"
        }
        var sendEmailInput = SendEmailInputData(to: replyTo, cc: replyCc, subject: replySubject, body: replyBody)
        if emailMessage.folderId.contains("DRAFTS") {
            sendEmailInput = SendEmailInputData(
                draftEmailMessageId: emailMessage.id,
                to: to,
                cc: replyCc,
                subject: replySubject.replacingOccurrences(of: "Re:", with: ""),
                body: replyBody.replacingOccurrences(of: "\n\n---------------\n\n", with: ""),
                scheduledAt: self.scheduledAt
            )
        }
        return sendEmailInput
    }

    func constructForwardInput() -> SendEmailInputData? {
        var forwardSubject = ""
        if let subject = emailMessage.subject {
            if subject.starts(with: "Fwd:") {
                forwardSubject = subject
            } else {
                forwardSubject = "Fwd: \(subject)"
            }
        }
        var forwardBody = ""
        if let bodyText = bodyLabel.text {
            forwardBody = "\n\n---------------\n\n\(bodyText)"
        }
        var sendEmailInput = SendEmailInputData(subject: forwardSubject, body: forwardBody)
        if emailMessage.folderId.contains("DRAFTS") {
            sendEmailInput = SendEmailInputData(
                draftEmailMessageId: emailMessage.id,
                subject: forwardSubject.replacingOccurrences(of: "Fwd:", with: ""),
                body: forwardBody.replacingOccurrences(of: "\n\n---------------\n\n", with: "")
            )
        }
        return sendEmailInput
    }

    enum FileContent {
        case document(Data)
        case image(UIImage)
    }

    func saveAttachment(attachmentName: String) {
        var errorMsg: String?
        let fileManager = FileManager.default

        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            errorMsg = "Could not find document directory"
            return
        }

        guard let attachment = attachments.first(where: { $0.filename == attachmentName }) else {
            errorMsg = "Attachment not found"
            return
        }

        let fileContent: FileContent
        if attachment.mimetype.contains("image/") {
            guard let imageData = Data(base64Encoded: attachment.data),
                  let image = UIImage(data: imageData) else {
                errorMsg = "Could not convert image data"
                return
            }
            fileContent = .image(image)
        } else {
            guard let documentData = Data(base64Encoded: attachment.data) else {
                errorMsg = "Could not convert document data"
                return
            }
            fileContent = .document(documentData)
        }

        let fileURL = documentDirectory.appendingPathComponent(attachmentName)

        do {
            switch fileContent {
            case .document(let content):
                try content.write(to: fileURL, options: [.atomic, .completeFileProtection])
                Task { presentAlert(title: "Success", message: "Saved \(attachment.filename) successfully at \(fileURL.path)") }
            case .image(let image):
                guard let imageData = image.jpegData(compressionQuality: 1.0) else {
                    errorMsg = "Could not convert image to JPEG data"
                    return
                }
                try imageData.write(to: fileURL)
                Task { presentAlert(title: "Success", message: "Saved \(attachment.filename) successfully at \(fileURL.path)") }
            }
        } catch {
            errorMsg = "Error saving file: \(error.localizedDescription)"
        }

        if let errorMsg = errorMsg {
               Task { presentErrorAlert(message: errorMsg) }
           }
    }

    // MARK: - Conformance: ActivityAlertViewControllerDelegate

    func didTapAlertCancelButton() {
        dismissActivityAlert {
            self.navigationController?.popViewController(animated: true)
        }
    }

}
