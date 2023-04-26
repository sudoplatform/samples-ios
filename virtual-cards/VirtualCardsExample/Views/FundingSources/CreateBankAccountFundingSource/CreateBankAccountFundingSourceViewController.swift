//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import LinkKit
import SudoVirtualCards
import WebKit

/// This View Controller presents a form so that a user can create a Checkout bank account based `FundingSource`.
///
/// - Links From:
///     - `CreateFundingSourceMenuViewController`: A user taps the "Add Checkout Bank Account" button.
/// - Links To:
///     - `FundingSourceListViewController`: If a user successfully creates a funding source, they will be returned to this form.
class CreateBankAccountFundingSourceViewController: UIViewController {

    // MARK: - Outlets

    /// Button used to launch the Plaid Link Flow.
    @IBOutlet var launchPlaidLinkButton: UIButton!

    /// Label used display information regarding the financial instiution name.
    @IBOutlet var institutionLabel: UILabel!

    /// Label used to display the bank account type information.
    @IBOutlet var accountTypeLabel: UILabel!

    /// Label used to display the name of the bank account.
    @IBOutlet var accountNameLabel: UILabel!

    /// Label used to display the last four digits of the bank account number.
    @IBOutlet var accountNumberEndingLabel: UILabel!

    /// View containing bank account information content.
    @IBOutlet var bankAccountInformationView: UIStackView!

    @IBOutlet var seperatorView: UIView!

    /// Web view containing the agreement text.
    @IBOutlet var agreementTextWebView: WKWebView!

    /// Check box used to indicate whether the user has accepted the agreement.
    @IBOutlet var checkBox: UIButton!

    /// Text view containing an a prompt to the user to accept the agreement.
    @IBOutlet var checkBoxTextView: UITextView!

    // MARK: - Supplementary

    /// Segues that are performed in `CreateBankAccountFundingSourceViewController`.
    enum Segue: String {
        /// Used to navigate back to the `FundingSourceListViewController`.
        case returnToFundingSourceList
    }

    // MARK: - Properties

    /// A `ProvisionalFundingSource` used to complete the funding source creation.
    var provisionalFundingSource: ProvisionalFundingSource!

    /// The `AuthorizationText` required for presentation to the user.
    var authorizationText: [AuthorizationText] = []

    var linkHandler: Handler?

    /// The `LinkSuccess` result from the Plaid Link Flow.
    var linkSuccess: LinkSuccess!

    /// Boolean flag indicating whether the check box has been checked or not.
    var checkBoxChecked = false

    // MARK: - Properties: Computed

    /// Virtual cards client used to get and create funding sources.
    var virtualCardsClient: SudoVirtualCardsClient {
        return AppDelegate.dependencies.virtualCardsClient
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        definesPresentationContext = true
        configureNavigationBar()
        setNavigationItemsEnabled(false)
        hideAuthorizationView(true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // MARK: - Actions

    /// Action associated with tapping the "Launch Plaid Link" button.
    ///
    /// This action will initiate the Plaid Link flow.
    @IBAction func didTapPlaidLinkButton() {
        Task(priority: .medium) {
            await self.setupFundingSource()
        }
    }

    /// Action associated with tapping the agreement checkbox.
    ///
    /// This action will allow the user to begin the creation of the funding source.
    @IBAction func didTapCheckBox() {
        if !checkBoxChecked {
            navigationItem.rightBarButtonItem?.isEnabled = true
            checkBox.setBackgroundImage((UIImage(named: "checkedBox")), for: UIControl.State.normal)
            checkBoxChecked = true
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = false
            checkBox.setBackgroundImage((UIImage(named: "uncheckedBox")), for: UIControl.State.normal)
            checkBoxChecked = false
        }
    }

    /// Action associated with tapping the "Create" button on the navigation bar.
    ///
    /// This action will initiate the sequence  creating a funding source via the `virtualCardsClient`.
    @objc func didTapCreateFundingSourceButton() {
        Task(priority: .medium) {
            await self.completeFundingSource()
        }
    }

    // MARK: - Operations

    /// Initiates the setup of the bank account funding source creation flow from the `virtualCardsClient` and
    /// launches the Plaid Link flow.
    func setupFundingSource() async {
        Task {
            presentActivityAlert(message: "Launching Plaid Link")
        }
        do {
            let input = SetupFundingSourceInput(
                type: .bankAccount,
                currency: "USD",
                applicationData: ClientApplicationData(applicationName: "iosApplication")
            )
            provisionalFundingSource = try await virtualCardsClient.setupFundingSource(withInput: input)
            let provisioningData = provisionalFundingSource.provisioningData
            var linkToken: String?
            if case .checkoutBankAccount(let checkoutProvisioningData) = provisioningData {
                linkToken = checkoutProvisioningData.linkToken
                authorizationText = checkoutProvisioningData.authorizationText
            }
            guard let linkToken = linkToken else {
                throw AnyError("Failed to get link token from provisioningData")
            }
            launchPlaidLink(linkToken: linkToken)
            configureAuthorizationWebView(authorizationText: authorizationText)
            Task {
                dismissActivityAlert()
            }
        } catch {
            Task {
                dismissActivityAlert()
                presentErrorAlert(message: "Failed to create funding source", error: error)
            }
        }
    }

    /// Completes the bank account funding source creation flow from the `virtualCardsClient`.
    func completeFundingSource() async {
        Task {
            presentActivityAlert(message: "Creating funding source")
        }
        do {
            try await virtualCardsClient.createKeysIfAbsent()
            let completionData = CheckoutBankAccountCompletionDataInput(
                publicToken: linkSuccess.publicToken,
                accountId: linkSuccess.metadata.accounts[0].id,
                institutionId: linkSuccess.metadata.institution.id,
                authorizationText: authorizationText[0]
            )
            let completionDataInput = CompletionDataInput.checkoutBankAccount(completionData)
            let input = CompleteFundingSourceInput(id: provisionalFundingSource.id, completionData: completionDataInput)
            try await virtualCardsClient.completeFundingSource(withInput: input)
            Task {
                dismissActivityAlert {
                    self.performSegue(withIdentifier: Segue.returnToFundingSourceList.rawValue, sender: self)
                }
            }
        } catch {
            Task {
                dismissActivityAlert()
                presentErrorAlert(message: "Failed to create funding source", error: error)
            }
        }
    }

    /// Builds the Plaid Link Configuration based on the `linkToken` and redirects the user to the Plaid Link flow
    /// in order to select a financial institution and bank account to fund the funding source.
    ///
    /// - Parameter linkToken: Link token required to launch Plaid Link.
    func launchPlaidLink(linkToken: String) {
        var linkConfiguration = LinkTokenConfiguration(
            token: linkToken,
            onSuccess: { linkSuccess in
                self.linkSuccess = linkSuccess
                self.setItemsEnabled(false)
                self.configureBankAccountInformation(linkSuccess: linkSuccess)
                self.hideAuthorizationView(false)
            }
        )
        let result = Plaid.create(linkConfiguration)
        switch result {
          case .failure(let error):
            Task {
                presentErrorAlert(message: "Failed to create funding source", error: error)
            }
          case .success(let handler):

            handler.open(presentUsing: .viewController(self))
            linkHandler = handler
        }
    }

    // MARK: - Helpers: Configuration

    /// Configure the view's navigation bar.
    ///
    /// Sets the right bar to a create button, which will attempt to create a funding source.
    func configureNavigationBar() {
        let createBarButton = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(didTapCreateFundingSourceButton))
        navigationItem.rightBarButtonItem = createBarButton
    }

    /// Configures the web view used to hold the authorization text.
    ///
    /// - Parameter authorizationText: The authorization text containing the agreement to present to the user.
    func configureAuthorizationWebView(authorizationText: [AuthorizationText]) {
        var authorizationTextHtml = authorizationText.first(where: {$0.contentType == "text/html"})?.content
        if authorizationTextHtml == nil {
            let authorizationTextPlain = authorizationText.first(where: {$0.contentType == "text/plain"})?.content ?? ""
            authorizationTextHtml = "<p>\(authorizationTextPlain)</p>"
        }
        agreementTextWebView.loadHTMLString(authorizationTextHtml ?? "", baseURL: nil)
    }

    /// Configures the text labels used to hold the bank account information returned from the
    /// Plaid Link `LinkSuccess` result.
    ///
    /// - Parameter linkSuccess: Success result from the Plaid Link flow.
    func configureBankAccountInformation(linkSuccess: LinkSuccess) {
        institutionLabel.text = linkSuccess.metadata.institution.name
        accountTypeLabel.text = linkSuccess.metadata.accounts[0].subtype.description
        accountNameLabel.text = linkSuccess.metadata.accounts[0].name
        accountNumberEndingLabel.text = "••••\(linkSuccess.metadata.accounts[0].mask ?? "")"
    }

    // MARK: - Helpers

    /// Sets the create button in the navigation bar to enabled/disabled.
    ///
    /// - Parameter isEnabled: If true, the navigation Create button will be enabled.
    func setNavigationItemsEnabled(_ isEnabled: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = isEnabled
    }

    /// Sets buttons to enabled/disabled.
    ///
    /// - Parameter isEnabled: If true, buttons will be enabled.
    func setItemsEnabled(_ isEnabled: Bool) {
        launchPlaidLinkButton.isEnabled = isEnabled
    }

    /// Displays/Hides the authorization view containing the authorization text information.
    ///
    ///  - Parameter isHidden: if true, the authorization view will be hidden.
    func hideAuthorizationView(_ isHidden: Bool) {
        bankAccountInformationView.isHidden = isHidden
        seperatorView.isHidden = isHidden
        agreementTextWebView.isHidden = isHidden
        checkBox.isHidden = isHidden
        checkBoxTextView.isHidden = isHidden
    }
}
