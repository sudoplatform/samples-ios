//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
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

    struct AccountDetails {
        var sudoLabel: String
        var fundingSource: FundingSource
        var card: VirtualCard

        var alias: String? {
            return card.metadataAlias ?? card.alias
        }
    }

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
    var inputCard: VirtualCard!

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
    lazy var dateTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .medium
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
            Task {
                await presentAlert(title: "Malformed transaction", message: "The transaction could not be loaded") { _ in
                    self.navigationController?.popViewController(animated: true)
                }
            }
            return
        }
        presentCancellableActivityAlert(message: "Loading Transaction", delegate: self) {
            let owners = self.inputCard.owners
            Task(priority: .medium) {
                do {
                    let transactions = try await self.listTransactions(withSequenceId: self.inputTransaction.sequenceId, cachePolicy: .remoteOnly)
                    guard let fundingSource = try await self.virtualCardsClient.getFundingSource(
                        withId: self.inputCard.fundingSourceId,
                        cachePolicy: .remoteOnly
                    ) else {
                        throw TransactionDetailError.fundingSourceNotFound
                    }

                    let sudos = try await self.profilesClient.listSudos(option: .remoteOnly)
                    guard let sudo = sudos.first(where: { sudo in
                        return owners.contains { $0.id == sudo.id }
                    }) else {
                        throw TransactionDetailError.sudoNotFound
                    }

                    Task {
                            guard let tableData = self.tableDataFromTransactions(
                                transactions,
                                sudo: sudo,
                                fundingSource: fundingSource,
                                card: self.inputCard
                            ) else {
                                Task {
                                    self.presentErrorAlert(message: "The transaction could not be loaded") { _ in
                                        Task {
                                            self.navigationController?.popViewController(animated: true)
                                        }
                                    }
                                }
                                return
                            }
                            self.tableData = tableData
                            self.tableView.reloadData()
                    }

                    self.dismissActivityAlert()
                } catch {
                    self.presentErrorAlert(message: "The transaction could not be loaded", error: error) { _ in
                        Task {
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
        cachePolicy: SudoVirtualCards.CachePolicy
    ) async throws -> [Transaction] {
        let result = try await virtualCardsClient.listTransactions(
            withLimit: Defaults.transactionLimit,
            nextToken: nil,
            dateRange: nil,
            sortOrder: nil,
            cachePolicy: cachePolicy)
        switch result {
        case .success(let success):
            return success.items
        case .partial(let partial):
            throw AnyError("Partial receieved: \(partial)")
        }
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
        card: VirtualCard
    ) -> TableData? {
        guard
            let selectedTransaction = transactions.first(where: { $0.id == inputTransaction.id }),
            let sudoLabel = sudo.label
        else {
            return nil
        }
        let generalSection = generalSectionFromTransaction(selectedTransaction)
        let detailSections = detailSectionsFromTransaction(selectedTransaction)
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
        let accountDetails = AccountDetails(sudoLabel: sudoLabel, fundingSource: fundingSource, card: card)
        let accountSection = accountSectionFromRawAccountDetails(details: accountDetails)

        var combinedArray: [[CellData]] = []
        combinedArray.append(generalSection)
        combinedArray.append(dateSection)
        combinedArray.append(contentsOf: detailSections)
        combinedArray.append(accountSection)
        return combinedArray
    }

    func generalSectionFromTransaction(_ transaction: Transaction) -> [CellData] {
        let merchantCell = CellData(title: "Merchant", value: transaction.description)
        let amountCellData = CellData(title: "Amount", value: transaction.billedAmount.presentableString)
        let statusCell = CellData(title: "Status", value: String(describing: transaction.type))
        if transaction.type == .decline {
            let declineReason = transaction.declineReason ?? TransactionDeclineReason.declined
            let declineReasonCell = CellData(title: "Decline Reason", value: String(describing: declineReason))
            return [merchantCell, statusCell, declineReasonCell]
        } else {
            return [merchantCell, amountCellData, statusCell]
        }
    }

    private func detailSectionsFromTransaction(_ transaction: Transaction) -> [[CellData]] {
        var sections: [[CellData]] = []
        for detail in transaction.detail {
            var cells: [CellData] = []
            let amountCellData = CellData(
                    title: "Merchant Amount",
                    value: detail.virtualCardAmount.presentableString)
            cells.append(amountCellData)
            switch transaction.type {
            case .complete, .pending:
                let feePercentString = String(format: "%.2f%%", (Double(detail.markup.percent) / 1000.0))
                let feeFlatString = String(format: "$%.2f", (Double(detail.markup.flat) / 100.0))
                let serviceFeeSubtitle = "\(feePercentString) + \(feeFlatString)"
                let serviceFeeCellData = CellData(title: "Service Fee", subtitle: serviceFeeSubtitle, value: detail.markupAmount.presentableString)
                let totalFeeCellData = CellData(title: "Funding Source Charge Amount", value: detail.fundingSourceAmount.presentableString)
                cells.append(contentsOf: [serviceFeeCellData, totalFeeCellData])
            default:
                break
            }
            if let transactedAt = detail.transactedAt {
                let detailTransactedCellData = CellData(title: "Date charged", value: dateTimeFormatter.string(from: transactedAt))
                cells.append(detailTransactedCellData)
            }
            if let settledAt = detail.settledAt {
                let detailSettledCellData = CellData(title: "Date settled", value: dateTimeFormatter.string(from: settledAt))
                cells.append(detailSettledCellData)
            }
            let statusCellData = CellData(title: "Charge Status", value: String(describing: detail.state))
            cells.append(statusCellData)
            sections.append(cells)
        }
        return sections
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
        let cardCell = CellData(title: "Virtual card", value: details.alias ?? "")
        var fundingSourceText = ""
        switch details.fundingSource {
        case .creditCardFundingSource(let creditCardFundingSource):
            fundingSourceText = "\(creditCardFundingSource.network.string) ••••\(creditCardFundingSource.last4)"
        case .bankAccountFundingSource(let bankAccountFundingSource):
            fundingSourceText = "\(bankAccountFundingSource.institutionName) ••••\(bankAccountFundingSource.last4)"
        }
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
        Task {
            dismissActivityAlert()
            self.navigationController?.popViewController(animated: true)
        }
    }
}
