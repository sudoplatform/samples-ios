//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
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

    /// Typealias for a successful response call to `SudoEmailClient.getEmailMessageRFC822DataWithId(_:completion:)`.
    typealias GetEmailMessageSuccessCompletion = (Data) -> Void

    /// Typealias for a error response call to `SudoEmailClient.getEmailMessageRFC822DataWithId(_:completion:)`.
    typealias GetEmailMessageErrorCompletion = (Error) -> Void

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
        guard let emailMessage = emailMessage, !emailMessage.address.isEmpty else {
            presentErrorAlert(
                message: "An error has occurred: no email address found",
                okHandler: { _ in
                    self.performSegue(withIdentifier: Segue.returnToEmailMessageList.rawValue, sender: self)
                }
            )
            return
        }
        guard let emailAddress = emailAddress, !emailAddress.address.isEmpty else {
            presentErrorAlert(
                message: "An error has occurred: no email address found",
                okHandler: { _ in
                    self.performSegue(withIdentifier: Segue.returnToEmailMessageList.rawValue, sender: self)
                }
            )
            return
        }
        if !messageLoaded {
            loadEmailMessage(emailMessage, emailAddress: emailAddress)
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

    // MARK: - Operations

    func readEmailMessage(
        messageId: String,
        success: @escaping GetEmailMessageSuccessCompletion,
        failure: @escaping GetEmailMessageErrorCompletion
    ) {
        emailClient.getEmailMessageRFC822DataWithId(messageId) { result in
            switch result {
            case let .success(output):
                success(output)
            case let .failure(error):
                failure(error)
            }
        }
    }

    // MARK: - Helpers: Configuration

    func configureNavigationBar() {
        let arrowImage = UIImage(systemName: "arrowshape.turn.up.left")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: arrowImage, style: .plain, target: self, action: #selector(replyToMessage))
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "replyButton"
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

    // MARK: - Helpers

    /// Firstly, attempts to load the email message via a remote call.
    ///
    /// On any failure, a "Failed to get Email Message" UIAlert message will be presented to the user.
    func loadEmailMessage(_ message: EmailMessage, emailAddress: EmailAddress) {
        presentCancellableActivityAlert(message: "Loading", delegate: self) {
            self.readEmailMessage(
                messageId: message.id,
                success: { [weak self] rfc822Data in
                    guard let weakSelf = self else { return }
                    let parsedMessage: BasicRFC822Message
                    do {
                        parsedMessage = try RFC822Util.fromPlainText(rfc822Data)
                    } catch {
                        DispatchQueue.main.async {
                            weakSelf.presentErrorAlert(message: "Failed load email message", error: error) { _ in
                                self?.performSegue(withIdentifier: Segue.returnToEmailMessageList.rawValue, sender: self)
                            }
                        }
                        return
                    }
                    let body = parsedMessage.body
                    DispatchQueue.main.async {
                        let toLabels: [UILabel] = message.to.map {
                            let label = UILabel()
                            label.font = UIFont.systemFont(ofSize: 14.0)
                            label.text = $0
                            label.adjustsFontSizeToFitWidth = true
                            label.minimumScaleFactor = 0.7
                            return label
                        }
                        let ccLabels: [UILabel] = message.cc.map {
                            let label = UILabel()
                            label.font = UIFont.systemFont(ofSize: 14.0)
                            label.text = $0
                            label.adjustsFontSizeToFitWidth = true
                            label.minimumScaleFactor = 0.7
                            return label
                        }
                        weakSelf.fromLabel.text = message.from.first
                        toLabels.forEach {
                            weakSelf.toMessageStackView.addArrangedSubview($0)
                        }
                        ccLabels.forEach {
                            weakSelf.ccMessageStackView.addArrangedSubview($0)
                        }
                        weakSelf.ccMessageStackView.isHidden = weakSelf.ccMessageStackView.arrangedSubviews.isEmpty
                        weakSelf.dateLabel.date = message.created
                        weakSelf.subjectLabel.text = message.subject
                        weakSelf.bodyLabel.text = body
                        weakSelf.messageLoaded = true
                        weakSelf.dismissActivityAlert()
                    }
                },
                failure: { [weak self] error in
                    guard let weakSelf = self else { return }
                    DispatchQueue.main.async {
                        weakSelf.dismissActivityAlert()
                        weakSelf.presentErrorAlert(message: "Failed to get Email Message", error: error)
                    }
                }
            )
        }
    }

    func constructReplyInput() -> SendEmailInputData? {
        var replyTo = ""
        if !emailMessage.from.isEmpty {
            replyTo = emailMessage.from.joined(separator: ", ")
        }
        var replyCc = ""
        if !emailMessage.cc.isEmpty {
            replyCc = emailMessage.cc.joined(separator: ", ")
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
        return SendEmailInputData(to: replyTo, cc: replyCc, subject: replySubject, body: replyBody)
    }

    // MARK: - Conformance: ActivityAlertViewControllerDelegate

    func didTapAlertCancelButton() {
        dismissActivityAlert {
            self.navigationController?.popViewController(animated: true)
        }
    }

}
