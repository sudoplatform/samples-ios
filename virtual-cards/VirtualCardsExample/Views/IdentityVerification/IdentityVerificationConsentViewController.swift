//
// Copyright © 2025 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoIdentityVerification

/// This View Controller presents a consent screen for Secure ID Verification.
///
/// - Links From:
///     - `MainMenuViewController`: A user taps the "Secure ID Verification" button.
class IdentityVerificationConsentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets

    /// Table view that lists consent information.
    @IBOutlet weak var tableView: UITableView!

    /// Shows supplementary information to the consent form.
    @IBOutlet weak var tableFooterView: UIView!

    /// Label displaying the consent status.
    @IBOutlet weak var statusLabel: UILabel!

    // MARK: - Properties

    /// The consent requirement status
    private var isConsentRequired: Bool = false

    /// The fetched consent content
    private var consentContent: IdentityDataProcessingConsentContent?

    /// The consent status from the server
    private var consentStatus: IdentityDataProcessingConsentStatus?

    /// Enum to identify different cell types
    private enum CellType {
        case consentStatus
        case fetchButton
        case consentContent
        case provideConsentButton
        case withdrawConsentButton
    }

    /// Array defining the structure of the table view
    private var tableStructure: [CellType] = [.consentStatus, .fetchButton, .consentContent]

    // MARK: - Properties: Computed

    /// Sudo identity verification client used to verify identity.
    var verificationClient: SudoIdentityVerificationClient {
        return AppDelegate.dependencies.identityVerificationClient
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureTableView()

        // Check if consent is required
        Task {
            await checkConsentRequirement()
        }
    }

    // MARK: - Operations

    /// Checks if consent is required for identity verification in the current environment
    @MainActor private func checkConsentRequirement() async {
        presentActivityAlert(message: "Checking consent requirement")

        do {
            isConsentRequired = try await verificationClient.isConsentRequiredForVerification()

            // Also fetch the current consent status
            await fetchConsentStatus()

            // Update the consent status
            updateConsentStatus()
            updateFooterWithConsentStatus()

            // Refresh the table view with consent information
            tableView.reloadData()
            dismissActivityAlert()
        } catch {
            dismissActivityAlert()
            presentErrorAlert(message: "Failed to check consent requirement", error: error)
        }
    }

    /// Fetches the current consent status from the server
    @MainActor private func fetchConsentStatus() async {
        do {
            consentStatus = try await verificationClient.getIdentityDataProcessingConsentStatus()
        } catch {
            // Don't show error for consent status fetch - it might not exist yet
            consentStatus = nil
        }
    }

    /// Fetches the consent content from the server
    @MainActor private func fetchConsentContent() async {
        presentActivityAlert(message: "Fetching consent content")

        do {
            let consentContentInput = IdentityDataProcessingConsentContentInput(preferredContentType: "text/html", preferredLanguage: "en-AU")
            consentContent = try await verificationClient.getIdentityDataProcessingConsentContent(input: consentContentInput)

            // Update the table structure to include the appropriate button based on consent status
            updateTableStructure()

            // Update the table view to show the consent content and appropriate button
            tableView.reloadData()

            dismissActivityAlert()
        } catch {
            dismissActivityAlert()
            presentErrorAlert(message: "Failed to fetch consent content", error: error)
        }
    }

    /// Provides consent for identity data processing
    @MainActor private func provideConsent() async {
        guard let consentContent = consentContent else {
            presentErrorAlert(message: "No consent content available",
                              error: NSError(domain: "ConsentError",
                                             code: 1,
                                             userInfo: [NSLocalizedDescriptionKey: "Please fetch consent content before providing consent"]))
            return
        }

        presentActivityAlert(message: "Providing consent")

        do {
            let consentInput = IdentityDataProcessingConsentInput(content: consentContent.content, contentType: consentContent.contentType, language: consentContent.language)

            // Call the verification client to provide consent
            let result = try await verificationClient.provideIdentityDataProcessingConsent(input: consentInput)

            // Check if the consent was actually processed
            if result.processed {
                print("Consent provided and processed successfully")

                // Refresh the consent status after providing consent to verify it was actually set
                await fetchConsentStatus()
                updateFooterWithConsentStatus()

                dismissActivityAlert()

                // Show success message
                let alert = UIAlertController(title: "Success",
                                            message: "Consent has been provided and processed successfully",
                                            preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            } else {
                print("Consent was submitted but not processed")

                // Still refresh the consent status
                await fetchConsentStatus()
                updateFooterWithConsentStatus()

                dismissActivityAlert()

                // Show warning if consent was not processed
                let alert = UIAlertController(title: "Warning",
                                            message: "Consent was submitted but was not processed by the server. Please try again or contact support.",
                                            preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }

            // Update the table to reflect the current state
            updateTableStructure()
            tableView.reloadData()

        } catch let error as NSError {
            dismissActivityAlert()

            // Provide more detailed error messages based on error type
            let errorMessage: String
            if error.domain == "SudoIdentityVerificationErrorDomain" {
                switch error.code {
                case 400:
                    errorMessage = "Invalid consent data provided. Please try fetching the consent content again."
                case 401:
                    errorMessage = "You are not authorized to provide consent. Please check your authentication."
                case 403:
                    errorMessage = "Consent provision is not allowed for your account."
                case 404:
                    errorMessage = "Consent service not found. Please try again later."
                case 409:
                    errorMessage = "Consent has already been provided."
                case 500...599:
                    errorMessage = "Server error occurred while providing consent. Please try again later."
                default:
                    errorMessage = "Failed to provide consent: \(error.localizedDescription)"
                }
            } else {
                errorMessage = "Failed to provide consent: \(error.localizedDescription)"
            }

            presentErrorAlert(message: errorMessage, error: error)

            // Log the error for debugging
            print("Error providing consent: \(error)")
        } catch {
            dismissActivityAlert()

            // Generic error handling for non-NSError types
            let errorMessage = "An unexpected error occurred while providing consent: \(error.localizedDescription)"
            presentErrorAlert(message: errorMessage, error: error)

            print("Unexpected error providing consent: \(error)")
        }
    }

    /// Withdraws consent for identity data processing
    @MainActor private func withdrawConsent() async {
        presentActivityAlert(message: "Withdrawing consent")

        do {
            // Call the verification client to withdraw consent
            let result = try await verificationClient.withdrawIdentityDataProcessingConsent()

            // Check if the consent withdrawal was actually processed
            if result.processed {
                print("Consent withdrawn and processed successfully")

                // Refresh the consent status after withdrawing consent
                await fetchConsentStatus()
                updateFooterWithConsentStatus()

                dismissActivityAlert()

                // Show success message
                let alert = UIAlertController(title: "Success",
                                            message: "Consent has been withdrawn and processed successfully",
                                            preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            } else {
                print("Consent withdrawal was submitted but not processed")

                // Still refresh the consent status
                await fetchConsentStatus()
                updateFooterWithConsentStatus()

                dismissActivityAlert()

                // Show warning if consent withdrawal was not processed
                let alert = UIAlertController(title: "Warning",
                                            message: "Consent withdrawal was submitted but was not processed by the server. Please try again or contact support.",
                                            preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }

            // Update the table to reflect the current state
            updateTableStructure()
            tableView.reloadData()

        } catch let error as NSError {
            dismissActivityAlert()

            // Provide more detailed error messages based on error type
            let errorMessage: String
            if error.domain == "SudoIdentityVerificationErrorDomain" {
                switch error.code {
                case 400:
                    errorMessage = "Invalid request to withdraw consent."
                case 401:
                    errorMessage = "You are not authorized to withdraw consent. Please check your authentication."
                case 403:
                    errorMessage = "Consent withdrawal is not allowed for your account."
                case 404:
                    errorMessage = "No consent found to withdraw, or consent service not found."
                case 409:
                    errorMessage = "Consent has already been withdrawn."
                case 500...599:
                    errorMessage = "Server error occurred while withdrawing consent. Please try again later."
                default:
                    errorMessage = "Failed to withdraw consent: \(error.localizedDescription)"
                }
            } else {
                errorMessage = "Failed to withdraw consent: \(error.localizedDescription)"
            }

            presentErrorAlert(message: errorMessage, error: error)

            // Log the error for debugging
            print("Error withdrawing consent: \(error)")
        } catch {
            dismissActivityAlert()

            // Generic error handling for non-NSError types
            let errorMessage = "An unexpected error occurred while withdrawing consent: \(error.localizedDescription)"
            presentErrorAlert(message: errorMessage, error: error)

            print("Unexpected error withdrawing consent: \(error)")
        }
    }

    // MARK: - Helpers: Configuration

    /// Configures the view.
    private func configureView() {
        title = "Secure ID Verification Consent"
        statusLabel.text = "Checking consent requirement..."
    }

    /// Configures the table view used to display the consent information.
    private func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "consentCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "contentCell")

        // Make sure we have a properly sized footer view with enough height for both labels
        if let footerView = tableFooterView {
            // We need to ensure the footer has the correct width (matching the table)
            // and update its frame after the view layout has been established
            // Increased height to accommodate both status labels
            footerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 200)
            tableView.tableFooterView = footerView

            // Add some initial content to the table view so it's visible before the API call completes
            tableView.reloadData()
        }
    }

    /// Updates the consent status label based on the consent requirement
    private func updateConsentStatus() {
        if isConsentRequired {
            statusLabel.text = "Consent is required for identity verification"
            statusLabel.textColor = .systemRed
        } else {
            statusLabel.text = "Consent is not required"
            statusLabel.textColor = .systemGreen
        }
    }

    /// Updates the table structure based on current state (consent content and consent status)
    private func updateTableStructure() {
        var newStructure: [CellType] = [.consentStatus, .fetchButton, .consentContent]

        // Only show buttons if consent content has been fetched
        if consentContent != nil {
            // Show both buttons regardless of consent status
            newStructure.append(.provideConsentButton)
            newStructure.append(.withdrawConsentButton)
        }

        tableStructure = newStructure
    }

    /// Updates the footer view with the current consent status
    private func updateFooterWithConsentStatus() {
        guard let tableFooterView = tableFooterView else { return }

        // Remove any existing consent status labels
        tableFooterView.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }

        // Create and add a label for consent status
        let consentStatusLabel = UILabel()
        consentStatusLabel.tag = 999 // Use a tag to identify this label
        consentStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        consentStatusLabel.font = UIFont.systemFont(ofSize: 13) // Slightly smaller font
        consentStatusLabel.numberOfLines = 2 // Allow wrapping if needed
        consentStatusLabel.textAlignment = .center

        if let consentStatus = consentStatus {
            // Check if consent has been provided based on the status
            let hasConsent = consentStatus.consented
            consentStatusLabel.text = "Consent Status: \(hasConsent ? "Provided" : "Not Provided")"
            consentStatusLabel.textColor = hasConsent ? .systemGreen : .systemOrange
        } else {
            consentStatusLabel.text = "Consent Status: Unknown"
            consentStatusLabel.textColor = .systemGray
        }

        tableFooterView.addSubview(consentStatusLabel)

        // Add constraints with more generous spacing and explicit height constraint
        NSLayoutConstraint.activate([
            consentStatusLabel.centerXAnchor.constraint(equalTo: tableFooterView.centerXAnchor),
            consentStatusLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 32), // Increased spacing
            consentStatusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: tableFooterView.leadingAnchor, constant: 20),
            consentStatusLabel.trailingAnchor.constraint(lessThanOrEqualTo: tableFooterView.trailingAnchor, constant: -20),
            consentStatusLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 40) // Explicit max height
        ])
    }

    // MARK: - Conformance: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableStructure.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellType = tableStructure[indexPath.row]

        switch cellType {
        case .consentStatus:
            let cell = tableView.dequeueReusableCell(withIdentifier: "consentCell", for: indexPath)
            cell.textLabel?.text = "Consent Required: \(isConsentRequired ? "Yes" : "No")"
            cell.textLabel?.textColor = isConsentRequired ? .systemRed : .systemGreen
            cell.selectionStyle = .none
            cell.accessoryType = .none
            return cell

        case .fetchButton:
            let cell = tableView.dequeueReusableCell(withIdentifier: "consentCell", for: indexPath)
            cell.textLabel?.text = "Fetch Consent Content"
            cell.textLabel?.textColor = .systemBlue
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
            return cell

        case .consentContent:
            let cell = tableView.dequeueReusableCell(withIdentifier: "contentCell", for: indexPath)

            // Remove any existing subviews
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }

            if let content = consentContent?.content {
                // Create a text view to display the full content
                let textView = UITextView()
                textView.text = content
                textView.isEditable = false
                textView.font = UIFont.systemFont(ofSize: 14)
                textView.backgroundColor = UIColor.systemBackground
                textView.layer.borderColor = UIColor.systemGray4.cgColor
                textView.layer.borderWidth = 1
                textView.layer.cornerRadius = 8
                textView.translatesAutoresizingMaskIntoConstraints = false

                // Calculate approximate number of lines in the content
                let lineHeight = textView.font?.lineHeight ?? 20
                let approximateLines = content.components(separatedBy: .newlines).count
                let hasMoreThan10Lines = approximateLines > 10

                // Enable/disable scrolling based on line count
                textView.isScrollEnabled = hasMoreThan10Lines
                textView.showsVerticalScrollIndicator = hasMoreThan10Lines

                cell.contentView.addSubview(textView)

                // Set up constraints for the text view
                NSLayoutConstraint.activate([
                    textView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                    textView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                    textView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                    textView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
                    textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
                ])

                cell.selectionStyle = .none
            } else {
                // Create a label for "no content" state
                let label = UILabel()
                label.text = "No content fetched yet"
                label.textColor = .systemGray
                label.textAlignment = .center
                label.font = UIFont.systemFont(ofSize: 16)
                label.translatesAutoresizingMaskIntoConstraints = false

                cell.contentView.addSubview(label)

                NSLayoutConstraint.activate([
                    label.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                    label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                    label.topAnchor.constraint(greaterThanOrEqualTo: cell.contentView.topAnchor, constant: 20),
                    label.bottomAnchor.constraint(lessThanOrEqualTo: cell.contentView.bottomAnchor, constant: -20)
                ])

                cell.selectionStyle = .none
            }

            return cell
        case .provideConsentButton:
            let cell = tableView.dequeueReusableCell(withIdentifier: "consentCell", for: indexPath)
            cell.textLabel?.text = "Provide Consent"
            cell.textLabel?.textColor = .systemBlue
            cell.selectionStyle = .default
            cell.accessoryType = .checkmark
            return cell
        case .withdrawConsentButton:
            let cell = tableView.dequeueReusableCell(withIdentifier: "consentCell", for: indexPath)
            cell.textLabel?.text = "Withdraw Consent"
            cell.textLabel?.textColor = .systemBlue
            cell.selectionStyle = .default
            cell.accessoryType = .checkmark
            return cell
        }
    }

    // MARK: - Conformance: UITableViewDelegate

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Consent Information"
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellType = tableStructure[indexPath.row]

        switch cellType {
        case .consentStatus, .fetchButton:
            return UITableView.automaticDimension
        case .consentContent:
            // Return a larger height for content cells to accommodate the text view
            return consentContent?.content != nil ? 220 : 60
        case .provideConsentButton, .withdrawConsentButton:
            return 60
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellType = tableStructure[indexPath.row]

        switch cellType {
        case .consentStatus, .fetchButton:
            return 44
        case .consentContent:
            return consentContent?.content != nil ? 220 : 60
        case .provideConsentButton, .withdrawConsentButton:
            return 60
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Handle cell selection
        switch tableStructure[indexPath.row] {
        case .consentStatus:
            // Do nothing, status is displayed
            break
        case .fetchButton:
            // Fetch the consent content when the button cell is tapped
            Task {
                await fetchConsentContent()
            }
        case .consentContent:
            // No action needed - content is displayed inline
            break
        case .provideConsentButton:
            // Handle provide consent action
            Task {
                await provideConsent()
            }
            break
        case .withdrawConsentButton:
            // Handle withdraw consent action
            Task {
                await withdrawConsent()
            }
            break
        }
    }
}
