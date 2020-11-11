//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoEmail

class SendEmailMessageViewController: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource, HeaderCellDelegate, BodyCellDelegate {

    // MARK: - Outlets

    @IBOutlet var tableView: UITableView!

    // MARK: - Supplementary

    /// Typealias for a successful response call to `SudoEmailClient.sendEmailMessage(withRFC822Data:senderEmailAddress:completion:)`.
    typealias SendEmailMessageSuccessCompletion = (String) -> Void

    /// Typealias for a error response call to `SudoEmailClient.sendEmailMessage(withRFC822Data:senderEmailAddress:completion:)`.
    typealias SendEmailMessageErrorCompletion = (Error) -> Void

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

    /// Address of a `EmailAddress` that was selected from a previous view. Used to send a message.
    var emailAddress: EmailAddress!

    /// save the pre-populated information for a reply
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

    // MARK: - Properties: Computed

    /// Email client used to get and create email addresses.
    var emailClient: SudoEmailClient = AppDelegate.dependencies.emailClient

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureNavigationBar()
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard emailAddress?.emailAddress != nil else {
            presentErrorAlert(message: "An error has occurred: no email address found") { _ in
                self.performSegue(withIdentifier: Segue.returnToEmailMessageList.rawValue, sender: self)
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
        let message = BasicRFC822Message(
            from: from,
            to: addressesToArray(to),
            cc: addressesToArray(cc),
            bcc: addressesToArray(bcc),
            subject: subject,
            body: body
        )

        guard let data = RFC822Util.fromBasicRFC822(message) else {
            presentErrorAlert(message: "Unable to marshall email message data")
            return
        }
        self.sendEmailMessage(data, emailAddressId: emailAddressId)
    }

    // MARK: - Utilities

    func sendEmailMessage(_ data: Data, emailAddressId: String) {
        presentActivityAlert(message: "Sending Email Message")
        self.emailClient.sendEmailMessage(withRFC822Data: data, emailAddressId: emailAddressId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.dismissActivityAlert {
                        self?.performSegue(withIdentifier: Segue.returnToEmailMessageList.rawValue, sender: self)
                    }
                case let .failure(error):
                    self?.dismissActivityAlert {
                        self?.presentErrorAlert(message: "Failed to send email message", error: error)
                    }
                }
            }
        }
    }

    func validateEmailAddressList(addresses: String) -> Bool {
        let addresses = addressesToArray(addresses)
        for address in addresses {
            if !validateEmail(address) {
                return false
            }
        }
        return true
    }

    func addressesToArray(_ addresses: String) -> [String] {
        var result: [String] = []
        let split = addresses.split(separator: ",")
        for address in split {
            result.append(address.trimmingCharacters(in: .whitespacesAndNewlines))
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

    // MARK: - Helpers: Configuration

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
        let sendBarButton = UIBarButtonItem(image: paperPlaneImage, style: .plain, target: self, action: #selector(didTapSendEmailButton))
        navigationItem.rightBarButtonItem = sendBarButton
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
        assert(indexPath.row <= 4)
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

    // MARK: - Conformance: InputFormCellDelegate

    func headerCell(_ cell: HeaderTableViewCell, didUpdateInput input: String?) {
        guard let indexPath = tableView.indexPath(for: cell), let field = InputField(rawValue: indexPath.row) else {
            return
        }
        guard let input = cell.textField.text, !input.isEmpty else {
            formData[field] = nil
            return
        }
        formData[field] = input
    }

    func bodyCell(_ cell: BodyTableViewCell, didUpdateInput input: String?) {
        tableView.beginUpdates()
        formData[.body] = input
        tableView.endUpdates()
    }
}
