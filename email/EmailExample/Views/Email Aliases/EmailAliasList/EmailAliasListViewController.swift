//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoEmail

/// This View Controller presents a global list of all `EmailAlias` objects for the current user.
///
/// Supports segmented filtering between internal and external alias types when external
/// aliases are enabled via configuration.
///
/// - Links From:
///     - `EmailMessageListViewController`: A user taps the "Alias" button in the navigation bar.
/// - Links To:
///     - `CreateEmailAliasViewController`: If a user taps the "Create Email Alias" row, the `CreateEmailAliasViewController` will
///         be presented so the user can provision a new email alias.
///     - `UpdateEmailAliasViewController`: If a user taps an existing alias row, the `UpdateEmailAliasViewController` will be
///         presented so the user can edit the alias's metadata and expiry.
@MainActor
class EmailAliasListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets

    /// The table view that lists each email alias.
    ///
    /// If the user does not have any email aliases, only the "Create Email Alias" entry will be seen.
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Supplementary

    /// Segues that are performed in `EmailAliasListViewController`.
    enum Segue: String {
        /// Used to navigate to the `CreateEmailAliasViewController`.
        case navigateToCreateEmailAlias
        /// Used to navigate to the `UpdateEmailAliasViewController`.
        case navigateToUpdateEmailAlias
        /// Used to navigate back to the `EmailAliasListViewController` (unwind).
        case returnToEmailAliasList
    }

    // MARK: - Properties

    /// A list of all `EmailAlias` objects for the current user.
    var emailAlias: [EmailAlias] = []

    /// The filtered subset of aliases matching the currently selected segment.
    var filteredAlias: [EmailAlias] = []

    /// Whether email aliases are enabled in the service configuration.
    var aliasesEnabled: Bool = true

    /// Cached configuration flag indicating whether external aliases are supported.
    var externalAliasEnabled: Bool = false

    /// The segmented control for switching between Internal and External alias views.
    /// Only created when `externalAliasEnabled` is true.
    var segmentedControl: UISegmentedControl?

    /// Tracks the currently selected segment (defaults to .internal).
    var selectedSegment: AliasTypeSegment = .internal

    // MARK: - Properties: Computed

    /// Email client used to manage email aliases.
    var emailClient: SudoEmailClient {
        return AppDelegate.dependencies.emailClient
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task {
            await self.loadAlias()
        }
    }

    // MARK: - Actions

    /// Action associated with returning to this view from a segue.
    @IBAction func returnToEmailAliasList(segue: UIStoryboardSegue) {
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueType = Segue(rawValue: segue.identifier ?? "")
        switch segueType {
        case .navigateToCreateEmailAlias:
            // CreateEmailAliasViewController now loads its own email addresses
            break

        case .navigateToUpdateEmailAlias:
            guard let updateVC = segue.destination as? UpdateEmailAliasViewController,
                  let row = tableView.indexPathForSelectedRow?.row,
                  row < filteredAlias.count else {
                break
            }
            updateVC.emailAlias = filteredAlias[row]

        default:
            break
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

    /// Checks the email alias configuration and loads all aliases for the current user.
    ///
    /// If aliases are not enabled in the configuration, an informational label is displayed and the "Create" row is hidden.
    /// Also checks whether external aliases are enabled to show the segmented filter control.
    func loadAlias() async {
        // Step 1: Check configuration
        var configExternalEnabled = false
        do {
            let configData = try await emailClient.getConfigurationData()
            if !configData.emailAliasesEnabled {
                self.aliasesEnabled = false
                Task {
                    self.showAliasDisabledLabel()
                    self.tableView.reloadData()
                }
                return
            }
            configExternalEnabled = configData.externalEmailAliasesEnabled
        } catch {
            Task {
                self.presentErrorAlert(message: "Failed to get email alias configuration", error: error)
            }
            return
        }

        // Step 2: Load all aliases for the current user
        do {
            let input = ListEmailAliasesForOwnerInput()
            let output = try await emailClient.listEmailAliasesForOwner(withInput: input)
            Task {
                self.externalAliasEnabled = configExternalEnabled
                self.emailAlias = output.items
                self.configureSegmentedControl()
                self.filterAlias()
                self.tableView.reloadData()
            }
        } catch {
            Task {
                self.presentErrorAlert(message: "Failed to list email aliases", error: error)
            }
        }
    }

    /// Displays an informational label indicating that email aliases are not available.
    func showAliasDisabledLabel() {
        let label = UILabel()
        label.text = "Email aliases are not enabled for this account."
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundView = label
    }

    // MARK: - Segmented Control

    /// Configures the segmented control based on the `externalAliasEnabled` flag.
    func configureSegmentedControl() {
        if externalAliasEnabled {
            if segmentedControl == nil {
                let control = UISegmentedControl(items: ["Internal", "External"])
                control.selectedSegmentIndex = AliasTypeSegment.internal.rawValue
                control.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)

                let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44))
                control.translatesAutoresizingMaskIntoConstraints = false
                headerView.addSubview(control)
                NSLayoutConstraint.activate([
                    control.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                    control.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
                    control.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
                ])

                segmentedControl = control
                tableView.tableHeaderView = headerView
            }

            segmentedControl?.selectedSegmentIndex = selectedSegment.rawValue
            segmentedControl?.isHidden = false
            tableView.tableHeaderView?.isHidden = false
        } else {
            segmentedControl?.isHidden = true
            tableView.tableHeaderView = nil
            selectedSegment = .internal
        }
    }

    @objc func segmentChanged(_ sender: UISegmentedControl) {
        guard let segment = AliasTypeSegment(rawValue: sender.selectedSegmentIndex) else { return }
        selectedSegment = segment
        filterAlias()
        tableView.reloadData()
    }

    // MARK: - Filtering

    /// Filters `emailAlias` into `filteredAlias` based on the currently selected segment.
    func filterAlias() {
        if externalAliasEnabled {
            let type: EmailAlias.RealAddressType = selectedSegment == .external ? .external : .internal
            filteredAlias = AliasListFilter.filter(aliases: emailAlias, byType: type)
        } else {
            filteredAlias = emailAlias
        }
    }

    // MARK: - Conformance: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !aliasesEnabled {
            return 0
        }

        if filteredAlias.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No email aliases. Tap 'Create Email Alias' to get started."
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .secondaryLabel
            emptyLabel.numberOfLines = 0
            emptyLabel.font = UIFont.preferredFont(forTextStyle: .body)
            tableView.backgroundView = emptyLabel
        } else {
            tableView.backgroundView = nil
        }

        return filteredAlias.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if indexPath.row == filteredAlias.count {
            cell = tableView.dequeueReusableCell(withIdentifier: "create", for: indexPath)
            cell.textLabel?.text = "Create Email Alias"
            cell.textLabel?.textColor = UIColor.systemBlue
            cell.accessoryView = UIImageView(image: UIImage(systemName: "plus"))
            cell.semanticContentAttribute = .forceRightToLeft
        } else {
            let alias = filteredAlias[indexPath.row]
            cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)

            var content = cell.defaultContentConfiguration()
            content.text = alias.aliasAddress

            var detailParts: [String] = []
            detailParts.append(alias.realAddress)

            switch alias.status {
            case .pending:
                detailParts.append("Pending")
            case .enabled:
                detailParts.append("Enabled")
            case .disabled:
                detailParts.append("Disabled")
            case .locked:
                detailParts.append("Locked")
            }

            if let metadata = alias.metadata, !metadata.isEmpty {
                let metadataStr = metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                let truncated = metadataStr.count > 30 ? String(metadataStr.prefix(30)) + "…" : metadataStr
                detailParts.append(truncated)
            }

            if let expiresAt = alias.expiresAt {
                detailParts.append("Expires: \(expiresAt.getFormattedDate(format: "yyyy-MM-dd"))")
            }

            content.secondaryText = detailParts.joined(separator: " · ")
            content.secondaryTextProperties.color = .secondaryLabel
            content.secondaryTextProperties.font = UIFont.preferredFont(forTextStyle: .caption1)

            cell.contentConfiguration = content

            // Status tag for external aliases
            if alias.realAddressType == .external {
                let statusLabel = UILabel()
                let statusColor: UIColor

                switch alias.status {
                case .pending:
                    statusLabel.text = "PENDING"
                    statusColor = AliasStatusColor.pending
                case .enabled:
                    statusLabel.text = "ENABLED"
                    statusColor = AliasStatusColor.enabled
                case .disabled:
                    statusLabel.text = "DISABLED"
                    statusColor = AliasStatusColor.disabled
                case .locked:
                    statusLabel.text = "LOCKED"
                    statusColor = AliasStatusColor.disabled
                }

                statusLabel.textColor = statusColor
                statusLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
                statusLabel.sizeToFit()
                cell.accessoryView = statusLabel
            } else {
                cell.accessoryView = nil
                cell.accessoryType = .disclosureIndicator
            }
        }
        return cell
    }

    // MARK: - Conformance: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(indexPath.section == 0)
        if indexPath.row == filteredAlias.count {
            performSegue(withIdentifier: Segue.navigateToCreateEmailAlias.rawValue, sender: self)
        } else {
            let alias = filteredAlias[indexPath.row]
            if alias.realAddressType == .external && alias.status == .pending {
                showVerificationInitiationAlert(for: alias, at: indexPath)
            } else {
                performSegue(withIdentifier: Segue.navigateToUpdateEmailAlias.rawValue, sender: self)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < filteredAlias.count else {
            return nil
        }

        let alias = filteredAlias[indexPath.row]

        if alias.realAddressType == .external {
            return buildExternalAliasSwipeActions(for: alias, at: indexPath)
        }

        return buildInternalAliasSwipeActions(for: alias, at: indexPath)
    }

    // MARK: - Swipe Actions: Internal Alias

    private func buildInternalAliasSwipeActions(for alias: EmailAlias, at indexPath: IndexPath) -> UISwipeActionsConfiguration {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
            self.presentActivityAlert(message: "Deleting Email Alias")
            Task {
                do {
                    let input = DeprovisionEmailAliasInput(emailAliasId: alias.id)
                    _ = try await self.emailClient.deprovisionEmailAlias(withInput: input)
                    Task {
                        self.dismissActivityAlert()
                        if let idx = self.emailAlias.firstIndex(where: { $0.id == alias.id }) {
                            self.emailAlias.remove(at: idx)
                        }
                        self.filterAlias()
                        self.tableView.reloadData()
                        completion(true)
                    }
                } catch {
                    Task {
                        self.dismissActivityAlert()
                        self.presentErrorAlert(message: "Failed to delete email alias", error: error)
                        completion(false)
                    }
                }
            }
        }
        deleteAction.backgroundColor = .red

        let toggleAction: UIContextualAction
        if alias.status == .enabled {
            toggleAction = UIContextualAction(style: .normal, title: "Disable") { _, _, completion in
                Task {
                    do {
                        let input = DisableEmailAliasInput(emailAliasId: alias.id)
                        let updatedAlias = try await self.emailClient.disableEmailAlias(withInput: input)
                        Task {
                            if let idx = self.emailAlias.firstIndex(where: { $0.id == alias.id }) {
                                self.emailAlias[idx] = updatedAlias
                            }
                            self.filterAlias()
                            self.tableView.reloadData()
                            completion(true)
                        }
                    } catch {
                        Task {
                            self.presentErrorAlert(message: "Failed to disable email alias", error: error)
                            completion(false)
                        }
                    }
                }
            }
            toggleAction.backgroundColor = .systemOrange
        } else {
            toggleAction = UIContextualAction(style: .normal, title: "Enable") { _, _, completion in
                Task {
                    do {
                        let input = EnableEmailAliasInput(emailAliasId: alias.id)
                        let updatedAlias = try await self.emailClient.enableEmailAlias(withInput: input)
                        Task {
                            if let idx = self.emailAlias.firstIndex(where: { $0.id == alias.id }) {
                                self.emailAlias[idx] = updatedAlias
                            }
                            self.filterAlias()
                            self.tableView.reloadData()
                            completion(true)
                        }
                    } catch {
                        Task {
                            self.presentErrorAlert(message: "Failed to enable email alias", error: error)
                            completion(false)
                        }
                    }
                }
            }
            toggleAction.backgroundColor = .systemGreen
        }

        return UISwipeActionsConfiguration(actions: [deleteAction, toggleAction])
    }

    // MARK: - Swipe Actions: External Alias

    private func buildExternalAliasSwipeActions(for alias: EmailAlias, at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let actionTitles = SwipeActionResolver.actions(for: alias)
        guard !actionTitles.isEmpty else { return nil }

        let actions: [UIContextualAction] = actionTitles.compactMap { title in
            switch title {
            case "Verify":
                let action = UIContextualAction(style: .normal, title: "Verify") { [weak self] _, _, completion in
                    guard let self = self else { completion(false); return }
                    self.showVerificationInitiationAlert(for: alias, at: indexPath)
                    completion(true)
                }
                action.backgroundColor = .systemBlue
                return action

            case "Enable":
                let action = UIContextualAction(style: .normal, title: "Enable") { [weak self] _, _, completion in
                    guard let self = self else { completion(false); return }
                    Task {
                        do {
                            let input = EnableEmailAliasInput(emailAliasId: alias.id)
                            let updatedAlias = try await self.emailClient.enableEmailAlias(withInput: input)
                            Task {
                                if let idx = self.emailAlias.firstIndex(where: { $0.id == alias.id }) {
                                    self.emailAlias[idx] = updatedAlias
                                }
                                self.filterAlias()
                                self.tableView.reloadData()
                            }
                            completion(true)
                        } catch {
                            Task {
                                self.presentErrorAlert(message: "Failed to enable alias", error: error)
                            }
                            completion(false)
                        }
                    }
                }
                action.backgroundColor = .systemGreen
                return action

            case "Disable":
                let action = UIContextualAction(style: .normal, title: "Disable") { [weak self] _, _, completion in
                    guard let self = self else { completion(false); return }
                    Task {
                        do {
                            let input = DisableEmailAliasInput(emailAliasId: alias.id)
                            let updatedAlias = try await self.emailClient.disableEmailAlias(withInput: input)
                            Task {
                                if let idx = self.emailAlias.firstIndex(where: { $0.id == alias.id }) {
                                    self.emailAlias[idx] = updatedAlias
                                }
                                self.filterAlias()
                                self.tableView.reloadData()
                            }
                            completion(true)
                        } catch {
                            Task {
                                self.presentErrorAlert(message: "Failed to disable alias", error: error)
                            }
                            completion(false)
                        }
                    }
                }
                action.backgroundColor = .systemGray
                return action

            case "Delete":
                let action = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
                    guard let self = self else { completion(false); return }
                    self.presentActivityAlert(message: "Deleting Email Alias")
                    Task {
                        do {
                            let input = DeprovisionEmailAliasInput(emailAliasId: alias.id)
                            _ = try await self.emailClient.deprovisionEmailAlias(withInput: input)
                            Task {
                                self.dismissActivityAlert()
                                if let idx = self.emailAlias.firstIndex(where: { $0.id == alias.id }) {
                                    self.emailAlias.remove(at: idx)
                                }
                                self.filterAlias()
                                self.tableView.reloadData()
                            }
                            completion(true)
                        } catch {
                            Task {
                                self.dismissActivityAlert()
                                self.presentErrorAlert(message: "Failed to delete alias", error: error)
                            }
                            completion(false)
                        }
                    }
                }
                return action

            default:
                return nil
            }
        }

        let configuration = UISwipeActionsConfiguration(actions: actions)
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    // MARK: - Verification Flow

    func showVerificationInitiationAlert(for alias: EmailAlias, at indexPath: IndexPath) {
        presentActivityAlert(message: "Sending verification code...")

        Task { [weak self] in
            guard let self = self else { return }

            let input = VerifyExternalEmailAddressInput(
                emailAddress: alias.realAddress,
                emailAliasId: alias.id,
                verificationCode: nil
            )

            do {
                _ = try await self.emailClient.verifyExternalEmailAddress(withInput: input)
                Task {
                    self.dismissActivityAlert {
                        self.showCodeEntryDialog(for: alias, at: indexPath)
                    }
                }
            } catch {
                Task {
                    self.dismissActivityAlert {
                        self.presentErrorAlert(message: "Verification failed", error: error)
                    }
                }
            }
        }
    }

    func showCodeEntryDialog(for alias: EmailAlias, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "Enter Verification Code",
            message: "Enter the 6-digit code sent to your email",
            preferredStyle: .alert
        )

        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
            guard let self = self,
                  let code = alert.textFields?.first?.text else { return }
            self.submitVerificationCode(code, for: alias)
        }
        confirmAction.isEnabled = false

        alert.addTextField { textField in
            textField.placeholder = "Verification code"
            textField.keyboardType = .numberPad

            NotificationCenter.default.addObserver(
                forName: UITextField.textDidChangeNotification,
                object: textField,
                queue: .main
            ) { _ in
                let text = textField.text ?? ""
                confirmAction.isEnabled = VerificationCodeValidation.isValid(text)
            }
        }

        alert.addAction(confirmAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true)
    }

    func submitVerificationCode(_ code: String, for alias: EmailAlias) {
        presentActivityAlert(message: "Verifying...")

        Task { [weak self] in
            guard let self = self else { return }

            let input = VerifyExternalEmailAddressInput(
                emailAddress: alias.realAddress,
                emailAliasId: alias.id,
                verificationCode: code
            )

            do {
                let result = try await self.emailClient.verifyExternalEmailAddress(withInput: input)

                Task {
                    self.dismissActivityAlert()

                    if result.isVerified {
                        Task {
                            await self.loadAlias()
                        }
                        let successAlert = UIAlertController(
                            title: "Success",
                            message: "Alias verified successfully",
                            preferredStyle: .alert
                        )
                        successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(successAlert, animated: true)
                    } else {
                        let errorMessage = result.reason ?? "Verification failed"
                        let errorAlert = UIAlertController(
                            title: "Verification Failed",
                            message: errorMessage,
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(errorAlert, animated: true)
                    }
                }
            } catch {
                Task {
                    self.dismissActivityAlert()
                    self.presentErrorAlert(message: "Verification failed", error: error)
                }
            }
        }
    }
}
