//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
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

    enum Segue: String {
        case returnToEmailAddressList
    }

    /// Types of fields the user can input.
    enum InputField: Int, CaseIterable {
        /// Local part of the email address to provision
        case localPart
        /// Alias of the email address to provision
        case alias

        /// Get the label to display on the UI for the input.
        var label: String {
            switch self {
            case .localPart:
                return "Local Part"
            case .alias:
                return "Alias"
            }
        }

        /// Returns true if the field is an optional input field.
        var isOptional: Bool {
            switch self {
            case .alias:
                return true
            default:
                return false
            }
        }

        /// Get the placeholder to display on the UI for the input.
        var placeholder: String {
            if isOptional {
                return "Enter \(label) (Optional)"
            } else {
                return "Enter \(label)"
            }
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

    /// Sudo Profiles client used to get ownershipProofToken
    var sudoProfilesClient: SudoProfilesClient {
        return AppDelegate.dependencies.profilesClient
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
        presentCancellableActivityAlert(message: "Loading", delegate: self) {
            Task.detached(priority: .medium) {
                guard let domain = try await self.getSupportedEmailDomains(cachePolicy: .remoteOnly).first else {
                    await self.dismissActivityAlert {
                        Task { @MainActor in
                            self.presentErrorAlert(message: "Failed to get supported domain") {_ in
                                self.performSegue(withIdentifier: Segue.returnToEmailAddressList.rawValue, sender: self)
                            }
                        }
                    }
                    return
                }
                Task { @MainActor in
                    self.domain = domain
                    self.dismissActivityAlert()
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningForKeyboardNotifications()
    }

    // MARK: - Actions

    /// Action associated with tapping the "Create" button on the navigation item.
    ///
    /// This action will initiate the sequence of validating inputs and provisioning an email address via the `emailClient`.
    @objc func didTapCreateEmailAddressButton() {
        Task.detached(priority: .medium) {
            await self.createEmailAddress()
        }
    }

    /// Action associated with firing the debounce timer on the input of the user's localPart.
    ///
    /// This action will initiate the checking of validity of the users input with the email service.
    @objc func didFireCheckEmailAddressTimer() {
        Task.detached(priority: .medium) {
            await self.checkInputEmailAddressAvailability()
        }
    }

    // MARK: - Operations

    /// Check the input of the user for validity of the email address.
    func checkInputEmailAddressAvailability() async {
        do {
            let localPart = formData[.localPart] ?? ""
            let checkAddressInput = CheckEmailAddressAvailabilityInput(localParts: [localPart], domains: [domain])
            let validAddresses = try await emailClient.checkEmailAddressAvailability(withInput: checkAddressInput)

            let indexPath = IndexPath(item: InputField.localPart.rawValue, section: 0)
            Task { @MainActor in
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
        } catch {
            self.setCreateButtonEnabled(false)
            Task { @MainActor in
                self.presentErrorAlert(message: "Failed to check email address availability", error: error)
            }
        }
    }

    /// Create the email address on the email service.
    func createEmailAddress() async {
        view.endEditing(true)
        setCreateButtonEnabled(false)
        guard validateFormData() else {
            Task { @MainActor in
                presentErrorAlert(message: "Please ensure all fields are filled out")
            }
            return
        }
        let localPart = formData[.localPart] ?? ""
        let alias = formData[.alias]
        presentActivityAlert(message: "Creating Address")
        let address = "\(localPart)@\(domain)"
        do {
            let ownershipProofToken = try await sudoProfilesClient.getOwnershipProof(sudo: sudo, audience: "sudoplatform.email.email-address")
            let provisionAddressInput = ProvisionEmailAddressInput(
                emailAddress: address,
                ownershipProofToken: ownershipProofToken,
                alias: alias
            )
            _ = try await emailClient.provisionEmailAddress(withInput: provisionAddressInput)
            Task { @MainActor in
                self.dismissActivityAlert {
                    self.performSegue(withIdentifier: Segue.returnToEmailAddressList.rawValue, sender: self)
                }
            }
        } catch {
            self.dismissActivityAlert {
                self.setCreateButtonEnabled(true)
                self.presentErrorAlert(message: "Failed to create email address", error: error)
            }
        }
    }

    func getSupportedEmailDomains(cachePolicy: CachePolicy) async throws -> [String] {
        return try await emailClient.getSupportedEmailDomains(cachePolicy)
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
            if fieldType.isOptional {
                return true
            }
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
        Task { @MainActor in
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
