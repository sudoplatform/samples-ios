//
// Copyright © 2025 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoEmail
import SudoProfiles

class CreateCustomFolderViewController: UIViewController,
    UITableViewDataSource,
    UITableViewDelegate,
    InputFormCellDelegate,
    ActivityAlertViewControllerDelegate {

    // MARK: - Outlets

    /// Table view that lists the input field for the form.
    @IBOutlet var tableView: UITableView!

    // MARK: - Supplementary

    enum Segue: String {
        case returnToEmailMessageList
    }

    /// Types of fields the user can input.
    enum InputField: Int, CaseIterable {
        /// The name of the custom folder
        case customFolderName

        /// Get the label to display on thje UI for the input.
        var label: String {
            switch self {
            case .customFolderName:
                return "Custom Folder Name"
            }
        }

        /// Returns true if the field is an optional input field.
        var isOptional: Bool {
            switch self {
            case .customFolderName:
                return false
            }
        }

        /// Get the placeholder to display on the UI for the input.
        var placeholder: String {
            switch self {
            case .customFolderName:
                return "Enter the name for the custom folder"
            }
        }
    }

    // MARK: - Properties

    /// The email address to be associated with the new custom folder
    var emailAddress: EmailAddress!

    /// The frame of the visible keyboard. This will be updated alongside show/hide notifications.
    var keyboardFrame: CGRect = .zero

    var customFolderName: String = ""

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
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startListeningForKeyboardNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningForKeyboardNotifications()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueType = Segue(rawValue: segue.identifier ?? "")
        switch segueType {
        case .returnToEmailMessageList:
            guard let returnToEmailMessages = segue.destination as? EmailMessageListViewController else {
                break
            }
            Task.detached(priority: .medium) {
                await returnToEmailMessages.refresh(folder: .string(self.customFolderName))
            }
        default:
            break
        }
    }

    // MARK: - Actions

    /// Action associated with tapping the "Create" button on the navigation item.
    ///
    /// This action will initiate the sequence of validating inputs and custom email folder via the `emailClient`.
    @objc func didTapCreateCustomFolderButton() {
        Task.detached(priority: .medium) {
            await self.createCustomEmailFolder()
        }
    }

    /// Create the custom folder on the email service
    func createCustomEmailFolder() async {
        view.endEditing(true)
        setCreateButtonEnabled(false)
        guard validateFormData() else {
            Task { @MainActor in
                presentErrorAlert(message: "Please ensure all fields are filled out")
            }
            return
        }
        self.customFolderName = formData[.customFolderName] ?? ""
        presentActivityAlert(message: "Creating custom folder")
        do {
            let createCustomEmailFolderInput = CreateCustomEmailFolderInput(
                emailAddressId: emailAddress.id,
                customFolderName: self.customFolderName
            )
            _ = try await emailClient.createCustomEmailFolder(withInput: createCustomEmailFolderInput)
            Task { @MainActor in
                self.dismissActivityAlert {
                    self.performSegue(withIdentifier: Segue.returnToEmailMessageList.rawValue, sender: self)
                }
            }
        } catch {
            self.dismissActivityAlert {
                self.setCreateButtonEnabled(true)
                self.presentErrorAlert(message: "Failed to create custom folder", error: error)
            }
        }
    }

    // MARK: - Helpers: Configuration

    /// Configures the navigation bar.
    func configureNavigationBar() {
        let createBarButton = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(didTapCreateCustomFolderButton))
        navigationItem.rightBarButtonItem = createBarButton
        setCreateButtonEnabled(true)
    }

    /// Configures the table view used to display the input form information.
    func configureTableView() {
        let inputFormTableViewCellNib = UINib(nibName: "InputFormTableViewCell", bundle: .main)
        tableView.register(inputFormTableViewCellNib, forCellReuseIdentifier: "inputFormCell")
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
    /// Returns false if the value of the form is missing, or its length is less than 1.
    func validateFormData() -> Bool {
        return InputField.allCases.allSatisfy { fieldType in
            if fieldType.isOptional {
                return true
            }
            guard let data = formData[fieldType] else {
                return false
            }
            return !data.isEmpty
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
            cell.textField.textColor = .label
            guard let indexPath = self.tableView.indexPath(for: cell), let field = InputField(rawValue: indexPath.row) else {
                return
            }
            guard let input = input, !input.isEmpty else {
                self.formData[field] = nil
                return
            }
            self.formData[field] = input
        }
    }

    // MARK: - Conformance: ActivityAlertViewControllerDelegate

    func didTapAlertCancelButton() {
        dismissActivityAlert {
            self.navigationController?.popViewController(animated: true)
        }
    }
}