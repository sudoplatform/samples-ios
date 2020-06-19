//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoVirtualCards

/// This View Controller presents a form so that a user can create a `FundingSource`.
///
/// - Links From:
///     - `FundingSourceListViewController`:  A user chooses the "Create Funding Source" option at the bottom of the table view list.
/// - Links To:
///     - `FundingSourceListViewController`: If a user successfully creates a funding source, they will be returned to this form.
class CreateFundingSourceViewController: UIViewController,
    UITableViewDelegate,
    UITableViewDataSource,
    InputFormCellDelegate,
    FundingSourceAuthorizationDelegate,
    LearnMoreViewDelegate {

    // MARK: - Outlets

    /// Table view that lists the input fields for the form.
    @IBOutlet var tableView: UITableView!

    /// Shows supplementary information to the input form, such as the "Learn more" view.
    @IBOutlet var tableFooterView: UIView!

    /// View appearing at the end of the content providing learn more labels and buttons.
    @IBOutlet var learnMoreView: LearnMoreView!

    // MARK: - Supplementary

    /// Segues that are performed in `CreateFundingSourceViewController`.
    enum Segue: String {
        /// Used to navigate back to the `FundingSourceListViewController`.
        case returnToFundingSourceList
    }

    /// Input fields shown on the form.
    enum InputField: Int, CaseIterable {
        /// Card number associated with the funding source.
        case cardNumber
        /// Expiration month associated with the funding source.
        case expirationMonth
        /// Expiration year associated with the funding source.
        case expirationYear
        /// Security code (CVC) associated with the funding source.
        case securityCode
        /// Unit number of the addess associated with the funding source.
        case unitNumber
        /// Address associated with the funding source.
        case address
        /// City of the address associated with the funding source.
        case city
        /// State of the address associated with the funding source.
        case state
        /// Zip code of the address associated with the funding source.
        case zip
        /// Country of the address associated with the funding source.
        case country

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
            case .cardNumber:
                return "Card Number"
            case .expirationMonth:
                return "Month"
            case .expirationYear:
                return "Year"
            case .securityCode:
                return "Security Code"
            case .unitNumber:
                return "Unit #"
            case .address:
                return "Address"
            case .city:
                return "City"
            case .state:
                return "State"
            case .zip:
                return "Zip"
            case .country:
                return "Country"
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
            case .cardNumber:
                return "4242424242424242"
            case .expirationMonth:
                return "10"
            case .expirationYear:
                return "2022"
            case .securityCode:
                return "123"
            case .address:
                return "222333 Peachtree Place"
            case .city:
                return "Atlanta"
            case .state:
                return "GA"
            case .zip:
                return "30318"
            case .country:
                return "US"
            default:
                return nil
            }
        }
    }

    // MARK: - Properties

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

    /// The frame of the visible keyboard. This will be updated alongside show/hide notifications.
    var keyboardFrame: CGRect = .zero

    // MARK: - Properties: Computed

    /// Virtual cards client used to get and create funding sources.
    var virtualCardsClient: SudoVirtualCardsClient {
        return AppDelegate.dependencies.virtualCardsClient
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureTableView()
        configureLearnMoreView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startListeningForKeyboardNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningForKeyboardNotifications()
    }

    override func viewDidLayoutSubviews() {
        // Note: This ensures the table footer height matches the custom outlet assigned in the xib file
        super.viewDidLayoutSubviews()
        tableView.tableFooterView?.frame.size.height = tableFooterView.frame.height
    }

    // MARK: - Actions

    /// Action associated with tapping the "Create" button on the navigation bar.
    ///
    /// This action will initiate the sequence of validating inputs and creating a funding source via the `virtualCardsClient`.
    @objc func didTapCreateFundingSourceButton() {
        createFundingSource()
    }

    // MARK: - Operations

    /// Validates and creates a funding source based on the view's form inputs.
    func createFundingSource() {
        view.endEditing(true)
        guard validateFormData() else {
            presentErrorAlert(message: "Please ensure all fields are filled out")
            return
        }
        setCreateButtonEnabled(false)
        presentActivityAlert(message: "Creating funding source")
        let input = CreditCardFundingSourceInput(
            cardNumber: formData[.cardNumber] ?? "",
            expirationMonth: Int(formData[.expirationMonth] ?? "0") ?? 0,
            expirationYear: Int(formData[.expirationYear] ?? "0") ?? 0,
            securityCode: formData[.securityCode] ?? "",
            address: formData[.address] ?? "",
            unitNumber: formData[.unitNumber],
            city: formData[.city] ?? "",
            state: formData[.state] ?? "",
            postalCode: formData[.zip] ?? "",
            country: formData[.country] ?? ""
        )
        virtualCardsClient.createFundingSource(
            withCreditCardInput: input,
            authorizationDelegate: self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.setCreateButtonEnabled(true)
                switch result {
                case .success:
                    self?.dismissActivityAlert {
                        self?.performSegue(withIdentifier: Segue.returnToFundingSourceList.rawValue, sender: self)
                    }
                case let .failure(error):
                    self?.dismissActivityAlert {
                        self?.presentErrorAlert(message: "Failed to create funding source", error: error)
                    }
                }
            }
        }
    }

    // MARK: - Helpers: Configuration

    /// Configure the view's navigation bar.
    ///
    /// Sets the right bar to a create button, which will validate the form and attempt to create a funding source.
    func configureNavigationBar() {
        let createBarButton = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(didTapCreateFundingSourceButton))
        navigationItem.rightBarButtonItem = createBarButton
    }

    /// Configures the table view used to display the input form information.
    ///
    /// Registers the custom `InputFormTableViewCell` for use as the `"inputFormCell"` and also sets the table footer to the non-editable
    /// information.
    func configureTableView() {
        let inputFormTableViewCellNib = UINib(nibName: "InputFormTableViewCell", bundle: .main)
        tableView.register(inputFormTableViewCellNib, forCellReuseIdentifier: "inputFormCell")
        tableFooterView.backgroundColor = .none
        tableView.tableFooterView = UIView()
        tableView.tableFooterView?.addSubview(tableFooterView)
    }

    /// Configure the view's "Learn more" view.
    ///
    /// Sets an informative text label and "Learn more" button which when tapped will redirect the user to a Sudo Platform webpage.
    func configureLearnMoreView() {
        learnMoreView.delegate = self
        learnMoreView.label.text = "A Funding source is required to link a real credit or debit card to a virtual card. This funding source is used to fund a"
            + " transaction performed on the virtual card."
    }

    // MARK: - Helpers

    /// Sets the create button in the navigation bar to enabled/disabled.
    ///
    /// - Parameter isEnabled: If true, the navigation Create button will be enabled.
    func setCreateButtonEnabled(_ isEnabled: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = isEnabled
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

    // MARK: - Conformance: UITableViewDataSource

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

    // MARK: - Conformance: UITableViewDelegate

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

    // MARK: - Conformance: FundingSourceServiceAuthorizationDelegate

    let returnURL: String? = "virtualcardsexample://fundingsource/authorization"

    func fundingSourceAuthorizationPresentingViewController() -> UIViewController {
        return self
    }

    // MARK: - Conformance: LearnMoreViewDelegate

    func didTapLearnMoreButton() {
        guard let docURL = URL(string: "https://docs.sudoplatform.com/guides/virtual-cards/manage-funding-sources") else {
            return
        }
        UIApplication.shared.open(docURL, options: [:], completionHandler: nil)
    }
}
