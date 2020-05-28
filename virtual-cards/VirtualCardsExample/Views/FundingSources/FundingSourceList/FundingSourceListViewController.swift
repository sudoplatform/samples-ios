//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoProfiles
import SudoVirtualCards

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

    /// Typealias for a successful response call to `VirtualCardsClient.getFundingSourcesWithFilter(_:limit:nextToken:cachePolicy:completion:)`
    typealias FundingSourceListSuccessCompletion = ([FundingSource]) -> Void

    /// Typealias for a error response call to `VirtualCardsClient.getFundingSourcesWithFilter(_:limit:nextToken:cachePolicy:completion:)`.
    typealias FundingSourceListErrorCompletion = (Error) -> Void

    /// Defaults used in `FundingSourceListViewController`.
    enum Defaults {
        /// Limit used when querying funding sources from `VirtualCardsClient`.
        static let fundingSourceLimit = 10
    }

    /// Segues that are performed in `FundingSourceListViewController`.
    enum Segue: String {
        /// Used to navigate to the `CreateFundingSourceViewController`.
        case navigateToCreateFundingSource
    }

    // MARK: - Properties

    /// A list of `FundingSources`.
    var fundingSources: [FundingSource] = []

    // MARK: - Properties: Computed

    /// Virtual cards client used to get and create funding sources.
    var virtualCardsClient: SudoVirtualCardsClient {
        return AppDelegate.dependencies.virtualCardsClient
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCacheFundingSourcesAndFetchRemote()
    }

    // MARK: - Actions

    /// Action associated with returning to this view from a segue.
    ///
    /// This action will ensure that the funding source list is up to date when returning from views - e.g. `CreateFundingSourceViewController`.
    @IBAction func returnToFundingSourceList(segue: UIStoryboardSegue) {
        loadCacheFundingSourcesAndFetchRemote()
    }

    // MARK: - Operations

    /// List funding sources from the virtual cards client.
    ///
    /// - Parameters:
    ///   - cachePolicy: Cache policy used to retrieve the funding sources.
    ///   - success: Closure that executes on a successful retrieval of funding sources.
    ///   - failure: Closure that executes on an error during the retrieval of funding sources.
    func listFundingSources(
        cachePolicy: SudoVirtualCards.CachePolicy,
        success: @escaping FundingSourceListSuccessCompletion,
        failure: @escaping FundingSourceListErrorCompletion
    ) {
        virtualCardsClient.getFundingSourcesWithLimit(Defaults.fundingSourceLimit, nextToken: nil, cachePolicy: cachePolicy) { result in
            switch result {
            case let .success(output):
                success(output.items)
            case let .failure(error):
                failure(error)
            }
        }
    }

    /// Cancel a funding source based on the input id.
    ///
    /// - Parameter id: The id of the funding source to cancel.
    func cancelFundingSource(id: String, _ completion: @escaping (Result<FundingSource, Error>) -> Void) {
        presentActivityAlert(message: "Cancelling funding source")
        virtualCardsClient.cancelFundingSourceWithId(id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.dismissActivityAlert()
                case let .failure(error):
                    self?.dismissActivityAlert {
                        self?.presentErrorAlert(message: "Failed to cancel funding source", error: error)
                    }
                }
                completion(result)
            }
        }
    }

    // MARK: - Helpers: Configuration

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
    func loadCacheFundingSourcesAndFetchRemote() {
        let failureCompletion: FundingSourceListErrorCompletion = { [weak self] error in
             self?.presentErrorAlert(message: "Failed to list Funding Sources", error: error)
         }
        listFundingSources(
            cachePolicy: .useCache,
            success: { [weak self] fundingSources in
                guard let weakSelf = self else { return }
                DispatchQueue.main.async {
                    weakSelf.fundingSources = fundingSources
                    weakSelf.tableView.reloadData()
                }
                weakSelf.listFundingSources(
                    cachePolicy: .useOnline,
                    success: { [weak self] fundingSources in
                        DispatchQueue.main.async {
                            guard let weakSelf = self else { return }
                            weakSelf.fundingSources = fundingSources
                            weakSelf.tableView.reloadData()
                        }
                    },
                    failure: failureCompletion
                )
            },
            failure: failureCompletion
        )
    }

    /// Formats the title which represents a funding source and is displayed on the table view cell.
    ///
    /// - Parameter fundingSource: The funding source to display.
    func getDisplayTitleForFundingSource(_ fundingSource: FundingSource) -> String {
        let suffix = (fundingSource.state == .inactive) ? " - Cancelled" : ""
        let cardNetwork = fundingSource.network.string.capitalized
        return "\(cardNetwork) ••••\(fundingSource.last4)\(suffix)"
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
        }
        return cell
    }

    // MARK: - Conformance: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(indexPath.section == 0)
        if indexPath.row == fundingSources.count {
            performSegue(withIdentifier: Segue.navigateToCreateFundingSource.rawValue, sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.row != fundingSources.count {
            let cancel = UIContextualAction(style: .destructive, title: "Cancel") { _, _, completion in
                let fundingSource = self.fundingSources[indexPath.row]
                self.cancelFundingSource(id: fundingSource.id) { result in
                    switch result {
                    case .success(let result):
                        self.fundingSources.remove(at: indexPath.row)
                        self.fundingSources.insert(result, at: indexPath.row)
                        let cell = self.tableView.cellForRow(at: indexPath)
                        cell?.textLabel?.text = self.getDisplayTitleForFundingSource(result)
                        completion(true)
                    case .failure:
                        completion(false)
                    }
                }
            }
            cancel.backgroundColor = .red
            return UISwipeActionsConfiguration(actions: [cancel])
        }
        return nil
    }
}
