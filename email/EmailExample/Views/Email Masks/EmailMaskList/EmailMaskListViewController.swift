//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoEmail

/// This View Controller presents a global list of all `EmailMask` objects for the current user.
///
/// Supports segmented filtering between internal and external mask types when external
/// masks are enabled via configuration.
///
/// - Links From:
///     - `EmailMessageListViewController`: A user taps the "Masks" button in the navigation bar.
///     - `EmailAddressListViewController`: A user taps the "Masks" button in the navigation bar.
/// - Links To:
///     - `CreateEmailMaskViewController`: If a user taps the "Create Email Mask" row, the `CreateEmailMaskViewController` will
///         be presented so the user can provision a new email mask.
///     - `UpdateEmailMaskViewController`: If a user taps an existing mask row, the `UpdateEmailMaskViewController` will be
///         presented so the user can edit the mask's metadata and expiry.
@MainActor
class EmailMaskListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets

    /// The table view that lists each email mask.
    ///
    /// If the user does not have any email masks, only the "Create Email Mask" entry will be seen.
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Supplementary

    /// Segues that are performed in `EmailMaskListViewController`.
    enum Segue: String {
        /// Used to navigate to the `CreateEmailMaskViewController`.
        case navigateToCreateEmailMask
        /// Used to navigate to the `UpdateEmailMaskViewController`.
        case navigateToUpdateEmailMask
        /// Used to navigate back to the `EmailMaskListViewController` (unwind).
        case returnToEmailMaskList
    }

    // MARK: - Properties

    /// A list of all `EmailMask` objects for the current user.
    var emailMasks: [EmailMask] = []

    /// The filtered subset of masks matching the currently selected segment.
    var filteredMasks: [EmailMask] = []

    /// Whether email masks are enabled in the service configuration.
    var masksEnabled: Bool = true

    /// Cached configuration flag indicating whether external masks are supported.
    var externalMasksEnabled: Bool = false

    /// The segmented control for switching between Internal and External mask views.
    /// Only created when `externalMasksEnabled` is true.
    var segmentedControl: UISegmentedControl?

    /// Tracks the currently selected segment (defaults to .internal).
    var selectedSegment: MaskTypeSegment = .internal

    // MARK: - Properties: Computed

    /// Email client used to manage email masks.
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
            await self.loadMasks()
        }
    }

    // MARK: - Actions

    /// Action associated with returning to this view from a segue.
    @IBAction func returnToEmailMaskList(segue: UIStoryboardSegue) {
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueType = Segue(rawValue: segue.identifier ?? "")
        switch segueType {
        case .navigateToCreateEmailMask:
            // CreateEmailMaskViewController now loads its own email addresses
            break

        case .navigateToUpdateEmailMask:
            guard let updateVC = segue.destination as? UpdateEmailMaskViewController,
                  let row = tableView.indexPathForSelectedRow?.row,
                  row < filteredMasks.count else {
                break
            }
            updateVC.emailMask = filteredMasks[row]

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

    /// Checks the email mask configuration and loads all masks for the current user.
    ///
    /// If masks are not enabled in the configuration, an informational label is displayed and the "Create" row is hidden.
    /// Also checks whether external masks are enabled to show the segmented filter control.
    func loadMasks() async {
        // Step 1: Check configuration
        var configExternalEnabled = false
        do {
            let configData = try await emailClient.getConfigurationData()
            if !configData.emailMasksEnabled {
                self.masksEnabled = false
                Task {
                    self.showMasksDisabledLabel()
                    self.tableView.reloadData()
                }
                return
            }
            configExternalEnabled = configData.externalEmailMasksEnabled
        } catch {
            Task {
                self.presentErrorAlert(message: "Failed to get email mask configuration", error: error)
            }
            return
        }

        // Step 2: Load all masks for the current user
        do {
            let input = ListEmailMasksForOwnerInput()
            let output = try await emailClient.listEmailMasksForOwner(withInput: input)
            Task {
                self.externalMasksEnabled = configExternalEnabled
                self.emailMasks = output.items
                self.configureSegmentedControl()
                self.filterMasks()
                self.tableView.reloadData()
            }
        } catch {
            Task {
                self.presentErrorAlert(message: "Failed to list email masks", error: error)
            }
        }
    }

    /// Displays an informational label indicating that email masks are not available.
    func showMasksDisabledLabel() {
        let label = UILabel()
        label.text = "Email masks are not enabled for this account."
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundView = label
    }

    // MARK: - Segmented Control

    /// Configures the segmented control based on the `externalMasksEnabled` flag.
    func configureSegmentedControl() {
        if externalMasksEnabled {
            if segmentedControl == nil {
                let control = UISegmentedControl(items: ["Internal", "External"])
                control.selectedSegmentIndex = MaskTypeSegment.internal.rawValue
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
        guard let segment = MaskTypeSegment(rawValue: sender.selectedSegmentIndex) else { return }
        selectedSegment = segment
        filterMasks()
        tableView.reloadData()
    }

    // MARK: - Filtering

    /// Filters `emailMasks` into `filteredMasks` based on the currently selected segment.
    func filterMasks() {
        if externalMasksEnabled {
            let type: EmailMask.RealAddressType = selectedSegment == .external ? .external : .internal
            filteredMasks = MaskListFilter.filter(masks: emailMasks, byType: type)
        } else {
            filteredMasks = emailMasks
        }
    }

    // MARK: - Conformance: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !masksEnabled {
            return 0
        }

        if filteredMasks.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No email masks. Tap 'Create Email Mask' to get started."
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .secondaryLabel
            emptyLabel.numberOfLines = 0
            emptyLabel.font = UIFont.preferredFont(forTextStyle: .body)
            tableView.backgroundView = emptyLabel
        } else {
            tableView.backgroundView = nil
        }

        return filteredMasks.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if indexPath.row == filteredMasks.count {
            cell = tableView.dequeueReusableCell(withIdentifier: "create", for: indexPath)
            cell.textLabel?.text = "Create Email Mask"
            cell.textLabel?.textColor = UIColor.systemBlue
            cell.accessoryView = UIImageView(image: UIImage(systemName: "plus"))
            cell.semanticContentAttribute = .forceRightToLeft
        } else {
            let mask = filteredMasks[indexPath.row]
            cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)

            var content = cell.defaultContentConfiguration()
            content.text = mask.maskAddress

            var detailParts: [String] = []
            detailParts.append(mask.realAddress)

            switch mask.status {
            case .pending:
                detailParts.append("Pending")
            case .enabled:
                detailParts.append("Enabled")
            case .disabled:
                detailParts.append("Disabled")
            case .locked:
                detailParts.append("Locked")
            }

            if let metadata = mask.metadata, !metadata.isEmpty {
                let metadataStr = metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                let truncated = metadataStr.count > 30 ? String(metadataStr.prefix(30)) + "…" : metadataStr
                detailParts.append(truncated)
            }

            if let expiresAt = mask.expiresAt {
                detailParts.append("Expires: \(expiresAt.getFormattedDate(format: "yyyy-MM-dd"))")
            }

            content.secondaryText = detailParts.joined(separator: " · ")
            content.secondaryTextProperties.color = .secondaryLabel
            content.secondaryTextProperties.font = UIFont.preferredFont(forTextStyle: .caption1)

            cell.contentConfiguration = content

            // Status tag for external masks
            if mask.realAddressType == .external {
                let statusLabel = UILabel()
                let statusColor: UIColor

                switch mask.status {
                case .pending:
                    statusLabel.text = "PENDING"
                    statusColor = MaskStatusColor.pending
                case .enabled:
                    statusLabel.text = "ENABLED"
                    statusColor = MaskStatusColor.enabled
                case .disabled:
                    statusLabel.text = "DISABLED"
                    statusColor = MaskStatusColor.disabled
                case .locked:
                    statusLabel.text = "LOCKED"
                    statusColor = MaskStatusColor.disabled
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
        if indexPath.row == filteredMasks.count {
            performSegue(withIdentifier: Segue.navigateToCreateEmailMask.rawValue, sender: self)
        } else {
            let mask = filteredMasks[indexPath.row]
            if mask.realAddressType == .external && mask.status == .pending {
                showVerificationInitiationAlert(for: mask, at: indexPath)
            } else {
                performSegue(withIdentifier: Segue.navigateToUpdateEmailMask.rawValue, sender: self)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < filteredMasks.count else {
            return nil
        }

        let mask = filteredMasks[indexPath.row]

        if mask.realAddressType == .external {
            return buildExternalMaskSwipeActions(for: mask, at: indexPath)
        }

        return buildInternalMaskSwipeActions(for: mask, at: indexPath)
    }

    // MARK: - Swipe Actions: Internal Masks

    private func buildInternalMaskSwipeActions(for mask: EmailMask, at indexPath: IndexPath) -> UISwipeActionsConfiguration {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
            self.presentActivityAlert(message: "Deleting Email Mask")
            Task {
                do {
                    let input = DeprovisionEmailMaskInput(emailMaskId: mask.id)
                    _ = try await self.emailClient.deprovisionEmailMask(withInput: input)
                    Task {
                        self.dismissActivityAlert()
                        if let idx = self.emailMasks.firstIndex(where: { $0.id == mask.id }) {
                            self.emailMasks.remove(at: idx)
                        }
                        self.filterMasks()
                        self.tableView.reloadData()
                        completion(true)
                    }
                } catch {
                    Task {
                        self.dismissActivityAlert()
                        self.presentErrorAlert(message: "Failed to delete email mask", error: error)
                        completion(false)
                    }
                }
            }
        }
        deleteAction.backgroundColor = .red

        let toggleAction: UIContextualAction
        if mask.status == .enabled {
            toggleAction = UIContextualAction(style: .normal, title: "Disable") { _, _, completion in
                Task {
                    do {
                        let input = DisableEmailMaskInput(emailMaskId: mask.id)
                        let updatedMask = try await self.emailClient.disableEmailMask(withInput: input)
                        Task {
                            if let idx = self.emailMasks.firstIndex(where: { $0.id == mask.id }) {
                                self.emailMasks[idx] = updatedMask
                            }
                            self.filterMasks()
                            self.tableView.reloadData()
                            completion(true)
                        }
                    } catch {
                        Task {
                            self.presentErrorAlert(message: "Failed to disable email mask", error: error)
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
                        let input = EnableEmailMaskInput(emailMaskId: mask.id)
                        let updatedMask = try await self.emailClient.enableEmailMask(withInput: input)
                        Task {
                            if let idx = self.emailMasks.firstIndex(where: { $0.id == mask.id }) {
                                self.emailMasks[idx] = updatedMask
                            }
                            self.filterMasks()
                            self.tableView.reloadData()
                            completion(true)
                        }
                    } catch {
                        Task {
                            self.presentErrorAlert(message: "Failed to enable email mask", error: error)
                            completion(false)
                        }
                    }
                }
            }
            toggleAction.backgroundColor = .systemGreen
        }

        return UISwipeActionsConfiguration(actions: [deleteAction, toggleAction])
    }

    // MARK: - Swipe Actions: External Masks

    private func buildExternalMaskSwipeActions(for mask: EmailMask, at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let actionTitles = SwipeActionResolver.actions(for: mask)
        guard !actionTitles.isEmpty else { return nil }

        let actions: [UIContextualAction] = actionTitles.compactMap { title in
            switch title {
            case "Verify":
                let action = UIContextualAction(style: .normal, title: "Verify") { [weak self] _, _, completion in
                    guard let self = self else { completion(false); return }
                    self.showVerificationInitiationAlert(for: mask, at: indexPath)
                    completion(true)
                }
                action.backgroundColor = .systemBlue
                return action

            case "Enable":
                let action = UIContextualAction(style: .normal, title: "Enable") { [weak self] _, _, completion in
                    guard let self = self else { completion(false); return }
                    Task {
                        do {
                            let input = EnableEmailMaskInput(emailMaskId: mask.id)
                            let updatedMask = try await self.emailClient.enableEmailMask(withInput: input)
                            Task {
                                if let idx = self.emailMasks.firstIndex(where: { $0.id == mask.id }) {
                                    self.emailMasks[idx] = updatedMask
                                }
                                self.filterMasks()
                                self.tableView.reloadData()
                            }
                            completion(true)
                        } catch {
                            Task {
                                self.presentErrorAlert(message: "Failed to enable mask", error: error)
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
                            let input = DisableEmailMaskInput(emailMaskId: mask.id)
                            let updatedMask = try await self.emailClient.disableEmailMask(withInput: input)
                            Task {
                                if let idx = self.emailMasks.firstIndex(where: { $0.id == mask.id }) {
                                    self.emailMasks[idx] = updatedMask
                                }
                                self.filterMasks()
                                self.tableView.reloadData()
                            }
                            completion(true)
                        } catch {
                            Task {
                                self.presentErrorAlert(message: "Failed to disable mask", error: error)
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
                    self.presentActivityAlert(message: "Deleting Email Mask")
                    Task {
                        do {
                            let input = DeprovisionEmailMaskInput(emailMaskId: mask.id)
                            _ = try await self.emailClient.deprovisionEmailMask(withInput: input)
                            Task {
                                self.dismissActivityAlert()
                                if let idx = self.emailMasks.firstIndex(where: { $0.id == mask.id }) {
                                    self.emailMasks.remove(at: idx)
                                }
                                self.filterMasks()
                                self.tableView.reloadData()
                            }
                            completion(true)
                        } catch {
                            Task {
                                self.dismissActivityAlert()
                                self.presentErrorAlert(message: "Failed to delete mask", error: error)
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

    func showVerificationInitiationAlert(for mask: EmailMask, at indexPath: IndexPath) {
        presentActivityAlert(message: "Sending verification code...")

        Task { [weak self] in
            guard let self = self else { return }

            let input = VerifyExternalEmailAddressInput(
                emailAddress: mask.realAddress,
                emailMaskId: mask.id,
                verificationCode: nil
            )

            do {
                _ = try await self.emailClient.verifyExternalEmailAddress(withInput: input)
                Task {
                    self.dismissActivityAlert {
                        self.showCodeEntryDialog(for: mask, at: indexPath)
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

    func showCodeEntryDialog(for mask: EmailMask, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "Enter Verification Code",
            message: "Enter the 6-digit code sent to your email",
            preferredStyle: .alert
        )

        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
            guard let self = self,
                  let code = alert.textFields?.first?.text else { return }
            self.submitVerificationCode(code, for: mask)
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

    func submitVerificationCode(_ code: String, for mask: EmailMask) {
        presentActivityAlert(message: "Verifying...")

        Task { [weak self] in
            guard let self = self else { return }

            let input = VerifyExternalEmailAddressInput(
                emailAddress: mask.realAddress,
                emailMaskId: mask.id,
                verificationCode: code
            )

            do {
                let result = try await self.emailClient.verifyExternalEmailAddress(withInput: input)

                Task {
                    self.dismissActivityAlert()

                    if result.isVerified {
                        Task {
                            await self.loadMasks()
                        }
                        let successAlert = UIAlertController(
                            title: "Success",
                            message: "Mask verified successfully",
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
