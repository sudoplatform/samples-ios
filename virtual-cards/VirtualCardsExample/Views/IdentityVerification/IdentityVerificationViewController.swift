//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoIdentityVerification

class IdentityVerificationViewController: UIViewController,
    UITableViewDataSource,
    UITableViewDelegate,
    InputFormCellDelegate,
    LearnMoreViewDelegate,
    UITextFieldDelegate {

    // MARK: - Outlets

    @IBOutlet var tableView: UITableView!
    @IBOutlet var tableFooterView: UIView!

    @IBOutlet var statusLabel: UILabel!

    @IBOutlet var learnMoreView: LearnMoreView!

    // MARK: - Supplementary

    enum VerificationStatus: String {
        case verified = "Verified"
        case unverified = "Not verified"
        case unknown = "Unknown"
    }

    enum InputField: Int, CaseIterable {
        case firstName
        case lastName
        case address
        case unitNumber
        case zip
        case country
        case dateOfBirth

        var isOptional: Bool {
            switch self {
            case .unitNumber:
                return true
            default:
                return false
            }
        }

        var label: String {
            switch self {
            case .firstName:
                return "First Name"
            case .lastName:
                return "Last Name"
            case .address:
                return "Adress"
            case .unitNumber:
                return "Unit #"
            case .zip:
                return "ZIP"
            case .country:
                return "Country"
            case .dateOfBirth:
                return "Date of Birth"
            }
        }

        var placeholder: String {
            if isOptional {
                return "Enter \(label) (Optional"
            } else {
                return "Enter \(label)"
            }
        }

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

    let inputFields: [InputField] = InputField.allCases

    var formData: [InputField: String] = {
        return InputField.allCases.reduce([:], { accumulator, field in
            var accumulator = accumulator
            accumulator[field] = field.defaultText
            return accumulator
        })
    }()

    // MARK: - Properties: Computed

    var verificationClient: SudoIdentityVerificationClient {
        return AppDelegate.dependencies.identityVerificationClient
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureTableView()
        configureLearnMoreView()
        setVerifyButtonEnabled(false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startListeningForKeyboardNotifications()
        fetchVerificationStatus()
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

    @objc func didTapVerify() {
        verifyUser()
    }

    // MARK: - Operations

    func verifyUser() {
        view.endEditing(true)
        guard validateFormData() else {
            presentErrorAlert(message: "Please ensure all fields are filled out")
            return
        }
        setVerifyButtonEnabled(false)

        presentActivityAlert(message: "Verifying identity")

        var address: String = formData[.address] ?? ""
        if let unitNumber = formData[.unitNumber], !unitNumber.isEmpty {
            address = "\(address) \(unitNumber)"
        }
        verificationClient.verifyIdentity(
            firstName: formData[.firstName] ?? "",
            lastName: formData[.lastName] ?? "",
            address: address,
            city: nil,
            state: nil,
            postalCode: formData[.zip] ?? "",
            country: formData[.country] ?? "",
            dateOfBirth: formData[.dateOfBirth] ?? ""
        ) { result in
            DispatchQueue.main.async {
                self.dismissActivityAlert {
                    self.setVerifyButtonEnabled(true)
                    switch result {
                    case .success(let verifiedIdentity):
                        if verifiedIdentity.verified {
                            self.presentAlert(title: "Verification complete", message: "Identity verified")
                            self.statusLabel.text = VerificationStatus.verified.rawValue
                        } else {
                            self.presentAlert(title: "Verification complete", message: "Identity not verified")
                            self.statusLabel.text = VerificationStatus.unverified.rawValue
                        }
                    case .failure(let cause):
                        self.presentErrorAlert(message: "Failed to verify identity", error: cause)
                    }
                }
            }
        }
    }

    /// Lookup the verification status of the registered user
    func fetchVerificationStatus() {
        // Once we know we're verified we don't have to check again
        if self.statusLabel?.text == VerificationStatus.verified.rawValue {
            return
        }

        presentActivityAlert(message: "Checking status")
        verificationClient.checkIdentityVerification(option: QueryOption.remoteOnly) { result in
            // dismiss activity alert
            DispatchQueue.main.async {
                self.setVerifyButtonEnabled(true)
                self.dismissActivityAlert {
                    switch result {
                    case .success(let verifiedIdentity):
                        if verifiedIdentity.verified {
                            self.statusLabel.text = VerificationStatus.verified.rawValue
                        } else {
                            self.statusLabel.text = VerificationStatus.unverified.rawValue
                        }
                    case .failure:
                        self.statusLabel.text = VerificationStatus.unknown.rawValue
                    }
                }
            }
        }
    }

    // MARK: - Helpers: Configuration

    func configureNavigationBar() {
        let verifyBarButton = UIBarButtonItem(title: "Verify", style: UIBarButtonItem.Style.plain, target: self, action: #selector(didTapVerify))
        navigationItem.rightBarButtonItem = verifyBarButton
    }

    func configureTableView() {
        let inputFormTableViewCellNib = UINib(nibName: "InputFormTableViewCell", bundle: .main)
        tableView.register(inputFormTableViewCellNib, forCellReuseIdentifier: "inputFormCell")
        tableView.tableFooterView = UIView()
        tableView.tableFooterView?.backgroundColor = .systemGray5
        tableView.tableFooterView?.addSubview(tableFooterView)
    }

    func configureLearnMoreView() {
        learnMoreView.label.text = "Secure identity verification is required in order ensure legitimate usage of the Sudo Platform virtual cards service.\n\n"
            + "Identity verification needs to be performed successfully once for each user.\n\n"
            + "The default identity information in this form will verify successfully in the sandbox environment."
        learnMoreView.delegate = self
    }

    // MARK: - Helpers

    func setVerifyButtonEnabled(_ isEnabled: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = isEnabled
    }

    /// Validate that all fields that require a value have one
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
