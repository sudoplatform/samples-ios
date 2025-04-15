//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoVirtualCards

/// This View Controller presents a view containing `Card` details and a list of `Transactions`.
///
/// - Links From:
///     - `CreateCardViewController`: A user chooses the "Create" option from the top right corner of the navigation bar.
///     - `CardListViewController`: A user chooses a `Card` which will show this view with the card detail and list of `Transactions` created against this card.
///     - `OrphanCardListViewController`: A user chooses an orphan `Card` which will show this view with the card detail and list of `Transactions` created
///         against this card.
class CardDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets

    /// Shows a graphical representation of a virtual card and its details.
    @IBOutlet var cardView: CardView!

    /// The table view that lists each card associated with the chosen `Card` from the previous view.
    @IBOutlet var tableView: UITableView!

    /// Shows the card view and transaction titles and information.
    @IBOutlet var headerView: UIView!

    // MARK: - Supplementary

    enum Segue: String {
        case navigateToTransactionDetail
    }

    /// Defaults used in `CardDetailsViewController`.
    enum Defaults {
        /// Limit used when querying transactions from `VirtualCardsClient`.
        static let transactionLimit = 100
    }

    /// Data type used to represent a transaction post transformation to be presented on the UI.
    struct PresentationTransaction {
        var description: String
        var date: String
        var amount: String
        var fee: String?
    }

    // MARK: - Properties

    /// Table data containing transactions.
    var tableData: [(title: String, items: [Transaction])] = []

    /// The selected card.
    var card: VirtualCard!

    // MARK: - Properties: Computed

    /// Virtual cards client used to get transactions.
    var virtualCardsClient: SudoVirtualCardsClient {
        return AppDelegate.dependencies.virtualCardsClient
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Card Details"
        configureCardView()
        configureTableView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.contentInset.top = headerView.frame.height - view.safeAreaInsets.top
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task {
            await fetchTransactions()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueType = Segue(rawValue: segue.identifier ?? "")
        switch segueType {
        case .navigateToTransactionDetail:
            guard
                let transactionDetail = segue.destination as? TransactionDetailViewController,
                let indexPath = tableView.indexPathForSelectedRow
            else {
                break
            }
            transactionDetail.inputTransaction = tableData[indexPath.section].items[indexPath.row]
            transactionDetail.inputCard = card
        case .none:
            break
        }
    }

    // MARK: - Helpers: Configuration

    /// Configure the view's card view.
    ///
    /// Sets the various card details on the graphical representation of a virtual card.
    func configureCardView() {
        let status: CardStatus
        switch card.state {
        case .closed:
            status = .closed
        case .failed:
            status = .failed
        case .issued:
            status = .issued
        case .suspended:
            status = .suspended
        case .unknown:
            status = .unknown
        }
        let cardModel = CardViewModel(
            cardName: card.metadataAlias ?? card.alias ?? "",
            cardStatus: status,
            cardholderName: card.cardHolder,
            cardNumber: card.pan.inserting(separator: " ", every: 4),
            expiration: "\(card.expiry.mm)/\(card.expiry.yyyy)",
            securityCode: card.csc
        )
        cardView.viewModel = cardModel
    }

    /// Configures the table view used to display the navigation elements.
    func configureTableView() {
        let transactionTableViewCell = UINib(nibName: "TransactionTableViewCell", bundle: .main)
        tableView.register(transactionTableViewCell, forCellReuseIdentifier: "transactionCell")
    }

    // MARK: - Helpers

    /// Attempts to fetch all transactions.
    ///
    /// On any failure,  a "Failed to list transactions" UIAlert message will be presented to the user.
    ///
    /// All transactions will be filtered and sorted based on the `type` of transaction to ensure that transactions are displayed as either "Pending"
    /// or "Complete".
    @MainActor func fetchTransactions() async {
        do {
            var transactions: [Transaction] = []
            let result = try await virtualCardsClient.listTransactions(
                withCardId: card.id,
                limit: Defaults.transactionLimit,
                nextToken: nil,
                dateRange: nil,
                sortOrder: nil
            )
            switch result {
            case .success(let success):
                transactions = success.items
            case .partial(let partial):
                throw AnyError("Failure: \(partial)")
            }
            tableData = splitAndOrderTransactions(transactions)
            tableView.reloadData()

        } catch {
            NSLog("error: \(error)")
            presentErrorAlert(message: "Failed to list transactions", error: error)
        }
    }

    /// Filters and sorts transactions based on `type` and returns as a map containing "Pending" and "Complete" transactions.
    ///
    /// - Parameter transactions: List of transactions to process.
    func splitAndOrderTransactions(_ transactions: [Transaction]) -> [(String, [Transaction])] {
        let descending: (Transaction, Transaction) -> Bool = { $0.transactedAt > $1.transactedAt }
        let pendingTransactions = transactions
            .filter({ $0.type == .pending })
            .sorted(by: descending)
        let completedTransactions = transactions
            .filter({ $0.type != .pending })
            .sorted(by: descending)
        let rawResults = [
            pendingTransactions.isEmpty ? nil : ("Pending", pendingTransactions),
            completedTransactions.isEmpty ? nil : ("Completed", completedTransactions)
        ]
        return rawResults.compactMap { $0 }
    }

    /// Transforms data to a form that can be presented clearly to the view.
    ///
    /// - Parameter data: transaction to process.
    func convertDataTransactionToPresentation(_ data: Transaction) -> PresentationTransaction {
        let description: String
        switch data.type {
        case .decline:
            description = data.description + " (Declined)"
        case .refund:
            description = data.description + " (Refunded)"
        default:
            description = data.description
        }
        let date = data.transactedAt.transactionPresentable
        let amount = data.billedAmount.presentableString
        let fee = data.detail.first?.markupAmount.presentableString
        return PresentationTransaction(description: description, date: date, amount: amount, fee: fee)
    }

    /// Get the table view's transaction for the current `indexPath`.
    func getTransaction(forIndexPath indexPath: IndexPath) -> Transaction? {
        let items = tableData[indexPath.section].items
        guard indexPath.row < items.count else {
            return nil
        }
        return items[indexPath.row]
    }

    // MARK: - Conformance: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return tableData.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableData[section].title
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "transactionCell", for: indexPath) as? TransactionTableViewCell else {
            return TransactionTableViewCell()
        }
        guard let transaction = getTransaction(forIndexPath: indexPath) else {
            return cell
        }
        let presentableTransaction = convertDataTransactionToPresentation(transaction)
        cell.desciptionLabel.text = presentableTransaction.description
        cell.dateLabel.text = presentableTransaction.date
        cell.amountLabel.text = presentableTransaction.amount
        cell.feeLabel.text = presentableTransaction.fee
        return cell
    }

    // MARK: - Conformance: UITableViewCell

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: Segue.navigateToTransactionDetail.rawValue, sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
