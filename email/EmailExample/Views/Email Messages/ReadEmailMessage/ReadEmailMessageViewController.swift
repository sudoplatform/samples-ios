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
        /// Used to navigate to the `SendEmailMessageViewController`.
        case replyToEmailMessage
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
            guard let inputData = constructReplyInput() else {
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

    /// Action associalted with blocking an email address
    ///
    /// This action will block the sender of the email being read
    @objc func blockSenderAddress() {
        let address = emailMessage.from[0].address
        Task.init {
            do {
                let blockRes = try await emailClient.blockEmailAddresses(addresses: [address])
                switch blockRes.status {
                case .success:
                    presentAlert(title: "Success", message: "\(address) has been blocked") { _ in
                        self.performSegue(withIdentifier: Segue.returnToEmailMessageList.rawValue, sender: self)
                    }
                case .failure:
                    presentErrorAlert(message: "Error blocking email address")
                default:
                    // no-op - Should never reach this as only passing one address
                    NSLog("Unexpected block result \(blockRes)")
                }
            } catch {
                NSLog("Error blocking email address \(error)")
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
        let arrowImage = UIImage(systemName: "arrowshape.turn.up.left")
        let replyButton = UIBarButtonItem(image: arrowImage, style: .plain, target: self, action: #selector(replyToMessage))
        replyButton.accessibilityIdentifier = "replyButton"

        let blockImage = UIImage(systemName: "nosign")
        let blockButton = UIBarButtonItem(image: blockImage, style: .plain, target: self, action: #selector(blockSenderAddress))
        blockButton.accessibilityIdentifier = "blockButton"

        navigationItem.rightBarButtonItems = [replyButton, blockButton]
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
                    let body = parsedMessage.body
                    let attachments = parsedMessage.attachments
                    if message.hasAttachments && attachments.isEmpty {
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
                            label.text = $0.displayName ?? $0.address
                            label.adjustsFontSizeToFitWidth = true
                            label.minimumScaleFactor = 0.7
                            return label
                        }
                        let ccLabels: [UILabel] = message.cc.map {
                            let label = UILabel()
                            label.font = UIFont.systemFont(ofSize: 14.0)
                            label.text = $0.displayName ?? $0.address
                            label.adjustsFontSizeToFitWidth = true
                            label.minimumScaleFactor = 0.7
                            return label
                        }
                        self.fromLabel.text = message.from.first?.displayName ?? message.from.first?.address
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
            replyTo = RFC822Util.toRfc822Address(messageAddresses: emailMessage.from)
        }
        var replyCc = ""
        if !emailMessage.cc.isEmpty {
            replyCc = RFC822Util.toRfc822Address(messageAddresses: emailMessage.to)
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
                body: replyBody.replacingOccurrences(of: "\n\n---------------\n\n", with: "")
            )
        }
        return sendEmailInput
    }

    func saveAttachment(attachmentName: String) {
        var errorMsg: String?
        // iOS 16+ required for `URL.downloadsDirectory` and `.appending`
        if #available(iOS 16.0, *) {
            if let emailAttachment = (attachments.first { $0.filename == attachmentName }),
               let fileData = Data(base64Encoded: emailAttachment.data) {
                do {
                    let url = URL.documentsDirectory.appending(path: emailAttachment.filename)
                    try fileData.write(to: url, options: [.atomic, .completeFileProtection])
                    Task { presentAlert(title: "Success", message: "Saved \(emailAttachment.filename) to Documents") }
                    return
                } catch {
                    NSLog("Failed to save attachment: \(error.localizedDescription)")
                    errorMsg = "Failed to save attachment"
                }
            } else {
                errorMsg = "Failed to parse attachment"
            }
        } else {
            errorMsg = "At least iOS 16.0 required"
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
