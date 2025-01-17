//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoProfiles
import SudoVirtualCards
import SudoNotification

/// This View Controller presents a list of `FundingSources`.
///
/// - Links From:
///     - `MainMenuViewController`: A user chooses the "Funding Sources" option from the main menu table view which will show this view with the list of
///         funding sources created. The last four digits of the funding source's card number and credit card network is used as the text for each funding
///         source.
///  - Links To:
///     - `CreateFundingSourceViewController`: If a user taps the "Create Funding Source" button, the `CreateFundingSourceViewController` will
///         be presented so the user can create a new funding source.
class FundingSourceListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Outlets

    /// The table view that lists each funding source.
    ///
    /// If no funding sources have been created before, then only the "Create Funding Source" entry will be seen. This can be tapped to create a funding source
    /// to append to the list.
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Supplementary

    /// Defaults used in `FundingSourceListViewController`.
    enum Defaults {
        /// Limit used when querying funding sources from `VirtualCardsClient`.
        static let fundingSourceLimit = 10
    }

    /// Segues that are performed in `FundingSourceListViewController`.
    enum Segue: String {
        /// Used to navigate to the `CreateFundingSourceViewController`.
        case navigateToCreateFundingSourceMenu
        /// Used to navigate to the `RefreshBankAccountFundingSourceViewController`.
        case navigateToRefreshBankAccountFundingSourceView
    }

    // MARK: - Properties

    /// A list of `FundingSources`.
    var fundingSources: [FundingSource] = []

    /// Interaction data required to refresh a bank account funding source
    var linkToken: String = ""
    var authorizationText: [AuthorizationText] = []
    var fundingSourceId: String = ""

    // MARK: - Properties: Computed

    /// Virtual cards client used to get and create funding sources.
    var virtualCardsClient: SudoVirtualCardsClient {
        return AppDelegate.dependencies.virtualCardsClient
    }
    /// Notification client used to manage notification configuration
    var notificationClient: SudoNotificationClient = AppDelegate.dependencies.notificationClient

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Task(priority: .medium) {
            await self.loadCacheFundingSourcesAndFetchRemote()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueType = Segue(rawValue: segue.identifier ?? "")
        switch segueType {
        case .navigateToRefreshBankAccountFundingSourceView:
            guard let refreshBankAccount = segue.destination as? RefreshBankAccountFundingSourceViewController else {
                break
            }
            refreshBankAccount.linkToken = linkToken
            refreshBankAccount.authorizationText = authorizationText
            refreshBankAccount.fundingSourceId = fundingSourceId

        default:
            break
        }
    }

    // MARK: - Actions

    /// Action associated with returning to this view from a segue.
    ///
    /// This action will ensure that the funding source list is up to date when returning from views - e.g. `CreateFundingSourceViewController`.
    @IBAction func returnToFundingSourceList(segue: UIStoryboardSegue) {
        Task(priority: .medium) {
            await self.loadCacheFundingSourcesAndFetchRemote()
        }
    }

    // MARK: - Operations

    /// List funding sources from the virtual cards client.
    ///
    /// - Parameters:
    ///   - cachePolicy: Cache policy used to retrieve the funding sources.
    ///   - success: Closure that executes on a successful retrieval of funding sources.
    ///   - failure: Closure that executes on an error during the retrieval of funding sources.
    func listFundingSources(
        cachePolicy: SudoVirtualCards.CachePolicy
    ) async throws -> [FundingSource] {
        return try await virtualCardsClient.listFundingSources(
            withFilter: nil,
            sortOrder: nil,
            withLimit: Defaults.fundingSourceLimit,
            nextToken: nil,
            cachePolicy: cachePolicy
        ).items
    }

    /// Cancel a funding source based on the input id.
    ///
    /// - Parameter id: The id of the funding source to cancel.
    func cancelFundingSource(id: String) async throws -> FundingSource {
        Task {
            self.presentActivityAlert(message: "Cancelling funding source")
        }

        do {
            let fundingSource = try await virtualCardsClient.cancelFundingSource(withId: id)
            Task {
                self.dismissActivityAlert()
            }

            return fundingSource
        } catch {
            Task {
                self.dismissActivityAlert()
                self.presentErrorAlert(message: "Failed to cancel funding source", error: error)
            }
            throw error
        }
    }

    /// Review a funding source based on the input id.
    ///
    /// - Parameter id: The id of the funding source to cancel.
    func reviewUnfundedFundingSource(id: String) async throws -> FundingSource {
        Task {
            self.presentActivityAlert(message: "Reviewing unfunded funding source")
        }

        do {
            let fundingSource = try await virtualCardsClient.reviewUnfundedFundingSource(withId: id)
            Task {
                self.dismissActivityAlert()
            }

            return fundingSource
        } catch {
            Task {
                self.dismissActivityAlert()
                self.presentErrorAlert(message: "Failed to review funding source", error: error)
            }
            throw error
        }
    }

    /// Refresh a funding source based on the input id.
    ///
    /// - Parameter id: The id of the funding source to refresh.
    func refreshFundingSource(id: String) async throws -> FundingSource {
        Task {
            self.presentActivityAlert(message: "Refreshing funding source")
        }
        let refreshData = CheckoutBankAccountRefreshDataInput(accountId: nil, authorizationText: nil)
        do {
            fundingSourceId = id
            let input = RefreshFundingSourceInput(
                    id: id,
                    refreshData: .checkoutBankAccount(refreshData),
                    applicationData: ClientApplicationData(applicationName: "iosApplication"),
                    language: "en-US")
            let fundingSource = try await virtualCardsClient.refreshFundingSource(withInput: input)
            Task {
                self.dismissActivityAlert()
            }
            return fundingSource
        } catch {
            // We want to catch the specific UserInteractionRequired error
            // and get the information from it to pass to the refreshBankAccountFundingSourceViewController
            // which will then jump through the plaid and authorization text interactions to complete the refresh.
            guard let sudoVirtualCardsError = error as? SudoVirtualCardsError else {
                Task {
                    self.dismissActivityAlert()
                    self.presentErrorAlert(message: "Failed to refresh funding source", error: error)
                }
                throw error
            }
            var handled = false
            if case let .fundingSourceRequiresUserInteraction(userInteractionData) = sudoVirtualCardsError {
                if case let .checkoutBankAccount(bankAccountInteractionData) = userInteractionData {
                    linkToken = bankAccountInteractionData.linkToken
                    authorizationText = bankAccountInteractionData.authorizationText

                    performSegue(withIdentifier: Segue.navigateToRefreshBankAccountFundingSourceView.rawValue, sender: self)
                    handled = true
                }
            }
            Task {
                self.dismissActivityAlert()
                if !handled {
                    self.presentErrorAlert(message: "Unexpected sudoplatform error from service", error: error)
                }
            }
            throw error
        }
    }

    // MARK: - Helpers: Configuration

    func configureNavigationBar() {
        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "Back", style: .plain, target: nil, action: nil)
    }

    /// Configures the table view used to display the navigation elements.
    func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "default")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "create")
        tableView.tableFooterView = UIView()
    }

    // MARK: - Helpers

    /// Attempts to load all funding sources from the device's cache first and then update via a remote call.
    ///
    /// On any failure, either by cache or remote call,  a "Failed to list funding sources" UIAlert message will be presented to the user.
    func loadCacheFundingSourcesAndFetchRemote() async {
        do {
            let localFundingSource = try await listFundingSources(
                cachePolicy: .cacheOnly
            )

            Task {
                self.fundingSources = localFundingSource
                self.tableView.reloadData()
            }

            let remoteFundingSource = try await listFundingSources(
                cachePolicy: .remoteOnly
            )
            var notifConfig = AppDelegate.dependencies.notificationConfiguration
            for fundingSource in remoteFundingSource {
                var fundingSourceId: String
                switch fundingSource {
                case .creditCardFundingSource(let creditCardFundingSource):
                    fundingSourceId = creditCardFundingSource.id
                case .bankAccountFundingSource(let bankAccountFundingSource):
                    fundingSourceId = bankAccountFundingSource.id
                }
                if let validConfig = notifConfig {
                    notifConfig = validConfig.setVirtualCardsNotificationsForFundingSource(fundingSourceId: fundingSourceId, enabled: true)
                }
            }

            if let finalConfig = notifConfig {
                Task.detached(priority: .medium) {
                    await self.updateNotificationConfiguration(config: finalConfig)
                }
            }

            Task {
                self.fundingSources = remoteFundingSource
                self.tableView.reloadData()
            }
        } catch {
            Task {
                self.presentErrorAlert(message: "Failed to list Funding Sources", error: error)
            }
        }
    }

    /// Formats the title which represents a funding source and is displayed on the table view cell.
    ///
    /// - Parameter fundingSource: The funding source to display.
    func getDisplayTitleForFundingSource(_ fundingSource: FundingSource) -> String {
        switch fundingSource {
        case .creditCardFundingSource(let creditCardFundingSource):
            let suffix = getSuffixForFundingSourceState(creditCardFundingSource.state, creditCardFundingSource.flags )
            return "••••\(creditCardFundingSource.last4) (\(creditCardFundingSource.cardType))\(suffix)"
        case .bankAccountFundingSource(let bankAccountFundingSource):
            var suffix = getSuffixForFundingSourceState(bankAccountFundingSource.state, bankAccountFundingSource.flags)
            suffix = getSuffixForUnfundedFundingSource(bankAccountFundingSource, suffix)
            let institutionName = (bankAccountFundingSource.institutionLogo == nil) ? "\(bankAccountFundingSource.institutionName) " : ""
            return "\(institutionName)••••\(bankAccountFundingSource.last4) (\(bankAccountFundingSource.bankAccountType))\(suffix)"
        }
    }

    private func getSuffixForFundingSourceState(_ state: FundingSourceState, _ flags: [FundingSourceFlags]) -> String {
        var suffix = ""
        switch state {
        case .inactive:
            suffix = " - Cancelled"
        default:
            break
        }
        if flags.contains(FundingSourceFlags.refresh) {
            suffix += " - Needs Refresh"
        }
        if  flags.contains(FundingSourceFlags.unfunded) {
            suffix += " - UNFUNDED"
        }
        return suffix
    }
    private func getSuffixForUnfundedFundingSource(_ fundingSource: BankAccountFundingSource, _ suffix: String) -> String {

        var internalSuffix = suffix

        if fundingSource .unfundedAmount != nil {
            let unfundedAmountDisplay = "\(Double(fundingSource.unfundedAmount!.amount) / 100.0) \(fundingSource.unfundedAmount!.currency)"
                    internalSuffix += " \(unfundedAmountDisplay)"
                }
        return internalSuffix
    }

    /// Formats the imageView which represents the logo of the credit card network or bank account institution
    /// on the table view cell.
    ///
    /// - Parameter fundingSource: The funding source containing the logo to display.
    func setFundingSourceLogo(_ fundingSource: FundingSource) -> UIImage? {
        switch fundingSource {
        case .creditCardFundingSource(let creditCardFundingSource):
            switch creditCardFundingSource.network {
            case .visa:
                return UIImage(named: "card-icon-visa")
            case .mastercard:
                return UIImage(named: "card-icon-mastercard")
            default:
                return nil
            }
        case .bankAccountFundingSource(let bankAccountFundingSource):
            if bankAccountFundingSource.institutionLogo != nil {
                guard let decodedData = Data(base64Encoded: bankAccountFundingSource.institutionLogo!.data) else {
                    return nil
                }
                return UIImage(data: decodedData)
            } else {
                return nil
            }
        }
    }

    // MARK: - Conformance: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fundingSources.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if indexPath.row == fundingSources.count {
            cell = tableView.dequeueReusableCell(withIdentifier: "create", for: indexPath)
            cell.textLabel?.text = "Create Funding Source"
            cell.textLabel?.textColor = UIColor.systemBlue
            cell.accessoryView = UIImageView(image: UIImage.init(systemName: "plus"))
            cell.semanticContentAttribute = .forceRightToLeft
        } else {
            let fundingSource = fundingSources[indexPath.row]
            cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
            cell.textLabel?.textColor = UIColor.black
            cell.textLabel?.text = getDisplayTitleForFundingSource(fundingSource)
            cell.imageView?.image = setFundingSourceLogo(fundingSource)
        }
        return cell
    }

    // MARK: - Conformance: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(indexPath.section == 0)
        if indexPath.row == fundingSources.count {
            performSegue(withIdentifier: Segue.navigateToCreateFundingSourceMenu.rawValue, sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.row != fundingSources.count {
            let fundingSource = self.fundingSources[indexPath.row]
            var canCancel = false
            var canRefresh = false
            var canReview = false
            switch fundingSource {
            case .creditCardFundingSource(let creditCardFundingSource):
                canCancel = creditCardFundingSource.state == .active
                canRefresh = creditCardFundingSource.flags.contains(FundingSourceFlags.refresh)
            case .bankAccountFundingSource(let bankAccountFundingSource):
                canRefresh = bankAccountFundingSource.flags.contains(FundingSourceFlags.refresh)
                canReview = bankAccountFundingSource.flags.contains(FundingSourceFlags.unfunded)
                canCancel = bankAccountFundingSource.state == .active && !canReview
            }
            var actions: [UIContextualAction] = []
            if canCancel {
                let cancel = UIContextualAction(style: .destructive, title: "Cancel") { _, _, completion in
                    let fundingSource = self.fundingSources[indexPath.row]

                    Task(priority: .medium) {
                        do {
                            var cancelledFundingSource: FundingSource
                            switch fundingSource {
                            case .creditCardFundingSource(let creditCardFundingSource):
                                cancelledFundingSource = try await self.cancelFundingSource(id: creditCardFundingSource.id)
                            case .bankAccountFundingSource(let bankAccountFundingSource):
                                cancelledFundingSource = try await self.cancelFundingSource(id: bankAccountFundingSource.id)
                            }
                            Task {
                                self.fundingSources.remove(at: indexPath.row)
                                self.fundingSources.insert(cancelledFundingSource, at: indexPath.row)
                                let cell = self.tableView.cellForRow(at: indexPath)
                                cell?.textLabel?.text = self.getDisplayTitleForFundingSource(cancelledFundingSource)
                                completion(true)
                            }
                        } catch {
                            completion(false)
                        }
                    }
                }
                cancel.backgroundColor = .red
                actions.append(cancel)
            }
            if canReview {
                let review = UIContextualAction(style: .destructive, title: "Review") { _, _, completion in
                    let fundingSource = self.fundingSources[indexPath.row]
                    switch fundingSource {
                    case .creditCardFundingSource:
                        break
                    case .bankAccountFundingSource(let bankAccountFundingSource):
                        Task(priority: .medium) {
                            do {
                                let  reviewedFundingSource = try await self.reviewUnfundedFundingSource(id: bankAccountFundingSource.id)
                                Task {
                                    self.fundingSources.remove(at: indexPath.row)
                                    self.fundingSources.insert(reviewedFundingSource, at: indexPath.row)
                                    let cell = self.tableView.cellForRow(at: indexPath)
                                    cell?.textLabel?.text = self.getDisplayTitleForFundingSource(reviewedFundingSource)
                                    completion(true)
                                }
                            } catch {
                                completion(false)
                            }
                        }
                    }
                }
                review.backgroundColor = .red
                actions.append(review)
            }
            if canRefresh {
                let refresh = UIContextualAction(style: .destructive, title: "Refresh") { _, _, completion in
                    let fundingSource = self.fundingSources[indexPath.row]

                    Task(priority: .medium) {
                        do {
                            var refreshedFundingSource: FundingSource
                            switch fundingSource {
                            case .creditCardFundingSource(let creditCardFundingSource):
                                refreshedFundingSource = try await self.refreshFundingSource(id: creditCardFundingSource.id)
                            case .bankAccountFundingSource(let bankAccountFundingSource):
                                refreshedFundingSource = try await self.refreshFundingSource(id: bankAccountFundingSource.id)
                            }
                            Task {
                                self.fundingSources.remove(at: indexPath.row)
                                self.fundingSources.insert(refreshedFundingSource, at: indexPath.row)
                                let cell = self.tableView.cellForRow(at: indexPath)
                                cell?.textLabel?.text = self.getDisplayTitleForFundingSource(refreshedFundingSource)
                                completion(true)
                            }
                        } catch {
                            completion(false)
                        }
                    }
                }
                refresh.backgroundColor = .orange
                actions.append(refresh)
            }
            if !actions.isEmpty {
                return UISwipeActionsConfiguration(actions: actions)
            }
        }
        return nil
    }

    func updateNotificationConfiguration(config: NotificationConfiguration) async {
        let input = NotificationSettingsInput(
            bundleId: AppDelegate.dependencies.deviceInfo.bundleId,
            deviceId: AppDelegate.dependencies.deviceInfo.deviceId,
            filter: config.configs,
            services: [AppDelegate.dependencies.virtualCardsNotificationFilterClient.getSchema()])

        do {
            let updatedConfig = try await notificationClient.setNotificationConfiguration(config: input)
            AppDelegate.dependencies.notificationConfiguration = updatedConfig
        } catch {
            NSLog("Error updating notification configuration \(error)")

            presentErrorAlert(message: "Unable to update notification configuration: \(error.localizedDescription)", error: error)
        }
    }
}
