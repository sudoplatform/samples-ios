//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoProfiles
import SudoVirtualCards

/// This View Controller presents a list of transaction details.
///
/// Links From:
///     - `CardDetailViewController`: A user chooses a transaction from the Transaction table view list.
class TransactionDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ActivityAlertViewControllerDelegate {

    // MARK: - Outlets

    /// The table view that lists all the transaction details.
    @IBOutlet var tableView: UITableView!

    // MARK: - Supplementary

    typealias TransactionListCompletion = ClientCompletion<[Transaction]>

    typealias FundingSourceGetCompletion = ClientCompletion<FundingSource?>

    typealias SudoGetCompletion = ClientCompletion<Sudo?>

    typealias AccountDetails = (sudoLabel: String, fundingSource: FundingSource, card: Card)

    /// Defaults used in `TransactionDetailViewController`.
    enum Defaults {
        /// Limit used when querying transactions from `VirtualCardsClient`.
        static let transactionLimit = 100
    }

    typealias TableData = [[CellData]]

    /// Data to be presented in a `TransactionDetailTableViewCell`.
    struct CellData {

        /// Title of the cell.
        var title: String

        /// Subtitle of the cell.
        var subtitle: String?

        /// Value of the cell.
        var value: String
    }

    // MARK: - Properties

    /// Input of the card by the view that serves this view.
    var inputCard: Card!

    /// Input by the view that serves this view.
    var inputTransaction: Transaction!

    /// An Array containing arrays of name-value pairs.
    ///
    /// The top level array reflects the section, each second-level array reflects a cell.
    var tableData: TableData = []

    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter
    }()

    // MARK: - Properties: Computed

    /// Virtual cards client used to get resources from the virtual cards service.
    var virtualCardsClient: SudoVirtualCardsClient {
        return AppDelegate.dependencies.virtualCardsClient
    }

    /// Profiles used to get sudos.
    var profilesClient: SudoProfilesClient {
        return AppDelegate.dependencies.profilesClient
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = inputTransaction.description
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard inputTransaction != nil else {
            presentAlert(title: "Malformed transaction", message: "The transaction could not be loaded") { _ in
                self.navigationController?.popViewController(animated: true)
            }
            return
        }
        presentCancellableActivityAlert(message: "Loading Transaction", delegate: self) {
            var transactionResult: Swift.Result<[Transaction], Error>?
            var fundingSourceResult: Swift.Result<FundingSource, Error>?
            var sudoResult: Swift.Result<Sudo, Error>?
            let group = DispatchGroup()
            group.enter()
            self.listTransactions(withSequenceId: self.inputTransaction.sequenceId, cachePolicy: .remoteOnly) { result in
                transactionResult = result
                group.leave()
            }
            group.enter()
            self.virtualCardsClient.getFundingSourceWithId(self.inputCard.fundingSourceId, cachePolicy: .remoteOnly) { result in
                defer { group.leave() }
                switch result {
                case let .success(optionalFundingSource):
                    guard let fundingSource = optionalFundingSource else {
                        fundingSourceResult = .failure(TransactionDetailError.fundingSourceNotFound)
                        return
                    }
                    fundingSourceResult = .success(fundingSource)
                case let .failure(error):
                    fundingSourceResult = .failure(error)
                }
            }
            group.enter()
            do {
                try self.profilesClient.listSudos(option: .remoteOnly) { result in
                    defer { group.leave() }
                    switch result {
                    case let .success(sudos):
                        guard let sudo = sudos.first(where: { sudo in
                            return self.inputCard.owners.contains { $0.id == sudo.id }
                        }) else {
                            sudoResult = .failure(TransactionDetailError.sudoNotFound)
                            return
                        }
                        sudoResult = .success(sudo)
                    case let .failure(cause):
                        sudoResult = .failure(cause)
                    }
                }
            } catch {
                sudoResult = .failure(error)
                group.leave()
            }
            group.notify(queue: .main) {
                let transactions: [Transaction]
                let fundingSource: FundingSource
                let sudo: Sudo
                do {
                    guard
                        let transactionResult = transactionResult,
                        let fundingSourceResult = fundingSourceResult,
                        let sudoResult = sudoResult
                    else {
                        throw TransactionDetailError.failedToLoadData
                    }
                    transactions = try transactionResult.get()
                    fundingSource = try fundingSourceResult.get()
                    sudo = try sudoResult.get()
                    guard let tableData = self.tableDataFromTransactions(transactions, sudo: sudo, fundingSource: fundingSource, card: self.inputCard) else {
                        throw TransactionDetailError.failedToLoadData
                    }
                    self.tableData = tableData
                    self.tableView.reloadData()
                    self.dismissActivityAlert()
                } catch {
                    self.dismissActivityAlert {
                        self.presentErrorAlert(message: "The transaction could not be loaded", error: error) { _ in
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Operations

    /// List transactions from the virtual cards client.
    ///
    /// - Parameters:
    ///   - sequenceId: Sequence Id of the related transactions to return.
    ///   - cachePolicy: Cache policy used to retrieve the transactions.
    ///   - success: Closure that executes on a successful retrieval of transactions.
    ///   - failure: Closure that executes on an error during the retrieval of transactions.
    func listTransactions(
        withSequenceId sequenceId: String?,
        cachePolicy: SudoVirtualCards.CachePolicy,
        completion: @escaping TransactionListCompletion
    ) {
        var filter: GetTransactionsFilterInput?
        if let sequenceId = sequenceId {
            filter = GetTransactionsFilterInput(sequenceId: .equals(sequenceId))
        }
        virtualCardsClient.listTransactionsWithFilter(filter, limit: Defaults.transactionLimit, nextToken: nil, cachePolicy: cachePolicy) { result in
            let items = result.map { $0.items }
            completion(items)
        }
    }

    func loadTransactionCacheAndFetchRemote(
        onCacheLoad cacheCompletion: @escaping TransactionListCompletion,
        onRemoteLoad remoteCompletion: @escaping TransactionListCompletion
    ) {
        listTransactions(withSequenceId: inputTransaction.sequenceId, cachePolicy: .cacheOnly, completion: cacheCompletion)
        listTransactions(withSequenceId: inputTransaction.sequenceId, cachePolicy: .cacheOnly, completion: remoteCompletion)
    }

    // MARK: - Helpers: Configuration

    /// Configure the `tableView`.
    func configureTableView() {
        let transactionDetailTableViewCell = UINib(nibName: TransactionDetailTableViewCell.name, bundle: .main)
        tableView.separatorStyle = .none
        tableView.register(transactionDetailTableViewCell, forCellReuseIdentifier: TransactionDetailTableViewCell.name)
        tableView.tableFooterView = UIView()
    }

    // MARK: - Helpers

    func tableDataFromTransactions(
        _ transactions: [Transaction],
        sudo: Sudo,
        fundingSource: FundingSource,
        card: Card
    ) -> TableData? {
        guard
            let selectedTransaction = transactions.first(where: { $0.id == inputTransaction.id }),
            let sudoLabel = sudo.label
        else {
            return nil
        }
        let generalSection = generalSectionFromTransaction(selectedTransaction)
        let amountSection = amountSectionFromTransaction(selectedTransaction)
        var dateSection: [CellData] = []
        switch selectedTransaction.type {
        case .pending:
            dateSection = dateSectionFromPendingTransaction(selectedTransaction)
        case .decline:
            dateSection = dateSectionFromDeclinedTransaction(selectedTransaction)
        case .refund:
            guard let completeTransaction = transactions.first(where: { $0.type == .complete }) else {
                return nil
            }
            dateSection = dateSectionFromRefundedTransaction(selectedTransaction, completedTransaction: completeTransaction)
        case .complete:
            dateSection = dateSectionFromCompletedTransaction(selectedTransaction)
        default:
            break
        }
        let accountDetails: AccountDetails = (sudoLabel: sudoLabel, fundingSource: fundingSource, card: card)
        let accountSection = accountSectionFromRawAccountDetails(details: accountDetails)
        return [generalSection, amountSection, dateSection, accountSection]
    }

    func generalSectionFromTransaction(_ transaction: Transaction) -> [CellData] {
        let merchantCell = CellData(title: "Merchant", value: transaction.description)
        let statusCell = CellData(title: "Status", value: String(describing: transaction.type))
        if transaction.type == .decline {
            let declineReason = transaction.declineReason ?? Transaction.DeclineReason.declined
            let declineReasonCell = CellData(title: "Decline Reason", value: String(describing: declineReason))
            return [merchantCell, statusCell, declineReasonCell]
        } else {
            return [merchantCell, statusCell]
        }
    }

    func amountSectionFromTransaction(_ transaction: Transaction) -> [CellData] {
        let transactionDetail = transaction.detail.first!
        var cells: [CellData] = []
        let amountCellData = CellData(title: "Amount", value: transactionDetail.virtualCardAmount.presentableString)
        cells.append(amountCellData)
        switch inputTransaction.type {
        case .complete, .pending:
            let feePercentString = String(format: "%.2f%%", (Double(transactionDetail.markup.percent) / 1000.0))
            let feeFlatString = String(format: "$%.2f", (Double(transactionDetail.markup.flat) / 100.0))
            let serviceFeeSubtitle = "\(feePercentString) + \(feeFlatString)"
            let serviceFeeCellData = CellData(title: "Service Fee", subtitle: serviceFeeSubtitle, value: transactionDetail.markupAmount.presentableString)
            let totalFeeCellData = CellData(title: "Total", value: transactionDetail.fundingSourceAmount.presentableString)
            cells.append(contentsOf: [serviceFeeCellData, totalFeeCellData])
        default:
            break
        }
        return cells
    }

    func dateSectionFromPendingTransaction(_ transaction: Transaction) -> [CellData] {
        let dateChargedCell = CellData(title: "Date charged", value: dateFormatter.string(from: transaction.transactedAt))
        return [dateChargedCell]
    }

    func dateSectionFromDeclinedTransaction(_ transaction: Transaction) -> [CellData] {
        let dateDeclinedCell = CellData(title: "Date declined", value: dateFormatter.string(from: transaction.transactedAt))
        return [dateDeclinedCell]
    }

    func dateSectionFromRefundedTransaction(_ transaction: Transaction, completedTransaction: Transaction) -> [CellData] {
        let dateSettledCell = CellData(title: "Date settled", value: dateFormatter.string(from: completedTransaction.transactedAt))
        let dateRefundedCell = CellData(title: "Date refunded", value: dateFormatter.string(from: transaction.transactedAt))
        return [dateSettledCell, dateRefundedCell]
    }

    func dateSectionFromCompletedTransaction(_ transaction: Transaction) -> [CellData] {
        let dateSettledCell = CellData(title: "Date settled", value: dateFormatter.string(from: transaction.transactedAt))
        return [dateSettledCell]
    }

    func accountSectionFromRawAccountDetails(details: AccountDetails) -> [CellData] {
        let sudoCell = CellData(title: "Sudo", value: details.sudoLabel)
        let cardCell = CellData(title: "Virtual card", value: details.card.alias)
        let fundingSourceText = "\(details.fundingSource.network.string) ••••\(details.fundingSource.last4)"
        let fundedByCell = CellData(title: "Funded by", value: fundingSourceText)
        return [sudoCell, cardCell, fundedByCell]
    }

    // MARK: - Conformance: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return tableData.count
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = UIColor(red: 0.9411764706, green: 0.9411764706, blue: 0.9450980392, alpha: 1.0) // R: 240, G: 240, B: 241
        return footer
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == tableData.count - 1 {
            return 0.0
        }
        return 10.0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TransactionDetailTableViewCell.name) as? TransactionDetailTableViewCell else {
            return TransactionDetailTableViewCell()
        }
        let dataCell = tableData[indexPath.section][indexPath.row]
        cell.title = dataCell.title
        cell.subtitle = dataCell.subtitle
        cell.value = dataCell.value
        return cell
    }

    // MARK: - Conformance: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Conformance: ActivityAlertViewControllerDelegate

    func didTapAlertCancelButton() {
        dismissActivityAlert {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
