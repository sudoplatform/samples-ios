//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoVirtualCards
import Frames

/// This View Controller presents a form so that a user can create a Checkout credit card based `FundingSource`.
///
/// - Links From:
///     - `CreateFundingSourceMenuViewController`:  A user chooses the "Add Checkout Funding Source" option at the bottom of the table view list.
/// - Links To:
///     - `FundingSourceListViewController`: If a user successfully creates a funding source, they will be returned to this form.
class CreateCheckoutCardFundingSourceViewController: UINavigationController,
                                                     ThreedsWebViewControllerDelegate {

    // MARK: - Supplementary

    /// Segues that are performed in `CreateCheckoutCardFundingSourceViewController`.
    enum Segue: String {
        /// Used to navigate back to the `FundingSourceListViewController`.
        case returnToFundingSourceList
        /// Used to navigate back to the `CreateFundingSourceMenuListViewController`.
        case returnToCreateFundingSourceMenu
    }

    // MARK: - Properties

    var configuration: CheckoutCardClientConfiguration!
    var setupResult: ProvisionalFundingSource?
    var paymentToken: String?

    // MARK: - Properties: Computed

    /// Virtual cards client used to get and create funding sources.
    var virtualCardsClient: SudoVirtualCardsClient {
        return AppDelegate.dependencies.virtualCardsClient
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureFramesViewController()
    }

    // MARK: - Operations

    /// Validates and creates a funding source based on the view's form inputs.
    func createFundingSource(token: String) {
        Task {
            presentActivityAlert(message: "Creating funding source")

            do {
                setupResult = try await virtualCardsClient.setupFundingSource(
                    withInput: SetupFundingSourceInput(
                        type: .creditCard,
                        currency: "USD",
                        applicationData: ClientApplicationData(applicationName: "iosApplication"),
                        supportedProviders: ["checkout"])
                )

                try await completeFundingSource(token: token)
            } catch {
                dismissActivityAlert()
                presentErrorAlert(message: "Failed to create funding source", error: error)
            }
        }
    }

    func completeFundingSource(token: String?) async throws {
        do {
            print("Completing funding source with payment token \(token ?? "nil")")

            paymentToken = token
            _ = try await virtualCardsClient.completeFundingSource(
                withInput: CompleteFundingSourceInput(
                    id: setupResult!.id,
                    completionData: .checkoutCard(CheckoutCardCompletionDataInput(paymentToken: token))
                )
            )
            dismissActivityAlert {
                self.performSegue(withIdentifier: Segue.returnToFundingSourceList.rawValue, sender: self)
            }
        } catch let error as SudoVirtualCardsError {
            guard case .fundingSourceRequiresUserInteraction(let interactionData) = error else {
                throw error
            }
            guard case .checkoutCard(let interactionData) = interactionData else {
                throw error
            }

            let threeDSWebViewController = ThreedsWebViewController(
                environment: .sandbox,
                successUrl: URL(string: interactionData.successUrl)!,
                failUrl: URL(string: interactionData.failureUrl)!
            )

            threeDSWebViewController.authURL = URL(string: interactionData.redirectUrl)!
            threeDSWebViewController.delegate = self

            dismissActivityAlert()

            self.present(threeDSWebViewController, animated: true)
        }
    }

    // MARK: - Helpers: Configuration

    func configureFramesViewController() {
        let country = Country(iso3166Alpha2: "US")
        let address = Address(
            // See https://www.checkout.com/docs/testing/avs-check-testing
            addressLine1: "Test_Y",
            addressLine2: "",
            city: "Atlanta",
            state: "GA",
            zip: "30318",
            country: country)

        let billingFormData = BillingForm(
            name: "John Smith",
            address: address,
            phone: nil)

        let configuration = PaymentFormConfiguration(
            apiKey: configuration.apiKey,
            environment: .sandbox,
            supportedSchemes: [.visa, .mastercard, .americanExpress, .discover],
            billingFormData: billingFormData)

        // Style applied on Card input screen (Payment Form)
        var paymentFormStyle = DefaultPaymentFormStyle()
        paymentFormStyle.payButton.text = "Create funding source"

        // Style applied on Billing input screen (Billing Form)
        var billingFormStyle = DefaultBillingFormStyle()

        // Filter out fields from default style that are not required.
        var billingFormStyleCells: [BillingFormCell] = []
        for cell in billingFormStyle.cells {
            switch cell {
            case
                .addressLine1,
                .addressLine2,
                .city,
                .postcode,
                .country:
                billingFormStyleCells.append(cell)
            default:
                break
            }
        }

        billingFormStyle.cells = billingFormStyleCells

        // Frames Style
        let style = PaymentStyle(
            paymentFormStyle: paymentFormStyle,
            billingFormStyle: billingFormStyle)
        let completion: ((Result<TokenDetails, TokenRequestError>) -> Void) = { result in
            switch result {
            case .failure(let failure):
                if failure == .userCancelled {
                    print("User cancelled - returning to create funding source menu")
                    self.performSegue(withIdentifier: Segue.returnToCreateFundingSourceMenu.rawValue, sender: self)
                } else {
                    print("Failed, received error", failure.localizedDescription)
                }
            case .success(let tokenDetails):
                print("Success, received token", tokenDetails.token)
                self.createFundingSource(token: tokenDetails.token)
            }
        }

        let framesViewController = PaymentFormFactory.buildViewController(
            configuration: configuration,
            style: style,
            completionHandler: completion
        )

        pushViewController(framesViewController, animated: true)
    }

    // MARK: - Helpers

    /// Sets the create button in the navigation bar to enabled/disabled.
    ///
    /// - Parameter isEnabled: If true, the navigation Create button will be enabled.
    func setCreateButtonEnabled(_ isEnabled: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = isEnabled
    }

    // MARK: - Confomance: ThreedsWebViewControllerDelegate
    func threeDSWebViewControllerAuthenticationDidSucceed(_ threeDSWebViewController: ThreedsWebViewController, token: String?) {

        Task {
            do {
                _ = try await self.completeFundingSource(token: nil)

                threeDSWebViewController.dismiss(animated: true) {
                    self.performSegue(withIdentifier: Segue.returnToFundingSourceList.rawValue, sender: self)
                }
            } catch {
                threeDSWebViewController.dismiss(animated: true, completion: nil)
                presentErrorAlert(message: "Failed to create funding source", error: error)
            }
        }
    }

    func threeDSWebViewControllerAuthenticationDidFail(_ threeDSWebViewController: ThreedsWebViewController) {
        threeDSWebViewController.dismiss(animated: true, completion: nil)
        presentErrorAlert(message: "Strong authentication failed")
    }
}
