//
// Copyright © 2022 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoVirtualCards
import Stripe

struct CreditCardFundingSourceInput: Equatable {

    /// Card account number.
    var cardNumber: String

    /// Required expiration month value.
    var expirationMonth: Int

    /// Required expiration year value.
    var expirationYear: Int

    /// Rwquired 3 or 4 digit security code from the back of the card.
    var securityCode: String

    /// Required street address field for the cardholders legal residence.
    var address: String

    /// Optional unit number field for the cardholders legal residence.
    var unitNumber: String?

    /// Required city the address resides in.
    var city: String

    /// Required state that the city resides in.
    var state: String

    /// Required postal code for the cardholders legal residence.
    var postalCode: String

    /// The ISO2 country code the address resides in.
    var country: String

}

class StripeIntentWorker: NSObject {

    let stripeClient: STPAPIClient
    let intentParameters: STPSetupIntentConfirmParams
    let authenticationContext: STPAuthenticationContext

    init(
       fromInputDetails inputDetails: CreditCardFundingSourceInput,
       clientSecret: String,
       stripeClient: STPAPIClient,
       authenticationContext: STPAuthenticationContext
    ) {
        self.stripeClient = stripeClient
        self.authenticationContext = authenticationContext

        STPPaymentHandler.shared().apiClient = self.stripeClient

        intentParameters = STPSetupIntentConfirmParams(clientSecret: clientSecret)
        intentParameters.paymentMethodParams = StripeIntentWorker.getStripePaymentMethodParams(fromInputDetails: inputDetails)
    }

    func confirmSetupIntent() async throws -> String {
        let setupIntent: STPSetupIntent = try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.main.async {
                    let paymentHandler = STPPaymentHandler.shared()
                    paymentHandler.confirmSetupIntent(self.intentParameters, with: self.authenticationContext) { status, intent, _ in
                        switch status {
                        case .succeeded:
                            guard let intent = intent else {
                                return continuation.resume(throwing: SudoVirtualCardsError.internalError("Intent is nil on success"))
                            }
                            return continuation.resume(returning: intent)
                        case .failed:
                            let msg = "Additional Authorization failed"
                            return continuation.resume(throwing: AnyError(msg))
                        case .canceled:
                            let msg = "Additional Authorization cancelled"
                            return continuation.resume(throwing: AnyError(msg))
                        }
                    }
                }
            }

        guard let paymentMethodId = setupIntent.paymentMethodID else {
            throw SudoVirtualCardsError.internalError("Invalid Stripe Setup Intent received - no paymentMethodID found")
        }
        return paymentMethodId
    }

    // MARK: - Private: Static Helpers

    private static func getStripePaymentMethodParams(fromInputDetails inputDetails: CreditCardFundingSourceInput) -> STPPaymentMethodParams {
        let cardDetails = STPCardParams()
        cardDetails.number = inputDetails.cardNumber
        cardDetails.expMonth = UInt(inputDetails.expirationMonth)
        cardDetails.expYear = UInt(inputDetails.expirationYear)
        cardDetails.cvc = inputDetails.securityCode
        // Billing Address
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.address = STPPaymentMethodAddress()
        billingDetails.address?.line1 = inputDetails.address
        if let unitNumber = inputDetails.unitNumber {
            billingDetails.address?.line1 = "\(unitNumber) / \(inputDetails.address)"
        }
        billingDetails.address?.city = inputDetails.city
        billingDetails.address?.state = inputDetails.state
        billingDetails.address?.postalCode = inputDetails.postalCode
        billingDetails.address?.country = inputDetails.country
        // Assign
        let cardParameters = STPPaymentMethodCardParams(cardSourceParams: cardDetails)
        return STPPaymentMethodParams(card: cardParameters, billingDetails: billingDetails, metadata: nil)
    }
}
