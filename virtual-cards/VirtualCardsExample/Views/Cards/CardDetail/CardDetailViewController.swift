//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoVirtualCards

class CardDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets

    @IBOutlet var cardView: CardView!

    /// The table view that lists each card associated with the chosen `Card` from the previous view.
    @IBOutlet var tableView: UITableView!

    @IBOutlet var headerView: UIView!

    // MARK: - Supplementary

    typealias TransactionListSuccessCompletion = ([Transaction]) -> Void
    typealias TransactionListErrorCompletion = (Error) -> Void

    enum Defaults {
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

    var tableData: [(title: String, items: [Transaction])] = []

    var card: Card!

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
        loadCacheTransactionsAndFetchRemote()
    }

    // MARK: - Operations

    func listTransactions(
        cachePolicy: SudoVirtualCards.CachePolicy,
        success: @escaping TransactionListSuccessCompletion,
        failure: @escaping TransactionListErrorCompletion
    ) {
        let filter = GetTransactionsFilterInput(cardId: .equals(card.id))
        virtualCardsClient.getTransactionsWithFilter(filter, limit: Defaults.transactionLimit, nextToken: nil, cachePolicy: cachePolicy) { result in
            switch result {
            case let .success(output):
                success(output.items)
            case let .failure(error):
                failure(error)
            }
        }
    }

    // MARK: - Helpers: Configuration

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
            cardName: card.alias,
            cardStatus: status,
            cardholderName: card.cardHolder,
            cardNumber: card.pan.inserting(separator: " ", every: 4),
            expiration: "\(card.expiry.mm)/\(card.expiry.yyyy)",
            securityCode: card.csc
        )
        cardView.viewModel = cardModel
    }

    func configureTableView() {
        let transactionTableViewCell = UINib(nibName: "TransactionTableViewCell", bundle: .main)
        tableView.register(transactionTableViewCell, forCellReuseIdentifier: "transactionCell")
    }

    // MARK: - Helpers

    func loadCacheTransactionsAndFetchRemote() {
        let failureCompletion: TransactionListErrorCompletion = { [weak self] error in
            self?.presentErrorAlert(message: "Failed to list transactions", error: error)
        }
        listTransactions(
            cachePolicy: .useCache,
            success: { [weak self] transactions in
                guard let weakSelf = self else { return }
                DispatchQueue.main.async {
                    weakSelf.tableData = weakSelf.splitAndOrderTransactions(transactions)
                    weakSelf.tableView.reloadData()
                }
                weakSelf.listTransactions(
                    cachePolicy: .useOnline,
                    success: { [weak self] transactions in
                        guard let weakSelf = self else { return }
                        DispatchQueue.main.async {
                            weakSelf.tableData = weakSelf.splitAndOrderTransactions(transactions)
                            weakSelf.tableView.reloadData()
                        }
                    },
                    failure: failureCompletion
                )
            },
            failure: failureCompletion
        )
    }

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
        cell.selectionStyle = .none
        cell.desciptionLabel.text = presentableTransaction.description
        cell.dateLabel.text = presentableTransaction.date
        cell.amountLabel.text = presentableTransaction.amount
        cell.feeLabel.text = presentableTransaction.fee
        return cell
    }

    // MARK: - Conformance: UITableViewCell

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
