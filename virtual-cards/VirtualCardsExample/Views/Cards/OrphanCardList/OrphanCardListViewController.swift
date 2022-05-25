//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoVirtualCards
import SudoProfiles

/// This View Controller presents a list of orphan `Cards` which are associated with deleted Sudos.
///
/// - Links From:
///     - `MainMenuViewController`: A user chooses the "Orphan Cards" option from the main menu table view which will show this view with the list of
///         orphan cards. The orphan card's `alias` property is used as the text for each card.
/// - Links To:
///     - `CardDetailViewController`: If a user chooses an orphan `Card` from the list, the `CardDetailViewController` will be presented so the user can
///         view card details and transactions.
class OrphanCardListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets

    /// The table view that lists each orphan card.
    ///
    /// If a user does not have any `Cards` that are orphaned without a Sudo, then the list will be empty.
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Supplementary

    /// Defaults used in `OrphanCardListViewController`.
    enum Defaults {
        /// Limit used when querying for orphan cards from `VirtualCardsClient`.
        static let orphanCardListLimit = 30
    }

    /// Segues that are performed in `OrphanCardListViewController`.
    enum Segue: String {
        /// Used to navigate to the `CardDetailViewController`.
        case navigateToCardDetail
    }

    // MARK: - Properties

    /// A list of orphan`Cards` that are associated with the `sudoId` of a deleted Sudo.
    var orphanCards: [VirtualCard] = []

    // MARK: - Properties: Computed

    /// Virtual cards client used to get and create cards.
    var virtualCardsClient: SudoVirtualCardsClient {
        return AppDelegate.dependencies.virtualCardsClient
    }

    /// Sudo profiles client used get Sudos.
    var profilesClient: SudoProfilesClient {
        return AppDelegate.dependencies.profilesClient
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task(priority: .medium) {
            await self.loadCacheOrphanCardsAndFetchRemote()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueType = Segue.init(rawValue: segue.identifier ?? "")
        switch segueType {
        case .navigateToCardDetail:
            guard let cardDetail = segue.destination as? CardDetailViewController, let row = tableView.indexPathForSelectedRow?.row else {
                break
            }
            cardDetail.card = orphanCards[row]
        default:
            break
        }
    }

    // MARK: - Actions

    /// Action associated with returning to this view from a segue.
    ///
    /// This action will ensure that the orphan card list is up to date when returning from views - e.g. `CardDetailViewController`.
    @IBAction func returnToOrphanCardList(segue: UIStoryboardSegue) {
        Task(priority: .medium) {
            await self.loadCacheOrphanCardsAndFetchRemote()
        }
    }

    // MARK: - Operations

    /// List orphan cards from the virtual cards client.
    ///
    /// - Parameters:
    ///   - cachePolicy: Cache policy used to retrieve the orphan cards.
    func listOrphanCards(
        cachePolicy: SudoVirtualCards.CachePolicy
    ) async throws -> [VirtualCard] {
        let result = try await virtualCardsClient.listVirtualCards(withLimit: Defaults.orphanCardListLimit, nextToken: nil, cachePolicy: cachePolicy)
        switch result {
        case .success(let success):
            return success.items
        case .partial(let partial):
            throw AnyError("Error occurred: \(partial)")
        }
    }

    // MARK: - Helpers: Configuration

    /// Configures the table view used to display the navigation elements.
    func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "default")
        tableView.tableFooterView = UIView()
    }

    // MARK: - Helpers

    /// Filter a list of cards by removing all sudos that do not contain a ownership proof.
    ///
    /// - Parameters:
    ///   - cards: Cards to be filtered.
    ///   - sudoIds: Sudo Identifiers.
    /// - Returns: Filtered orphan cards.
    func filterCards(_ cards: [VirtualCard]) -> [VirtualCard] {
        return cards.filter { card in
            return !card.owners.contains { $0.issuer == "sudoplatform.sudoservice" }
        }
    }

    /// Attempts to load all the cards from the device's cache, and then update via a remote call.
    ///
    /// On any failure, either by cache or remote call, a "Failed to list orphan cards" UIAlert message will be presented to the user.
    ///
    /// All cards will be filtered using the `sudoId`of deleted Sudos to ensure only cards associated with the deleted sudo are listed.
    func loadCacheOrphanCardsAndFetchRemote() async {
        do {
            let localCards = try await listOrphanCards(cachePolicy: .cacheOnly)

            Task {
                self.orphanCards = self.filterCards(localCards)
                self.tableView.reloadData()
            }

            let remoteCards = try await self.listOrphanCards(cachePolicy: .remoteOnly)

            Task {
                self.orphanCards = self.filterCards(remoteCards)
                self.tableView.reloadData()
            }
        } catch {
            Task {
                self.presentErrorAlert(message: "Failed to list orphan Cards", error: error)
            }
        }
    }

    /// Formats the title which represents an orphan card and is displayed on the table view cell.
    ///
    /// - Parameter orphanCard: The orphan card to display.
    func getDisplayTitleForOrphanCard(_ orphanCard: VirtualCard) -> String {
        let suffix = (orphanCard.state == .closed) ? " - Cancelled" : ""
        return "\(orphanCard.metadataAlias ?? orphanCard.alias ?? "") \(suffix)"
    }

    // MARK: - Conformance: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orphanCards.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
        let orphanCard = orphanCards[indexPath.row]
        cell.textLabel?.textColor = UIColor.black
        cell.textLabel?.text = getDisplayTitleForOrphanCard(orphanCard)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - Conformance: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(indexPath.section == 0)
        performSegue(withIdentifier: Segue.navigateToCardDetail.rawValue, sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
