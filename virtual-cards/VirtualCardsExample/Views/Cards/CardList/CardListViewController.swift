//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoVirtualCards
import SudoProfiles

/// This View Controller presents a list of `Cards` associated with a `Sudo`.
///
/// - Links From:
///     - `CreateSudoViewController`: A user chooses the "Create" option from the top right corner of the navigation bar.
///     - `SudoListViewController`: A user chooses a `Sudo` which will show this view with the list of cards created against this sudo. The card's `alias`
///         property is used as the text for each card.
/// - Links To:
///     - `CreateCardViewController`: If a user taps the "Create Virtual Card" button, the `CreateCardViewController` will be presented
///         so the user can add a new card to their sudo.
///     - `CardDetailViewController`: If a user chooses a `Card` from the list, the `CardDetailViewController` will be presented so the user can
///         view card details and transactions.
class CardListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets

    /// The table view that lists each card associated with the chosen `Sudo` from the previous view.
    ///
    /// If the user does not have any `Cards` associated to this `Sudo`, then only the "Create Virtual Card" entry will be seen. This can be tapped to add a
    /// card to the sudo.
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Supplementary

    /// Defaults used in `CardListViewController`.
    enum Defaults {
        /// Limit used when querying cards from `VirtualCardsClient`.
        static let cardListLimit = 30
    }

    /// Segues that are performed in `CardListViewController`.
    enum Segue: String {
        /// Used to navigate to the `CreateCardViewController`.
        case navigateToCreateCard
        /// Used to navigate to the `CardDetailViewController`.
        case navigateToCardDetail
        /// Used to navigate back to the `SudoListViewController`.
        case returnToSudoList
    }

    // MARK: - Properties

    /// Label of a `Sudo` that was selected from the previous view. Used to present to the user.
    var sudoLabelText: String = ""

    /// `Sudo` that was selected from the previous view. Used to filter cards and add a new card.
    var sudo: Sudo = Sudo()

    /// A list of `Cards` that are associated with the `sudoId`.
    var cards: [VirtualCard] = []

    // MARK: - Properties: Computed

    /// Virtual cards client used to get and create cards.
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
        guard let sudoLabel = sudo.label, !sudoLabel.isEmpty else {
            Task {
                presentErrorAlert(
                    message: "An error has occurred: no sudo label found",
                    okHandler: { _ in
                        self.performSegue(withIdentifier: Segue.returnToSudoList.rawValue, sender: self)
                    }
                )
            }
            return
        }
        guard let sudoId = sudo.id, !sudoId.isEmpty else {
            Task {
                presentErrorAlert(
                    message: "An error has occurred: no sudo id found",
                    okHandler: { _ in
                        self.performSegue(withIdentifier: Segue.returnToSudoList.rawValue, sender: self)
                    }
                )
            }
            return
        }

        Task(priority: .medium) {
            await self.loadCacheCardsAndFetchRemote()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueType = Segue(rawValue: segue.identifier ?? "")
        switch segueType {
        case .navigateToCreateCard:
            guard let createCard = segue.destination as? CreateCardViewController else {
                break
            }
            createCard.sudo = sudo
        case .navigateToCardDetail:
            guard let cardDetail = segue.destination as? CardDetailViewController, let row = tableView.indexPathForSelectedRow?.row else {
                break
            }
            cardDetail.card = cards[row]
        default:
            break
        }
    }

    // MARK: - Actions

    /// Action associated with returning to this view from a segue.
    ///
    /// This action will ensure that the card list is up to date when returning from views - e.g. `CreateCardViewController`.
    @IBAction func returnToCardList(segue: UIStoryboardSegue) {
        Task(priority: .medium) {
            await self.loadCacheCardsAndFetchRemote()
        }
    }

    // MARK: - Operations

    /// List cards from the virtual cards client.
    ///
    /// - Parameters:
    ///   - cachePolicy: Cache policy used to retrieve the cards.
    func listCards(cachePolicy: SudoVirtualCards.CachePolicy) async throws -> [VirtualCard] {
        let result = try await virtualCardsClient.listVirtualCards(withLimit: Defaults.cardListLimit, nextToken: nil, cachePolicy: cachePolicy)
        switch result {
        case .success(let success):
            return success.items
        case .partial(let partial):
            throw AnyError("Failure: \(partial)")
        }
    }

    /// Cancel a card based on the input id.
    ///
    /// - Parameter id: The id of the card to cancel.
    func cancelCard(id: String) async throws -> VirtualCard {
        Task {
            self.presentActivityAlert(message: "Cancelling card")
        }

        do {
            let result = try await virtualCardsClient.cancelVirtualCard(withId: id)
            let card: VirtualCard
            switch result {
            case .success(let c):
                card = c
            case .partial(let partial):
                throw AnyError("Failure: \(partial)")
            }

            Task {
                self.dismissActivityAlert()
            }
            return card
        } catch {
            Task {
                self.dismissActivityAlert()
                self.presentErrorAlert(message: "Failed to cancel card", error: error)
            }
            throw error
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

    /// Firstly, attempts to load all the cards from the device's cache, and then update via a remote call.
    ///
    /// On any failure, either by cache or remote call, a "Failed to list cards" UIAlert message will be presented to the user.
    ///
    /// All cards will be filtered using the `sudoId` to ensure only cards associated with the sudo are listed.
    func loadCacheCardsAndFetchRemote() async {
        do {
            let localCards = try await listCards(
                cachePolicy: .cacheOnly
            )

            Task {
                self.cards = self.filterCards(localCards, withSudoId: self.sudo.id ?? "")
                self.tableView.reloadData()
            }

            let remoteCards = try await listCards(
                cachePolicy: .remoteOnly
            )

            Task {
                self.cards = self.filterCards(remoteCards, withSudoId: self.sudo.id ?? "")
                self.tableView.reloadData()
            }
        } catch {
            Task {
                 self.presentErrorAlert(message: "Failed to list Cards", error: error)
            }
        }
    }

    /// Filter a list of cards by a sudo identifier.
    ///
    /// - Parameters:
    ///   - cards: Cards to be filtered.
    ///   - sudoId: Sudo Identifier to use to filter the cards.
    /// - Returns: Filtered cards.
    func filterCards(_ cards: [VirtualCard], withSudoId sudoId: String) -> [VirtualCard] {
        return cards.filter { $0.owners.contains { $0.id == sudoId } }
    }

    /// Formats the title which represents a card and is displayed on the table view cell.
    ///
    /// - Parameter card: The card to display.
    func getDisplayTitleForCard(_ card: VirtualCard) -> String {
        let suffix = (card.state == .closed) ? " - Cancelled" : ""
        return "\(card.metadataAlias ?? card.alias ?? "") \(suffix)"
    }

    // MARK: - Conformance: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cards.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if indexPath.row == cards.count {
            cell = tableView.dequeueReusableCell(withIdentifier: "create", for: indexPath)
            cell.textLabel?.text = "Create Virtual Card"
            cell.textLabel?.textColor = UIColor.systemBlue
            cell.accessoryView = UIImageView(image: UIImage.init(systemName: "plus"))
            cell.semanticContentAttribute = .forceRightToLeft
        } else {
            let card = cards[indexPath.row]
            cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
            cell.textLabel?.textColor = UIColor.black
            cell.textLabel?.text = getDisplayTitleForCard(card)
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    // MARK: - Conformance: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(indexPath.section == 0)
        if indexPath.row == cards.count {
            performSegue(withIdentifier: Segue.navigateToCreateCard.rawValue, sender: self)
        } else {
            performSegue(withIdentifier: Segue.navigateToCardDetail.rawValue, sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.row != cards.count {
            let cancel = UIContextualAction(style: .destructive, title: "Cancel") { _, _, completion in
                let card = self.cards[indexPath.row]

                Task(priority: .medium) {
                    do {
                        let canceledCard = try await self.cancelCard(id: card.id)
                        Task {
                            self.cards.remove(at: indexPath.row)
                            self.cards.insert(canceledCard, at: indexPath.row)
                            let cell = self.tableView.cellForRow(at: indexPath)
                            cell?.textLabel?.text = self.getDisplayTitleForCard(canceledCard)
                            completion(true)
                        }
                    } catch {
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
