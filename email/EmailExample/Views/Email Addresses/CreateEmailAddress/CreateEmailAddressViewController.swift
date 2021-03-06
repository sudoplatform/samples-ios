//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoEmail
import SudoProfiles

class CreateEmailAddressViewController: UIViewController,
    UITableViewDataSource,
    UITableViewDelegate,
    InputFormCellDelegate,
    ActivityAlertViewControllerDelegate,
    LearnMoreViewDelegate {

    // MARK: - Outlets

    /// Table view that lists the input field for the form.
    @IBOutlet var tableView: UITableView!

    /// Shows supplementary information to the input form, such as the chosen sudo and learn more.
    @IBOutlet var tableFooterView: UIView!

    /// View appearing at the end of the content providing learn more labels and buttons.
    @IBOutlet var learnMoreView: LearnMoreView!

    @IBOutlet var sudoLabel: UILabel!

    // MARK: - Supplementary

    /// Typealias for a successful response call to `SudoEmailClient.provisionEmailAddress(_:address:sudoId:completion:)`.
    typealias ProvisionEmailAddressSuccessCompletion = (EmailAddress) -> Void

    /// Typealias for a error response call to `SudoEmailClient.provisionEmailAddresss(_:address:sudoId:completion:)`.
    typealias ProvisionEmailAddressErrorCompletion = (Error) -> Void

    /// Typealias for a successful response call to `SudoEmailClient.getSupportedEmailDomainsWithCachePolicy(_:cachePolicy:completion:)`.
    typealias GetSupportedDomainsSuccessCompletion = ([String]) -> Void

    /// Typealias for a error response call to `SudoEmailClient.getSupportedEmailDomainsWithCachePolicy(_:cachePolicy:completion:)`.
    typealias GetSupportedDomainsErrorCompletion = (Error) -> Void

    enum Segue: String {
        case returnToEmailAddressList
    }

    /// Types of fields the user can input.
    enum InputField: Int, CaseIterable {
        /// Local part of the email address to provision
        case localPart

        /// Get the label to display on the UI for the input.
        var label: String {
            switch self {
            case .localPart:
                return "Local Part"
            }
        }

        /// Get the placeholder to display on the UI for the input.
        var placeholder: String {
            return "Enter \(label)"
        }
    }

    // MARK: - Properties

    /// Label of a `Sudo` that was selected from the previous view. Used to present to the user.
    var sudoLabelText: String = ""

    /// `Sudo` that was selected from the previous view. Used to filter email addresses and provision a new email address.
    var sudo: Sudo = Sudo()

    /// Domain to provision. Retrieved on diplay of view from the email service.
    var domain: String = ""

    /// Timer used to debounce user input on local part input.
    var checkEmailAddressTimer: Timer?

    /// The frame of the visible keyboard. This will be updated alongside show/hide notifications.
    var keyboardFrame: CGRect = .zero

    // MARK: - Properties: Computed

    /// Email client used to get and create email addresses.
    var emailClient: SudoEmailClient {
        return AppDelegate.dependencies.emailClient
    }

    /// Form data entered by user. Initialized with empty strings.
    var formData: [InputField: String] = {
        return InputField.allCases.reduce([:], { accumulator, field in
            var accumulator = accumulator
            accumulator[field] = ""
            return accumulator
        })
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureLearnMoreView()
        configureFooterValues()
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startListeningForKeyboardNotifications()
        let failureCompletion: (Error?) -> Void = { [weak self] error in
            DispatchQueue.main.async {
                self?.dismissActivityAlert {
                    self?.presentErrorAlert(message: "Failed to get supported domain") { _ in
                        self?.performSegue(withIdentifier: Segue.returnToEmailAddressList.rawValue, sender: self)
                    }
                }
            }
        }
        presentCancellableActivityAlert(message: "Loading", delegate: self) {
            self.getSupportedEmailDomains(
                cachePolicy: .remoteOnly,
                success: { [weak self] domains in
                    guard let domain = domains.first else {
                        failureCompletion(nil)
                        return
                    }
                    self?.domain = domain
                    DispatchQueue.main.async {
                        self?.dismissActivityAlert()
                    }
                },
                failure: failureCompletion
            )
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningForKeyboardNotifications()
    }

    // MARK: - Actions

    /// Action associated with tapping the "Create" button on the navigation item.
    ///
    /// This action will initiate the sequence of validating inputs and adding a card via the `emailClient`.
    @objc func didTapCreateEmailAddressButton() {
        createEmailAddress()
    }

    /// Action associated with firing the debounce timer on the input of the user's localPart.
    ///
    /// This action will initiate the checking of validity of the users input with the email service.
    @objc func didFireCheckEmailAddressTimer() {
        checkInputEmailAddressAvailability()
    }

    // MARK: - Operations

    /// Check the input of the user for validity of the email address.
    func checkInputEmailAddressAvailability() {
        let localPart = formData[.localPart] ?? ""
        emailClient.checkEmailAddressAvailabilityWithLocalParts([localPart], domains: [domain]) { [weak self] result in
            switch result {
            case let .success(validAddresses):
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    let indexPath = IndexPath(item: InputField.localPart.rawValue, section: 0)
                    guard let cell = self.tableView.cellForRow(at: indexPath)  as? InputFormTableViewCell else {
                        return
                    }
                    guard validAddresses.count == 1 else {
                        cell.textField.textColor = .red
                        self.setCreateButtonEnabled(false)
                        return
                    }
                    cell.textField.textColor = .systemGreen
                    self.setCreateButtonEnabled(true)
                }
            case let .failure(error):
                DispatchQueue.main.async {
                    self?.setCreateButtonEnabled(false)
                    self?.presentErrorAlert(message: "Failed to check email address availability", error: error)
                }
            }
        }
    }

    /// Create the email address on the email service.
    func createEmailAddress() {
        view.endEditing(true)
        setCreateButtonEnabled(false)
        guard validateFormData() else {
            presentErrorAlert(message: "Please ensure all fields are filled out")
            return
        }
        guard let sudoId = sudo.id else {
            presentErrorAlert(message: "Sudo Id cannot be found")
            return
        }
        let localPart = formData[.localPart] ?? ""
        let failureCompletion: (Error) -> Void = { [weak self] error in
            DispatchQueue.main.async {
                self?.dismissActivityAlert {
                    self?.setCreateButtonEnabled(true)
                    self?.presentErrorAlert(message: "Failed to create email address", error: error)
                }
            }
        }
        presentActivityAlert(message: "Creating Address")
        let address = "\(localPart)@\(domain)"
        emailClient.provisionEmailAddress(address, sudoId: sudoId) { [weak self] result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self?.dismissActivityAlert {
                        self?.performSegue(withIdentifier: Segue.returnToEmailAddressList.rawValue, sender: self)
                    }
                }
            case let .failure(error):
                failureCompletion(error)
            }
        }
    }

    func getSupportedEmailDomains(
        cachePolicy: CachePolicy,
        success: @escaping GetSupportedDomainsSuccessCompletion,
        failure: @escaping GetSupportedDomainsErrorCompletion
    ) {
        emailClient.getSupportedEmailDomainsWithCachePolicy(cachePolicy) { result in
            switch result {
            case let .success(domains):
                success(domains)
            case let .failure(error):
                failure(error)
            }
        }
    }

    // MARK: - Helpers: Configuration

    /// Configures the navigation bar.
    func configureNavigationBar() {
        let createBarButton = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(didTapCreateEmailAddressButton))
        navigationItem.rightBarButtonItem = createBarButton
        setCreateButtonEnabled(false)
    }

    /// Configures the table view used to display the input form information.
    func configureTableView() {
        let inputFormTableViewCellNib = UINib(nibName: "InputFormTableViewCell", bundle: .main)
        tableView.register(inputFormTableViewCellNib, forCellReuseIdentifier: "inputFormCell")
        tableFooterView.backgroundColor = .none
        tableFooterView.translatesAutoresizingMaskIntoConstraints = true
        tableView.tableFooterView = tableFooterView
    }

    /// Configures the table footer values from the passed in `Sudo`.
    ///
    /// If a valid sudo is not found, an error will be presented to the user, which results in a segue back to the `EmailAddressListViewController`.
    func configureFooterValues() {
        guard let sudoLabelText = sudo.label, !sudoLabelText.isEmpty else {
            presentErrorAlert(
                message: "An error has occurred: no sudo label found",
                okHandler: { _ in
                    self.performSegue(withIdentifier: Segue.returnToEmailAddressList.rawValue, sender: self)
                }
            )
            return
        }
        guard let sudoId = sudo.id, !sudoId.isEmpty else {
            presentErrorAlert(
                message: "An error has occurred: no sudo id found",
                okHandler: { _ in
                    self.performSegue(withIdentifier: Segue.returnToEmailAddressList.rawValue, sender: self)
                }
            )
            return
        }
        sudoLabel.text = sudoLabelText
    }

    func configureLearnMoreView() {
        learnMoreView.delegate = self
        learnMoreView.label.text = "Addresses from different configured domains can be provisioned and used to communicate with other recipients. " +
        "The list above has been randonly generated based on the currently configured domains."
    }

    // MARK: - Helpers: Keyboard

    func startListeningForKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    func stopListeningForKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardDidShow(notification: Notification) {
        let keyboardRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        keyboardFrame = keyboardRect ?? .zero
        tableView.contentInset.bottom = (keyboardFrame.height + 12) // Height + some padding
    }

    @objc func keyboardWillHide() {
        keyboardFrame = .zero
        tableView.contentInset.bottom = 0
    }

    // MARK: - Helpers

    /// Sets the create button `isEnabled` property.
    func setCreateButtonEnabled(_ isEnabled: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = isEnabled
    }

    /// Get the form's input label for the current `indexPath`.
    func getInputLabel(forIndexPath indexPath: IndexPath) -> String {
        return InputField(rawValue: indexPath.row)?.label ?? "Field"
    }

    /// Get the form's input placeholder for the current `indexPath`.
    func getInputPlaceholder(forIndexPath indexPath: IndexPath) -> String {
        return InputField(rawValue: indexPath.row)?.placeholder ?? "Enter value"
    }

    /// Validates the form data that is input from the user.
    ///
    /// Returns false if the value of the form is missing, or its length is less than 3.
    func validateFormData() -> Bool {
        return InputField.allCases.allSatisfy { fieldType in
            guard let data = formData[fieldType] else {
                return false
            }
            return data.count > 2
        }
    }

    // MARK: - Conformance: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return InputField.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "inputFormCell", for: indexPath) as? InputFormTableViewCell else {
            NSLog("Failed to get cell")
            return InputFormTableViewCell()
        }
        cell.delegate = self
        cell.label.text = getInputLabel(forIndexPath: indexPath)
        cell.textField.placeholder = getInputPlaceholder(forIndexPath: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath)  as? InputFormTableViewCell else {
            return
        }
        cell.textField.becomeFirstResponder()
    }

    // MARK: - Conformance: InputFormCellDelegate

    func inputCell(_ cell: InputFormTableViewCell, didUpdateInput input: String?) {
        DispatchQueue.main.async {
            self.checkEmailAddressTimer?.invalidate()
            self.setCreateButtonEnabled(false)
            cell.textField.textColor = .label
            guard let indexPath = self.tableView.indexPath(for: cell), let field = InputField(rawValue: indexPath.row) else {
                return
            }
            guard let input = input, !input.isEmpty else {
                self.formData[field] = nil
                return
            }
            self.formData[field] = input
            if self.validateFormData() {
                self.checkEmailAddressTimer = Timer(
                    timeInterval: 1.0,
                    target: self,
                    selector: #selector(self.didFireCheckEmailAddressTimer),
                    userInfo: nil,
                    repeats: false
                )
                RunLoop.main.add(self.checkEmailAddressTimer!, forMode: .common)
            }
        }
    }

    // MARK: - Conformance: ActivityAlertViewControllerDelegate

    func didTapAlertCancelButton() {
        dismissActivityAlert {
            self.navigationController?.popViewController(animated: true)
        }
    }

    // MARK: - Conformance: LearnMoreViewDelegate

    func didTapLearnMoreButton() {
        guard let docURL = URL(string: "https://docs.sudoplatform.com/guides/email/manage-email-addresses") else {
            return
        }
        UIApplication.shared.open(docURL, options: [:], completionHandler: nil)
    }

}
