//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoIdentityVerification

/// This View Controller presents a form so that a user can perform Secure ID Verification.
///
/// - Links From:
///     - `MainMenuViewController`: A user chooses the "Secure ID Verification" option from the main menu table view which will show this view allowing the user
///         to perform Secure ID Verification.
class IdentityVerificationViewController: UIViewController,
    UITableViewDataSource,
    UITableViewDelegate,
    InputFormCellDelegate,
    LearnMoreViewDelegate,
    UITextFieldDelegate {

    // MARK: - Outlets

    /// Table view that lists the input fields for the form.
    @IBOutlet var tableView: UITableView!

    /// Shows supplementary information to the input form, such as the status and  "Learn more" view.
    @IBOutlet var tableFooterView: UIView!

    /// Label that shows verification status.
    @IBOutlet var statusLabel: UILabel!

    /// View appearing at the end of the content providing learn more labels and buttons.
    @IBOutlet var learnMoreView: LearnMoreView!

    // MARK: - Supplementary

    /// Various types of statuses.
    enum VerificationStatus: String {
        case verified = "Verified"
        case unverified = "Not verified"
        case unknown = "Unknown"
    }

    /// Input fields shown on the form.
    enum InputField: Int, CaseIterable {
        /// First name associated with the user.
        case firstName
        /// Last name associated with the user.
        case lastName
        /// Address associated with the user.
        case address
        /// Unit number of the address associated with the user.
        case unitNumber
        /// Zip code of the address associated with the user.
        case zip
        /// Country of the address associated with the user.
        case country
        /// Date of birth associated with the user.
        case dateOfBirth

        /// Returns true if the field is an optional input field.
        var isOptional: Bool {
            switch self {
            case .unitNumber:
                return true
            default:
                return false
            }
        }

        /// Label of the field shown to the user.
        var label: String {
            switch self {
            case .firstName:
                return "First Name"
            case .lastName:
                return "Last Name"
            case .address:
                return "Address"
            case .unitNumber:
                return "Unit #"
            case .zip:
                return "Zip"
            case .country:
                return "Country"
            case .dateOfBirth:
                return "Date of Birth"
            }
        }

        /// Placeholder of the field.
        var placeholder: String {
            if isOptional {
                return "Enter \(label) (Optional)"
            } else {
                return "Enter \(label)"
            }
        }

        /// Default text populated for the field.
        ///
        /// Optional fields are not populated by default.
        var defaultText: String? {
            guard !isOptional else {
                return nil
            }
            switch self {
            case .firstName:
                return "John"
            case .lastName:
                return "Smith"
            case .address:
                return "222333 Peachtree Place"
            case .zip:
                return "30318"
            case .country:
                return "USA"
            case .dateOfBirth:
                return "1975-02-28"
            default:
                return nil
            }
        }
    }

    // MARK: - Properties

    /// The frame of the visible keyboard. This will be updated alongside show/hide notifications.
    var keyboardFrame: CGRect = .zero

    /// Array of input fields used on the view.
    let inputFields: [InputField] = InputField.allCases

    /// Inputted form data. Initialized with default data.
    var formData: [InputField: String] = {
        return InputField.allCases.reduce([:], { accumulator, field in
            var accumulator = accumulator
            accumulator[field] = field.defaultText
            return accumulator
        })
    }()

    // MARK: - Properties: Computed

    /// Sudo identity verification client used to verify identity.
    var verificationClient: SudoIdentityVerificationClient {
        return AppDelegate.dependencies.identityVerificationClient
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureTableView()
        configureLearnMoreView()

        Task {
            await setVerifyButtonEnabled(false)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startListeningForKeyboardNotifications()

        // Once we know we're verified we don't have to check again
        if self.statusLabel?.text != VerificationStatus.verified.rawValue {
            Task(priority: .medium) {
                await self.fetchVerificationStatus()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningForKeyboardNotifications()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Note: This ensures the table footer height matches the custom outlet assigned in the xib file
        tableView.tableFooterView?.frame.size.height = tableFooterView.frame.height
    }

    // MARK: - Actions

    /// Action associated with tapping the "Verify" button on the navigation bar.
    ///
    /// This action will initiate the sequence of validating inputs and verify identity via the `virtualCardsClient`.
    @objc func didTapVerify() {
        Task(priority: .medium) {
            await self.verifyUser()
        }
    }

    // MARK: - Operations

    /// Validates and verifies identity based on the view's form inputs.
    func verifyUser() async {
        Task {
            view.endEditing(true)
        }
        guard validateFormData() else {
            Task {
                presentErrorAlert(message: "Please ensure all fields are filled out")
            }
            return
        }

        await self.setVerifyButtonEnabled(false)
        self.presentActivityAlert(message: "Verifying identity")

        var address: String = formData[.address] ?? ""
        if let unitNumber = formData[.unitNumber], !unitNumber.isEmpty {
            address = "\(address) \(unitNumber)"
        }
        do {
            let input = VerifyIdentityInput(
                firstName: formData[.firstName] ?? "",
                lastName: formData[.lastName] ?? "",
                address: address,
                city: nil,
                state: nil,
                postalCode: formData[.zip] ?? "",
                country: formData[.country] ?? "",
                dateOfBirth: formData[.dateOfBirth] ?? "")

            let verifiedIdentity = try await verificationClient.verifyIdentity(input: input)

            Task {
                self.dismissActivityAlert {
                    Task {
                        if verifiedIdentity.verified {
                            await self.presentAlert(title: "Verification complete", message: "Identity verified")
                            self.statusLabel.text = VerificationStatus.verified.rawValue
                        } else {
                            await self.presentAlert(title: "Verification complete", message: "Identity not verified")
                            self.statusLabel.text = VerificationStatus.unverified.rawValue
                        }
                    }
                }
            }
        } catch {
            Task {
                self.dismissActivityAlert {
                    Task {
                        self.presentErrorAlert(message: "Failed to verify identity", error: error)
                    }
                }
            }
        }

        await self.setVerifyButtonEnabled(true)
    }

    /// Lookup the verification status of the registered user
    func fetchVerificationStatus() async {
        await self.setVerifyButtonEnabled(false)
        presentActivityAlert(message: "Checking status")
        do {
            let verifiedIdentity = try await verificationClient.checkIdentityVerification(option: QueryOption.remoteOnly)
            // dismiss activity alert
            Task {
                if verifiedIdentity.verified {
                    self.statusLabel.text = VerificationStatus.verified.rawValue
                } else {
                    self.statusLabel.text = VerificationStatus.unverified.rawValue
                }
            }

            Task {
                self.dismissActivityAlert()
            }
        } catch {
            Task {
                self.statusLabel.text = VerificationStatus.unknown.rawValue
                self.dismissActivityAlert()
                self.presentErrorAlert(message: "Please ensure all fields are filled out", error: error)
            }
        }

        await self.setVerifyButtonEnabled(true)
    }

    // MARK: - Helpers: Configuration

    /// Configure the view's navigation bar.
    ///
    /// Sets the right bar to a verify button, which will validate the form and attempt to verify identity.
    func configureNavigationBar() {
        let verifyBarButton = UIBarButtonItem(title: "Verify", style: UIBarButtonItem.Style.plain, target: self, action: #selector(didTapVerify))
        navigationItem.rightBarButtonItem = verifyBarButton
    }

    /// Configures the table view used to display the input form information.
    ///
    /// Registers the custom `InputFormTableViewCell` for use as the `"inputFormCell"` and also sets the table footer to the non-editable
    /// information.
    func configureTableView() {
        let inputFormTableViewCellNib = UINib(nibName: "InputFormTableViewCell", bundle: .main)
        tableView.register(inputFormTableViewCellNib, forCellReuseIdentifier: "inputFormCell")
        tableView.tableFooterView = UIView()
        tableView.tableFooterView?.backgroundColor = .systemGray5
        tableView.tableFooterView?.addSubview(tableFooterView)
    }

    /// Configure the view's "Learn more" view.
    ///
    /// Sets an informative text label and "Learn more" button which when tapped will redirect the user to a Sudo Platform webpage.
    func configureLearnMoreView() {
        learnMoreView.label.text = "Secure identity verification is required in order to ensure legitimate usage of the Sudo Platform virtual "
            + "cards service.\n\n"
            + "Identity verification needs to be performed successfully once for each user.\n\n"
            + "The default identity information in this form will verify successfully in the sandbox environment."
        learnMoreView.delegate = self
    }

    // MARK: - Helpers

    /// Sets the verify button in the navigation bar to enabled/disabled.
    ///
    /// - Parameter isEnabled: If true, the navigation verify button will be enabled.
    func setVerifyButtonEnabled(_ isEnabled: Bool) async {
        self.navigationItem.rightBarButtonItem?.isEnabled = isEnabled
    }

    /// Validates the form data.
    /// - Returns: `true` if the form data is valid.
    func validateFormData() -> Bool {
        return inputFields.allSatisfy { fieldType in
            guard !fieldType.isOptional else {
                return true
            }
            guard let data = formData[fieldType] else {
                return false
            }
            return !data.isEmpty
        }
    }

    /// Get the form's input label for the current `indexPath`.
    func getInputLabel(forIndexPath indexPath: IndexPath) -> String {
        return InputField(rawValue: indexPath.row)?.label ?? "Field"
    }

    /// Get the form's input placeholder for the current `indexPath`.
    func getInputPlaceholder(forIndexPath indexPath: IndexPath) -> String {
        return InputField(rawValue: indexPath.row)?.placeholder ?? "Enter value"
    }

    /// Get the form's input text for the current `indexPath`.
    func getFormInput(forIndexPath indexPath: IndexPath) -> String? {
        guard let inputField = InputField(rawValue: indexPath.row) else {
            return nil
        }
        return formData[inputField]
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

    // MARK: - Confomance: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inputFields.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "inputFormCell") as? InputFormTableViewCell else {
            return InputFormTableViewCell()
        }
        cell.delegate = self
        cell.label.text = getInputLabel(forIndexPath: indexPath)
        cell.textField.placeholder = getInputPlaceholder(forIndexPath: indexPath)
        cell.textField.text = getFormInput(forIndexPath: indexPath)
        return cell
    }

    // MARK: - Confomance: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? InputFormTableViewCell else {
            return
        }
        cell.textField.becomeFirstResponder()
    }

    // MARK: - Conformance: InputFormCellDelegate

    func inputCell(_ cell: InputFormTableViewCell, didUpdateInput input: String?) {
        guard let indexPath = tableView.indexPath(for: cell), let field = InputField(rawValue: indexPath.row) else {
            return
        }
        guard let input = cell.textField.text, !input.isEmpty else {
            formData[field] = nil
            return
        }
        formData[field] = input
    }

    // MARK: - Conformance: UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
    }

    // MARK: - Conformance: LearnMoreView

    func didTapLearnMoreButton() {
        let docURL = URL(string: "https://docs.sudoplatform.com/guides/identity-verification")!
        UIApplication.shared.open(docURL, options: [:], completionHandler: nil)
    }

}
