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
    var orphanCards: [Card] = []

    /// A list of `Sudos` to check for deleted Sudos.
    var sudos: [Sudo] = []

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
        Task.detached(priority: .medium) {
            await self.loadCacheSudosAndFetchRemote()
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
        Task.detached(priority: .medium) {
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
    ) async throws -> [Card] {
        return try await virtualCardsClient.listCardsWithFilter(nil, limit: Defaults.orphanCardListLimit, nextToken: nil, cachePolicy: cachePolicy).items
    }

    // MARK: - Helpers: Configuration

    /// Configures the table view used to display the navigation elements.
    func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "default")
        tableView.tableFooterView = UIView()
    }

    // MARK: - Helpers

    /// Filter a list of cards by a Sudo identifier of a deleted Sudo.
    ///
    /// - Parameters:
    ///   - cards: Cards to be filtered.
    ///   - sudoIds: Sudo Identifiers.
    /// - Returns: Filtered orphan cards.
    func filterCards(_ cards: [Card], withSudoIds sudoIds: [String]) -> [Card] {
        return cards.filter { $0.owners.contains { !sudoIds.contains($0.id) } }
    }

    /// Attempts to load all the cards from the device's cache, and then update via a remote call.
    ///
    /// On any failure, either by cache or remote call, a "Failed to list orphan cards" UIAlert message will be presented to the user.
    ///
    /// All cards will be filtered using the `sudoId`of deleted Sudos to ensure only cards associated with the deleted sudo are listed.
    func loadCacheOrphanCardsAndFetchRemote() async {
        do {
            let sudoIds = self.sudos.map { $0.id ?? "" }
            let localCards = try await listOrphanCards(cachePolicy: .cacheOnly)

            Task { @MainActor in
                self.orphanCards = self.filterCards(localCards, withSudoIds: sudoIds)
                self.tableView.reloadData()
            }

            let remoteCards = try await self.listOrphanCards(cachePolicy: .remoteOnly)

            Task { @MainActor in
                self.orphanCards = self.filterCards(remoteCards, withSudoIds: sudoIds)
                self.tableView.reloadData()
            }
        } catch {
            await self.presentErrorAlert(message: "Failed to list orphan Cards", error: error)
        }
    }

    /// Attempts to load all Sudos from the device's cache first and then update via a remote call.
    func loadCacheSudosAndFetchRemote() async {
        do {
            let localSudos = try await self.profilesClient.listSudos(option: .cacheOnly)
            Task { @MainActor in
                self.sudos = localSudos
            }
            let remoteSudos = try await self.profilesClient.listSudos(option: .remoteOnly)
            Task { @MainActor in
                self.sudos = remoteSudos
            }
        } catch {
            await self.presentErrorAlert(message: "Failed to list Sudos", error: error)
        }
    }

    /// Formats the title which represents an orphan card and is displayed on the table view cell.
    ///
    /// - Parameter orphanCard: The orphan card to display.
    func getDisplayTitleForOrphanCard(_ orphanCard: Card) -> String {
        let suffix = (orphanCard.state == .closed) ? " - Cancelled" : ""
        return "\(orphanCard.alias) \(suffix)"
    }

    // MARK: - Conformance: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    @MainActor
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orphanCards.count
    }

    @MainActor
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
        let orphanCard = orphanCards[indexPath.row]
        cell.textLabel?.textColor = UIColor.black
        cell.textLabel?.text = getDisplayTitleForOrphanCard(orphanCard)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - Conformance: UITableViewDelegate

    @MainActor
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(indexPath.section == 0)
        performSegue(withIdentifier: Segue.navigateToCardDetail.rawValue, sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
