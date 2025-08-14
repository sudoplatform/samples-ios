//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import SudoEmail

class SendEmailMessageViewController: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource, HeaderCellDelegate, BodyCellDelegate {

    // MARK: - Outlets

    @IBOutlet var tableView: UITableView!

    // MARK: - Supplementary

    /// Segues that are performed in `SendEmailMessageViewController`.
    enum Segue: String {
        /// Used to navigate back to the `EmailMessageListViewController`.
        case returnToEmailMessageList
    }

    /// Input fields shown on the form.
    enum InputField: Int, CaseIterable {
        case to
        case cc
        case bcc
        case subject
        case body

        /// Label of the field shown to the user.
        var label: String? {
            switch self {
            case .to:
                return "To:"
            case .cc:
                return "Cc:"
            case .bcc:
                return "Bcc:"
            case .subject:
                return "Subject:"
            default:
                return nil
            }
        }
    }

    // MARK: - Properties

    /// The native file picker controller.
    var filePickerViewController: FilePickerViewController?

    /// The native image picker controller.
    var imagePickerViewController: ImagePickerViewController?

    /// The controller for the attachment list views.
    var attachmentsListController: EmailAttachmentsListController?

    var bodyTableViewCell: BodyTableViewCell? {
        didSet {
            self.configureAttachmentsListView()
        }
    }

    /// The UI view of the indicator to be hidden/shown.
    var encryptedIndicatorView: UIView?

    /// Flag to determine is the indicator is visible or not.
    var encryptedIndicatorViewVisible: Bool = false

    /// Task that tracks the current `lookupEmailAddressesPublicInfo` SDK call.
    /// (so it can be cancelled before trying again)
    var encryptedIndicatorTask: Task<Void, Error>?

    /// Encryption status for each email address ui input.
    /// Used to track cases where multiple values need to be verified without stacking requests.
    var encryptedInputStatuses: [String: Bool?] = [
        "to": nil,
        "cc": nil,
        "bcc": nil
    ]

    /// Address of a `EmailAddress` that was selected from a previous view. Used to send a message.
    var emailAddress: EmailAddress!

    /// Save the pre-populated information for replying or forwarding
    var inputData: SendEmailInputData?

    /// Array of input fields used on the view.
    let inputFields: [InputField] = InputField.allCases

    /// Form data entered by user   . Initialized with default data.
    var formData: [InputField: String] = {
        return InputField.allCases.reduce([:], { accumulator, field in
            var accumulator = accumulator
            accumulator[field] = ""
            return accumulator
        })
    }()

    /// Email attachments that are sent with the email message.
    var attachments: Set<EmailAttachment> = []

    /// ID of message that this message is replying to
    var replyingMessageId: String?

    /// ID of message that this message is forwarding
    var forwardingMessageId: String?

    // MARK: - Properties: Computed

    /// Email client used to get and create email addresses.
    var emailClient: SudoEmailClient = AppDelegate.dependencies.emailClient

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureNavigationBar()
        configureEncryptedIndicatorView()
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard emailAddress?.emailAddress != nil else {
            Task { @MainActor in
                presentErrorAlert(message: "An error has occurred: no email address found") { _ in
                    self.performSegue(withIdentifier: Segue.returnToEmailMessageList.rawValue, sender: self)
                }
            }
            return
        }
        if let inputData = inputData {
            formData[.to] = inputData.to
            formData[.cc] = inputData.cc
            formData[.body] = inputData.body
            formData[.subject] = inputData.subject
        }
    }

    // MARK: - Keyboard Operations

    @objc func keyboardWillShow(notification: Notification) {
    }

    @objc func keyboardWillHide(notification: Notification) {
    }

    // MARK: - Actions

    @objc func didTapSendEmailButton() {
        let emailAddressId = emailAddress.id
        let from = emailAddress.emailAddress
        guard
            let to = formData[.to],
            !to.isEmpty,
            validateEmailAddressList(addresses: to)
        else {
            presentErrorAlert(message: "Invalid to address")
            return
        }
        guard
            let cc = formData[.cc],
            cc.isEmpty || validateEmailAddressList(addresses: cc)
        else {
            presentErrorAlert(message: "Invalid cc address")
            return
        }
        guard
            let bcc = formData[.bcc],
            bcc.isEmpty || validateEmailAddressList(addresses: bcc)
        else {
            presentErrorAlert(message: "Invalid bcc address")
            return
        }
        guard let subject = formData[.subject] else {
            presentErrorAlert(message: "Invalid subject")
            return
        }
        guard let body = formData[.body] else {
            presentErrorAlert(message: "Invalid body")
            return
        }

        let emailMessageHeader = InternetMessageFormatHeader(
            from: EmailAddressAndName(address: from, displayName: emailAddress.alias),
            to: addressesToArray(to),
            cc: addressesToArray(cc),
            bcc: addressesToArray(bcc),
            subject: subject
        )
        let sendEmailMessageInput = SendEmailMessageInput(
            senderEmailAddressId: emailAddressId,
            emailMessageHeader: emailMessageHeader,
            body: body,
            attachments: Array(attachments),
            replyingMessageId: replyingMessageId,
            forwardingMessageId: forwardingMessageId
        )

        Task.detached(priority: .medium) {
            await self.sendEmailMessage(sendEmailMessageInput)
        }
    }

    @objc func didTapDeleteDraftButton() {
        let alert = UIAlertController(
            title: "Delete draft",
            message: "Delete this draft message? This cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .default) { _ in
            Task { @MainActor in
                self.presentActivityAlert(message: "Deleting...")
                await self.deleteDraft()
                self.dismissActivityAlert {
                    self.performSegue(withIdentifier: Segue.returnToEmailMessageList.rawValue, sender: self)
                }
            }
        })
        present(alert, animated: true)
    }

    @objc func didTapScheduleButton() {
        guard let draftId = inputData?.draftEmailMessageId else {
            self.presentErrorAlert(message: "No draft id found")
            return
        }

        let alert = UIAlertController(title: "Schedule Send", message: "Select a date and time to send this message.", preferredStyle: .alert)

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.minimumDate = Date().addingTimeInterval(60) // at least 1 minute in the future
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.translatesAutoresizingMaskIntoConstraints = false

        alert.view.addSubview(datePicker)
        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 60),
            datePicker.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor, constant: 16),
            datePicker.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor, constant: -16),
            datePicker.heightAnchor.constraint(equalToConstant: 160)
        ])

        // Resize alert to fit date picker
        let height = NSLayoutConstraint(
          item: alert.view!, 
          attribute: .height, 
          relatedBy: .equal, 
          toItem: nil, 
          attribute: .notAnAttribute, 
          multiplier: 1, 
          constant: 320
        )
        alert.view.addConstraint(height)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Schedule", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let sendAt = datePicker.date
            if sendAt <= Date() {
                self.presentErrorAlert(message: "Please select a future date and time.")
                return
            }
            Task { @MainActor in
                self.presentActivityAlert(message: "Scheduling...")
                let input = ScheduleSendDraftMessageInput(
                    id: draftId,
                    emailAddressId: self.emailAddress.id,
                    sendAt: sendAt
                )
                do {
                    _ = try await self.emailClient.scheduleSendDraftMessage(withInput: input)
                    self.dismissActivityAlert {
                        self.performSegue(withIdentifier: Segue.returnToEmailMessageList.rawValue, sender: self)
                    }
                } catch {
                    self.dismissActivityAlert {
                        self.presentErrorAlert(message: "Failed to schedule message", error: error)
                    }
                }
            }
        })
        self.present(alert, animated: true)
    }

    @objc func didTapCancelScheduleSendButton() {
        guard let draftId = inputData?.draftEmailMessageId else {
            self.presentErrorAlert(message: "No draft id found")
            return
        }
        let alert = UIAlertController(
            title: "Cancel Schedule Send",
            message: "Cancel sending this message?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .default) { _ in
            Task { @MainActor in
                self.presentActivityAlert(message: "Cancelling...")
                let input = CancelScheduledDraftMessageInput(id: draftId, emailAddressId: self.emailAddress.id)
                do {
                    let _ = try await self.emailClient.cancelScheduledDraftMessage(withInput: input)
                    self.dismissActivityAlert {
                        self.performSegue(withIdentifier: Segue.returnToEmailMessageList.rawValue, sender: self)
                    }
                } catch {
                    self.dismissActivityAlert {
                        self.presentErrorAlert(message: "Failed to cancel sending", error: error)
                    }

                }
            }
        })
        present(alert, animated: true)
    }

    @IBAction func didTapAttachmentButton() {
        self.showAddAttachmentAlert()
    }

    @objc func didTapBackButton() {
        self.cancelSend()
    }

    // MARK: - Utilities

    func sendEmailMessage(_ sendEmailMessageInput: SendEmailMessageInput) async {
        presentActivityAlert(message: "Sending Email Message")
        do {
            _ = try await emailClient.sendEmailMessage(withInput: sendEmailMessageInput)
                await self.deleteDraft()
            Task { @MainActor in
                self.dismissActivityAlert {
                    self.performSegue(withIdentifier: Segue.returnToEmailMessageList.rawValue, sender: self)
                }
            }
        } catch {
            self.dismissActivityAlert {
                self.presentErrorAlert(message: "Failed to send email message", error: error)
            }
        }
    }

    func validateEmailAddressList(addresses: String) -> Bool {
        let addresses = addressesToArray(addresses)
        for address in addresses where !validateEmail(address.address) {
            return false
        }
        return true
    }

    func addressesToArray(_ addresses: String) -> [EmailAddressAndName] {
        var result: [EmailAddressAndName] = []
        let split = addresses.split(separator: ",").map { EmailAddressAndName(address: String($0).trimmingCharacters(in: .whitespacesAndNewlines)) }
        for address in split {
            result.append(address)
        }
        return result
    }

    func validateEmail(_ address: String) -> Bool {
        guard let addressSpecValidator = try? NSRegularExpression(pattern: "^.+@[^.].*.[a-z]{2,}$") else {
            return false
        }
        guard let rfc822AddressValidator = try? NSRegularExpression(pattern: "^.*<.+@[^.].*.[a-z]{2,}>$") else {
            return false
        }
        if address.contains(" ") {
            return rfc822AddressValidator.firstMatch(in: address, options: [], range: NSRange(location: 0, length: address.count)) != nil
        } else {
            return addressSpecValidator.firstMatch(in: address, options: [], range: NSRange(location: 0, length: address.count)) != nil
        }
    }

    func validateEncryptedEmailAddresses(_ addressesInput: String) async throws -> Bool {
        if !validateEmailAddressList(addresses: addressesInput) {
            return false
        }

        let emailAddresses = addressesToArray(addressesInput).map { $0.address }
        let input = LookupEmailAddressesPublicInfoInput(emailAddresses: emailAddresses)
        let emailAddressesPublicInfo = try await emailClient.lookupEmailAddressesPublicInfo(withInput: input)

        // Verify all request email addresses were included in the `emailAddressesPublicInfo` response
        let resultEmailAddresses = emailAddressesPublicInfo.map { $0.emailAddress }
        let result = emailAddresses.allSatisfy { emailAddress in
            resultEmailAddresses.contains(emailAddress)
        }

        return result
    }

    func handleEncryptedIndicatorView(_ addresses: String, _ fieldName: String) async throws {
        encryptedInputStatuses[fieldName] = nil
        hideEncryptedIndicatorView()

        // Cancel task each time this function is invoked to avoid bulk requests.
        encryptedIndicatorTask?.cancel()

        // Run the email address lookup as a task to allow cancellation.
        encryptedIndicatorTask = Task {
            do {
                if addresses != "" {
                    let isEncrypted = try await validateEncryptedEmailAddresses(addresses)
                    encryptedInputStatuses[fieldName] = isEncrypted
                }

                // Check if at least one input value is true (encrypted), and the rest are nil (empty)
                let validInput = encryptedInputStatuses.contains { $0.value == true }
                let invalidInput = encryptedInputStatuses.contains { $0.value == false }
                let validInputs = validInput && !invalidInput

                if validInputs {
                    showEncryptedIndicatorView()
                }
            } catch {
                self.presentErrorAlert(message: "Failed to validate email address encryption status", error: error)
            }
        }

        try await encryptedIndicatorTask?.value
    }

    @MainActor
    func cancelSend() {
        let alert = UIAlertController(
            title: "Cancel Sending",
            message: "Would you like to save this message as a draft?",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save Draft", style: .default) { _ in
            Task.detached(priority: .medium) {
                await self.saveDraft()
            }
        })
        alert.addAction(UIAlertAction(title: "Don't Save", style: .default) { _ in
            self.performSegue(withIdentifier: Segue.returnToEmailMessageList.rawValue, sender: self)
        })
        present(alert, animated: true, completion: nil)
    }

    func saveDraft() async {
        let emailAddressId = emailAddress.id
        let from = emailAddress.emailAddress
        guard let to = formData[.to],
              let cc = formData[.cc],
              let bcc = formData[.bcc],
              let subject = formData[.subject],
              let body = formData[.body] else {
            return
        }
        if to.isEmpty && cc.isEmpty && bcc.isEmpty && subject.isEmpty && body.isEmpty {
            presentErrorAlert(message: "Nothing to save") {_ in
                self.performSegue(withIdentifier: Segue.returnToEmailMessageList.rawValue, sender: self)
            }
            return
        }
        let message = BasicRFC822Message(
            from: from,
            to: addressesToArray(to).map { $0.description },
            cc: addressesToArray(cc).map { $0.description },
            bcc: addressesToArray(bcc).map { $0.description },
            subject: subject,
            body: body
        )

        guard let data = RFC822Util.fromBasicRFC822(message) else {
            presentErrorAlert(message: "Unable to marshall email message data")
            return
        }

        presentActivityAlert(message: "Saving Draft Email Message")
        do {
            if let draftEmailMessageId = inputData?.draftEmailMessageId {
                let input = UpdateDraftEmailMessageInput(
                    id: draftEmailMessageId,
                    rfc822Data: data,
                    senderEmailAddressId: emailAddressId
                )
                _ = try await self.emailClient.updateDraftEmailMessage(withInput: input)
            } else {
                let input = CreateDraftEmailMessageInput(
                    rfc822Data: data,
                    senderEmailAddressId: emailAddressId
                )
                _ = try await self.emailClient.createDraftEmailMessage(withInput: input)
            }
            Task { @MainActor in
                self.dismissActivityAlert {
                    self.performSegue(withIdentifier: Segue.returnToEmailMessageList.rawValue, sender: self)
                }
            }
        } catch {
            self.dismissActivityAlert {
                self.presentErrorAlert(message: "Failed to save draft email message", error: error)
            }
        }
    }

    func deleteDraft() async {
        do {
            if let draftEmailMessageId = inputData?.draftEmailMessageId {
                let input = DeleteDraftEmailMessagesInput(
                    ids: [draftEmailMessageId],
                    emailAddressId: emailAddress.id
                )
                _ = try await emailClient.deleteDraftEmailMessages(withInput: input)
            }
        } catch {
            self.dismissActivityAlert {
                self.presentErrorAlert(message: "Failed to delete draft email message", error: error)
            }
        }
    }

    /// Presents a `UIAlertController` providing different file system options to select an attachment from.
    func showAddAttachmentAlert() {
        let alert = UIAlertController(
            title: "Select an Attachment",
            message: "Please select an attachment to add.",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Image", style: .default) { _ in
            if self.imagePickerViewController == nil {
                self.imagePickerViewController = ImagePickerViewController(onImagePickedHandler: self.addAttachment)
            } else {
                self.imagePickerViewController?.dismiss(animated: true)
            }
            if let controller = self.imagePickerViewController {
                self.present(controller, animated: true, completion: nil)
            }
        })
        alert.addAction(UIAlertAction(title: "Document", style: .default) { _ in
            if self.filePickerViewController == nil {
                self.filePickerViewController = FilePickerViewController(onFilePickedHandler: self.addAttachment)
            } else {
                self.filePickerViewController?.dismiss(animated: true)
            }
            if let controller = self.filePickerViewController {
                self.present(controller, animated: true, completion: nil)
            }
        })
        present(alert, animated: true, completion: nil)
    }

    func buildAttachment(withURL fileURL: URL) -> EmailAttachment? {
        do {
            let filename = fileURL.lastPathComponent
            let pathExtension = (filename as NSString).pathExtension
            let mimetype = UTType(filenameExtension: pathExtension)?.preferredMIMEType ?? "application/octet-stream"
            let data = try Data(contentsOf: fileURL)
            let attachment = EmailAttachment(
                filename: filename,
                mimetype: mimetype,
                inlineAttachment: false,
                data: data
            )

            return attachment
        } catch {
            presentErrorAlert(message: "Failed to parse base64 data from file")
            return nil
        }
    }

    func addAttachment(fileURL: URL) {
        if let emailAttachment = self.buildAttachment(withURL: fileURL) {
            self.attachments.insert(emailAttachment)
            self.tableView.beginUpdates()
            self.attachmentsListController?.setAttachments(attachments: self.attachments)
            self.tableView.endUpdates()
        }
    }

    func removeAttachment(attachmentName: String) {
        if let emailAttachment = (attachments.first { $0.filename == attachmentName }) {
            self.attachments.remove(emailAttachment)
            self.tableView.beginUpdates()
            self.attachmentsListController?.setAttachments(attachments: self.attachments)
            self.tableView.endUpdates()
        }
    }

    // MARK: - Helpers: Configuration

    func configureAttachmentsListView() {
        guard let containingView = self.bodyTableViewCell?.contentView,
              let siblingView = self.bodyTableViewCell?.textView else {
            return
        }
        self.attachmentsListController = EmailAttachmentsListController(
            containingView: containingView,
            siblingView: siblingView,
            onListItemClickedHandler: { self.removeAttachment(attachmentName: $0) }
        )
        guard let attachmentsListView = self.attachmentsListController?.attachmentsListView else { return }

        // Only add constraints to the attachmentsListView, not the textView, to avoid conflicts
        attachmentsListView.translatesAutoresizingMaskIntoConstraints = false
        containingView.addSubview(attachmentsListView)

        let margin = containingView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            attachmentsListView.topAnchor.constraint(equalTo: margin.topAnchor),
            attachmentsListView.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
            attachmentsListView.trailingAnchor.constraint(equalTo: margin.trailingAnchor),
            // Attach the attachmentsListView to the top, and let the textView be laid out as per IB
            attachmentsListView.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
        ])
    }

    func configureTableView() {
        let headerTableViewCellNib = UINib(nibName: "HeaderTableViewCell", bundle: .main)
        tableView.register(headerTableViewCellNib, forCellReuseIdentifier: "headerCell")
        let bodyCellNib = UINib(nibName: "BodyTableViewCell", bundle: .main)
        tableView.register(bodyCellNib, forCellReuseIdentifier: "bodyCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
    }

    func configureNavigationBar() {
        let paperPlaneImage = UIImage(systemName: "paperplane")
        let sendBarButton = UIBarButtonItem(
            image: paperPlaneImage,
            style: .plain,
            target: self,
            action: #selector(didTapSendEmailButton)
        )
        let paperclipImage = UIImage(systemName: "paperclip")
        let attachmentButton = UIBarButtonItem(
            image: paperclipImage,
            style: .plain,
            target: self,
            action: #selector(didTapAttachmentButton)
        )
        navigationItem.rightBarButtonItems = [sendBarButton, attachmentButton]

        if inputData?.draftEmailMessageId != nil {
            let deleteImage = UIImage(systemName: "trash")
            let deleteDraftBarButton = UIBarButtonItem(
                image:  deleteImage,
                style: .plain,
                target: self,
                action: #selector(didTapDeleteDraftButton)
            )
            navigationItem.rightBarButtonItems?.append(deleteDraftBarButton)

            if inputData?.scheduledAt == nil {
                let scheduleImage = UIImage(systemName: "clock")
                let scheduleSendBarButton = UIBarButtonItem(
                    image: scheduleImage,
                    style: .plain,
                    target: self,
                    action: #selector(didTapScheduleButton)
                )
                navigationItem.rightBarButtonItems?.append(scheduleSendBarButton)
            } else {
                let cancelScheduleImage = UIImage(systemName: "clock.badge.xmark")
                let cancelScheduleSendButton = UIBarButtonItem(
                    image: cancelScheduleImage,
                    style: .plain,
                    target: self,
                    action: #selector(didTapCancelScheduleSendButton)
                )
                navigationItem.rightBarButtonItems?.append(cancelScheduleSendButton)
            }
        }

        let backImage = UIImage(systemName: "chevron.backward")
        let backButton = UIBarButtonItem(
            image: backImage,
            style: .plain,
            target: self,
            action: #selector(didTapBackButton)
        )
        navigationItem.leftBarButtonItem = backButton
    }

    /// Create the view that will hide/show when the email address in the `send` input field is verified.
    func configureEncryptedIndicatorView() {
        let height = Int(40)
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: Int(tableView.frame.size.width), height: height))

        label.center = CGPoint(x: Int(UIScreen.main.bounds.width) / 2, y: height / 2)
        label.backgroundColor = UIColor.systemGray
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14.0)

        let attributedText = NSMutableAttributedString()
        let lockImageString = UIImage.toAttributedString(systemName: "lock.fill", withTintColor: .link)
        let textString = NSAttributedString(string: " End-to-end encrypted")
        attributedText.append(lockImageString)
        attributedText.append(textString)

        label.attributedText = attributedText
        encryptedIndicatorView = label
    }

    func hideEncryptedIndicatorView() {
        if encryptedIndicatorViewVisible {
            tableView.tableHeaderView = nil
            encryptedIndicatorViewVisible = false
        }
    }

    func showEncryptedIndicatorView() {
        if !encryptedIndicatorViewVisible {
            tableView.tableHeaderView = encryptedIndicatorView
            encryptedIndicatorViewVisible = true
            tableView.layoutIfNeeded()
        }
    }

    // MARK: - Conformance: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inputFields.count
    }

    func isHeaderField(forIndexPath indexPath: IndexPath) -> Bool {
        guard let inputField = InputField(rawValue: indexPath.row) else {
            return false
        }
        let headerFields: [InputField] = [.to, .bcc, .cc, .subject]
        return headerFields.contains(inputField)
    }

    /// Get the form's input label for the current `indexPath`.
    func getInputLabel(forIndexPath indexPath: IndexPath) -> String {
        return InputField(rawValue: indexPath.row)?.label ?? "Field"
    }

    /// Get the form's input text for the current `indexPath`.
    func getFormInput(forIndexPath indexPath: IndexPath) -> String? {
        guard let inputField = InputField(rawValue: indexPath.row) else {
            return nil
        }
        return formData[inputField]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isHeaderField(forIndexPath: indexPath) {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell") as? HeaderTableViewCell else {
                return HeaderTableViewCell()
            }
            cell.delegate = self
            cell.label.text = getInputLabel(forIndexPath: indexPath)
            cell.textField.text = getFormInput(forIndexPath: indexPath)
            guard let inputField = InputField(rawValue: indexPath.row) else {
                return cell
            }
            switch inputField {
            case .bcc, .cc, .to:
                cell.textField.keyboardType = .emailAddress
            default:
                break
            }
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "bodyCell") as? BodyTableViewCell else {
                return BodyTableViewCell()
            }
            let text: String
            if let formBody = formData[.body], !formBody.isEmpty {
                text = formBody
            } else {
                text = "\n\nSent from Sudo Platform Email Sample App"
            }
            cell.textView.text = text
            cell.delegate = self
            self.bodyTableViewCell = cell
            return cell
        }
    }

    // MARK: - Conformance: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let cell = tableView.cellForRow(at: indexPath) as? HeaderTableViewCell {
            cell.textField.becomeFirstResponder()
        }
        if let cell = tableView.cellForRow(at: indexPath) as? BodyTableViewCell {
            cell.textView.becomeFirstResponder()
        }
    }

    func headerCell(_ cell: HeaderTableViewCell, didUpdateInput input: String?) {
        guard let indexPath = tableView.indexPath(for: cell), let field = InputField(rawValue: indexPath.row) else {
            return
        }
        let input = cell.textField.text
        if input == nil || input!.isEmpty {
            formData[field] = nil
        } else {
            formData[field] = input
        }

        let fieldName: String?
        switch indexPath.row {
        case 0:
            fieldName = "to"
        case 1:
            fieldName = "cc"
        case 2:
            fieldName = "bcc"
        default:
            fieldName = nil
        }

        if fieldName != nil {
            Task { @MainActor in
                try await self.handleEncryptedIndicatorView(input ?? "", fieldName!)
            }
        }
    }

    func bodyCell(_ cell: BodyTableViewCell, didUpdateInput input: String?) {
        tableView.beginUpdates()
        formData[.body] = input
        tableView.endUpdates()
    }
}
