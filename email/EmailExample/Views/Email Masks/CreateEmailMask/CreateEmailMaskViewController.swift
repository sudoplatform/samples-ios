//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoEmail
import SudoProfiles

/// This View Controller presents a form to provision a new `EmailMask`.
///
/// Follows the same table-based input form design as `CreateEmailAddressViewController`.
/// Supports both internal and external mask creation modes when external masks are enabled.
///
/// - Links From:
///     - `EmailMaskListViewController`: A user taps the "Create Email Mask" row.
/// - Links To:
///     - `EmailMaskListViewController`: On successful provisioning, navigates back via unwind segue.
@MainActor
class CreateEmailMaskViewController: UIViewController,
    UITableViewDataSource,
    UITableViewDelegate {

    // MARK: - Outlets

    @IBOutlet weak var tableView: UITableView!

    // MARK: - Supplementary

    enum Segue: String {
        case returnToEmailMaskList
    }

    /// Input fields for the form.
    enum InputField: Int, CaseIterable {
        /// Local part of the mask address
        case localPart
    }

    // MARK: - Properties

    /// Available mask domains retrieved from `getEmailMaskDomains()`.
    var availableDomains: [String] = []

    /// The mask domain to use (first available).
    var domain: String = ""

    /// All email addresses belonging to the user (for internal mask picker).
    var emailAddresses: [EmailAddress] = []

    /// The currently selected email address index in the picker (-1 means none selected).
    var selectedEmailIndex: Int = -1

    /// Cached configuration flag indicating whether external masks are supported.
    var externalMasksEnabled: Bool = false

    /// Tracks whether the form is currently in external mask mode.
    var isExternalMode: Bool = false

    /// Form data entered by user.
    var localPartText: String = ""

    /// External email address entered by user (external mode only).
    var externalEmailText: String = ""

    /// Timer used to debounce user input for availability check.
    var checkAddressTimer: Timer?

    /// Whether the current local part has been validated as available.
    var isAddressAvailable: Bool = false

    // MARK: - UI Elements

    /// Segmented control in the table header for switching modes.
    private var maskTypeSegmentedControl: UISegmentedControl?

    /// Picker view for selecting email address (internal mode).
    private var emailDropdownButton: UIButton?

    /// Text field for local part input.
    private var localPartTextField: UITextField?

    /// Text field for external email input (external mode).
    private var externalEmailTextField: UITextField?

    /// Validation label for external email.
    private var externalValidationLabel: UILabel?

    // MARK: - Properties: Computed

    var emailClient: SudoEmailClient {
        return AppDelegate.dependencies.emailClient
    }

    var profilesClient: SudoProfilesClient {
        return AppDelegate.dependencies.profilesClient
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureTableView()
        // Hide table content until data is loaded
        tableView.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presentActivityAlert(message: "Loading")
        Task {
            await self.loadInitialData()
        }
    }

    // MARK: - Configuration

    func configureNavigationBar() {
        title = "Create Email Mask"
        let createButton = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(didTapCreateButton))
        navigationItem.rightBarButtonItem = createButton
        setCreateButtonEnabled(false)
    }

    func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
    }

    // MARK: - Data Loading

    func loadInitialData() async {
        // Load configuration
        var configEnabled = false
        do {
            let config = try await emailClient.getConfigurationData()
            configEnabled = config.externalEmailMasksEnabled
        } catch {
            configEnabled = false
        }

        // Load mask domains
        var domains: [String] = []
        do {
            domains = try await emailClient.getEmailMaskDomains()
        } catch {
            Task {
                self.presentErrorAlert(message: "Failed to load email mask domains", error: error)
            }
            return
        }

        // Load email addresses
        var addresses: [EmailAddress] = []
        do {
            let input = ListEmailAddressesInput(limit: 50, nextToken: nil)
            let output = try await emailClient.listEmailAddresses(withInput: input)
            addresses = output.items
        } catch {
            Task {
                self.presentErrorAlert(message: "Failed to load email addresses", error: error)
            }
        }

        Task {
            self.externalMasksEnabled = configEnabled
            self.availableDomains = domains
            self.domain = domains.first ?? ""
            self.emailAddresses = addresses
            self.dismissActivityAlert()
            self.tableView.isHidden = false
            self.configureTableHeader()
            self.tableView.reloadData()
        }
    }

    // MARK: - Table Header (Segmented Control + Picker/External Field)

    func configureTableHeader() {
        updateTableHeader()
    }

    /// Rebuilds the table header view based on the current mode.
    func updateTableHeader() {
        let headerWidth = tableView.bounds.width
        let headerContainer = UIView()

        var currentY: CGFloat = 16

        // Segmented control (only if external masks enabled)
        if externalMasksEnabled {
            let control = UISegmentedControl(items: ["Internal", "External"])
            control.selectedSegmentIndex = isExternalMode ? 1 : 0
            control.addTarget(self, action: #selector(maskTypeChanged(_:)), for: .valueChanged)
            control.frame = CGRect(x: 20, y: currentY, width: headerWidth - 40, height: 32)
            headerContainer.addSubview(control)
            maskTypeSegmentedControl = control
            currentY += 32 + 16
        }

        // Local Part label
        let localPartLabel = UILabel()
        localPartLabel.text = "Local Part"
        localPartLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        localPartLabel.textColor = .secondaryLabel
        localPartLabel.frame = CGRect(x: 20, y: currentY, width: headerWidth - 40, height: 20)
        headerContainer.addSubview(localPartLabel)
        currentY += 20 + 4

        // Local Part text field
        let localPartField = UITextField()
        localPartField.placeholder = "Enter local part of the mask address"
        localPartField.borderStyle = .roundedRect
        localPartField.autocapitalizationType = .none
        localPartField.autocorrectionType = .no
        localPartField.text = localPartText
        localPartField.frame = CGRect(x: 20, y: currentY, width: headerWidth - 40, height: 36)
        localPartField.addTarget(self, action: #selector(localPartFieldChanged(_:)), for: .editingChanged)
        headerContainer.addSubview(localPartField)
        localPartTextField = localPartField
        currentY += 36 + 4

        // Mask domain info
        let domainLabel = UILabel()
        domainLabel.text = "Mask domain: @\(domain)"
        domainLabel.font = UIFont.systemFont(ofSize: 13)
        domainLabel.textColor = .secondaryLabel
        domainLabel.frame = CGRect(x: 20, y: currentY, width: headerWidth - 40, height: 18)
        headerContainer.addSubview(domainLabel)
        currentY += 18 + 16

        if isExternalMode {
            // External email label
            let extLabel = UILabel()
            extLabel.text = "External email address:"
            extLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            extLabel.textColor = .secondaryLabel
            extLabel.frame = CGRect(x: 20, y: currentY, width: headerWidth - 40, height: 20)
            headerContainer.addSubview(extLabel)
            currentY += 20 + 4

            // External email text field
            let extTextField = UITextField()
            extTextField.placeholder = "Enter your external email address"
            extTextField.borderStyle = .roundedRect
            extTextField.keyboardType = .emailAddress
            extTextField.autocapitalizationType = .none
            extTextField.autocorrectionType = .no
            extTextField.text = externalEmailText
            extTextField.frame = CGRect(x: 20, y: currentY, width: headerWidth - 40, height: 36)
            extTextField.addTarget(self, action: #selector(externalEmailChanged(_:)), for: .editingChanged)
            headerContainer.addSubview(extTextField)
            externalEmailTextField = extTextField
            currentY += 36 + 4

            // Validation label
            let validationLabel = UILabel()
            validationLabel.font = UIFont.systemFont(ofSize: 12)
            validationLabel.textColor = .systemRed
            validationLabel.text = ""
            validationLabel.frame = CGRect(x: 20, y: currentY, width: headerWidth - 40, height: 16)
            headerContainer.addSubview(validationLabel)
            externalValidationLabel = validationLabel
            currentY += 16 + 12
        } else {
            // "Associate with email:" label
            let pickerLabel = UILabel()
            pickerLabel.text = "Associate with email:"
            pickerLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            pickerLabel.textColor = .secondaryLabel
            pickerLabel.frame = CGRect(x: 20, y: currentY, width: headerWidth - 40, height: 20)
            headerContainer.addSubview(pickerLabel)
            currentY += 20 + 8

            // Dropdown-style button for selecting email address
            let selectedTitle: String
            if emailAddresses.isEmpty {
                selectedTitle = "No email addresses available"
            } else if selectedEmailIndex < 0 || selectedEmailIndex >= emailAddresses.count {
                selectedTitle = "Select an email address"
            } else {
                selectedTitle = emailAddresses[selectedEmailIndex].emailAddress
            }

            let dropdownButton = UIButton(type: .system)
            dropdownButton.setTitle(selectedTitle, for: .normal)
            dropdownButton.contentHorizontalAlignment = .leading
            dropdownButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            dropdownButton.titleLabel?.lineBreakMode = .byTruncatingTail
            if selectedEmailIndex < 0 {
                dropdownButton.setTitleColor(.placeholderText, for: .normal)
            }
            dropdownButton.layer.borderColor = UIColor.systemGray4.cgColor
            dropdownButton.layer.borderWidth = 1.0
            dropdownButton.layer.cornerRadius = 8
            dropdownButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 36)
            dropdownButton.frame = CGRect(x: 20, y: currentY, width: headerWidth - 40, height: 44)
            dropdownButton.addTarget(self, action: #selector(didTapEmailDropdown), for: .touchUpInside)
            dropdownButton.isEnabled = !emailAddresses.isEmpty
            headerContainer.addSubview(dropdownButton)
            emailDropdownButton = dropdownButton

            // Chevron indicator
            let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
            chevron.tintColor = .systemGray
            chevron.frame = CGRect(x: headerWidth - 52, y: currentY + 14, width: 16, height: 16)
            chevron.contentMode = .scaleAspectFit
            headerContainer.addSubview(chevron)

            currentY += 44 + 12
        }

        headerContainer.frame = CGRect(x: 0, y: 0, width: headerWidth, height: currentY)
        tableView.tableHeaderView = headerContainer
    }

    // MARK: - Local Part Input

    @objc func localPartFieldChanged(_ sender: UITextField) {
        checkAddressTimer?.invalidate()
        isAddressAvailable = false
        setCreateButtonEnabled(false)
        sender.textColor = .label

        guard let input = sender.text, !input.isEmpty else {
            localPartText = ""
            return
        }

        localPartText = input

        // Debounce the availability check (1 second)
        checkAddressTimer = Timer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(didFireCheckAddressTimer),
            userInfo: nil,
            repeats: false
        )
        RunLoop.main.add(checkAddressTimer!, forMode: .common)
    }

    // MARK: - Email Dropdown

    @objc func didTapEmailDropdown() {
        let alert = UIAlertController(title: "Select Email Address", message: nil, preferredStyle: .actionSheet)

        for (index, address) in emailAddresses.enumerated() {
            let action = UIAlertAction(title: address.emailAddress, style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.selectedEmailIndex = index
                self.emailDropdownButton?.setTitle(address.emailAddress, for: .normal)
                self.emailDropdownButton?.setTitleColor(nil, for: .normal)
                self.updateCreateButtonState()
            }
            // Mark the currently selected one
            if index == selectedEmailIndex {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = emailDropdownButton
            popover.sourceRect = emailDropdownButton?.bounds ?? .zero
            popover.permittedArrowDirections = .any
        }

        present(alert, animated: true)
    }

    // MARK: - Mode Switching

    @objc func maskTypeChanged(_ sender: UISegmentedControl) {
        guard let segment = MaskTypeSegment(rawValue: sender.selectedSegmentIndex) else { return }

        switch segment {
        case .internal:
            isExternalMode = false
        case .external:
            isExternalMode = true
        }

        // Rebuild the header to reflect the new mode with correct sizing
        updateTableHeader()
        updateCreateButtonState()
    }

    // MARK: - Availability Check

    /// Checks if the entered local part is available as a mask address.
    @objc func didFireCheckAddressTimer() {
        Task {
            await self.checkMaskAddressAvailability()
        }
    }

    func checkMaskAddressAvailability() async {
        guard !localPartText.isEmpty, !domain.isEmpty else { return }

        do {
            let input = CheckEmailAddressAvailabilityInput(localParts: [localPartText], domains: [domain])
            let validAddresses = try await emailClient.checkEmailAddressAvailability(withInput: input)

            Task {
                if validAddresses.count == 1 {
                    self.localPartTextField?.textColor = .systemGreen
                    self.isAddressAvailable = true
                } else {
                    self.localPartTextField?.textColor = .red
                    self.isAddressAvailable = false
                }
                self.updateCreateButtonState()
            }
        } catch {
            Task {
                self.isAddressAvailable = false
                self.updateCreateButtonState()
            }
        }
    }

    // MARK: - Validation

    func updateCreateButtonState() {
        var canCreate = isAddressAvailable && !localPartText.isEmpty

        if isExternalMode {
            let trimmed = externalEmailText.trimmingCharacters(in: .whitespaces)
            canCreate = canCreate && EmailValidation.isValidFormat(trimmed)
        } else {
            canCreate = canCreate && selectedEmailIndex >= 0 && selectedEmailIndex < emailAddresses.count
        }

        setCreateButtonEnabled(canCreate)
    }

    func setCreateButtonEnabled(_ enabled: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = enabled
    }

    @objc func externalEmailChanged(_ sender: UITextField) {
        externalEmailText = sender.text ?? ""
        let trimmed = externalEmailText.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty {
            externalValidationLabel?.text = "Email address is required"
            externalValidationLabel?.isHidden = false
        } else if !EmailValidation.isValidFormat(trimmed) {
            externalValidationLabel?.text = "Invalid email format"
            externalValidationLabel?.isHidden = false
        } else {
            externalValidationLabel?.text = ""
            externalValidationLabel?.isHidden = true
        }

        updateCreateButtonState()
    }

    // MARK: - Actions

    @objc func didTapCreateButton() {
        if isExternalMode {
            createExternalMask()
        } else {
            createInternalMask()
        }
    }

    // MARK: - Internal Mask Provisioning

    private func createInternalMask() {
        guard !localPartText.isEmpty else {
            presentErrorAlert(message: "Please enter a local part")
            return
        }
        guard selectedEmailIndex < emailAddresses.count else {
            presentErrorAlert(message: "Please select an email address")
            return
        }

        let selectedEmail = emailAddresses[selectedEmailIndex]
        let maskAddress = "\(localPartText)@\(domain)"
        let sudoId = selectedEmail.owners.first?.id ?? ""

        view.endEditing(true)
        setCreateButtonEnabled(false)
        presentActivityAlert(message: "Provisioning Email Mask")

        Task {
            do {
                let ownershipProof = try await self.profilesClient.getOwnershipProof(sudoId: sudoId, audience: "sudoplatform.email.email-address")
                let input = ProvisionEmailMaskInput(
                    maskAddress: maskAddress,
                    realAddress: selectedEmail.emailAddress,
                    ownershipProofToken: ownershipProof
                )
                _ = try await self.emailClient.provisionEmailMask(withInput: input)
                Task {
                    self.dismissActivityAlert {
                        self.performSegue(withIdentifier: Segue.returnToEmailMaskList.rawValue, sender: self)
                    }
                }
            } catch {
                Task {
                    self.dismissActivityAlert {
                        self.presentErrorAlert(message: "Failed to provision email mask", error: error)
                        self.setCreateButtonEnabled(true)
                    }
                }
            }
        }
    }

    // MARK: - External Mask Provisioning

    private func createExternalMask() {
        guard !localPartText.isEmpty else {
            presentErrorAlert(message: "Please enter a local part for the mask address")
            return
        }

        let realAddress = externalEmailText.trimmingCharacters(in: .whitespaces)
        guard !realAddress.isEmpty, EmailValidation.isValidFormat(realAddress) else {
            presentErrorAlert(message: "Please enter a valid external email address")
            return
        }

        // Use first available email's sudo for ownership proof
        guard let firstEmail = emailAddresses.first, let sudoId = firstEmail.owners.first?.id else {
            presentErrorAlert(message: "No email addresses available to obtain ownership proof")
            return
        }

        let maskAddress = "\(localPartText)@\(domain)"

        view.endEditing(true)
        setCreateButtonEnabled(false)
        presentActivityAlert(message: "Provisioning External Email Mask")

        Task {
            do {
                let ownershipProof = try await self.profilesClient.getOwnershipProof(sudoId: sudoId, audience: "sudoplatform.email.email-address")
                let input = ProvisionEmailMaskInput(
                    maskAddress: maskAddress,
                    realAddress: realAddress,
                    ownershipProofToken: ownershipProof
                )
                _ = try await self.emailClient.provisionEmailMask(withInput: input)
                Task {
                    self.dismissActivityAlert {
                        self.performSegue(withIdentifier: Segue.returnToEmailMaskList.rawValue, sender: self)
                    }
                }
            } catch {
                Task {
                    self.dismissActivityAlert {
                        self.presentErrorAlert(message: "Failed to provision external email mask", error: error)
                        self.setCreateButtonEnabled(true)
                    }
                }
            }
        }
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
