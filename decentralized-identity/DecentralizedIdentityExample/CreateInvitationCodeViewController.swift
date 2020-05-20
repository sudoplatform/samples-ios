//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoDecentralizedIdentity

fileprivate extension UIImage {
    static func qrCode(from string: String) -> UIImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }

        filter.setValue(string.data(using: .utf8), forKey: "inputMessage")

        guard let outputImage = filter.outputImage else {
            return nil
        }

        return UIImage(ciImage: outputImage)
    }
}

class CreateInvitationCodeViewController: UIViewController {
    // MARK: Data

    var walletId: String!
    var localDid: Did!
    var connectionName: String!

    private var currentInvitationJson: Data?
    private var presentedActivityAlert: UIAlertController?

    // MARK: Connection Establishment

    func createInvitationCode() {
        generateInvitationString { invitation, invitationData, invitationURL, mediatorPostboxId in
            let qrCodeImage = UIImage.qrCode(from: invitationURL)

            self.currentInvitationJson = invitationData
            self.qrCodeImageView.image = qrCodeImage

            self.waitForExchangeRequest(from: invitation, at: mediatorPostboxId) { exchangeRequest in
                DispatchQueue.main.async {
                    self.presentedActivityAlert = self.presentActivityAlert(message: "Sending Response")
                }

                self.createAndTransmitExchangeResponse(to: exchangeRequest) { exchangeResponse in
                    // TODO: wait for "Exchange Complete" message.
                    DispatchQueue.main.async {
                        self.presentedActivityAlert?.message = "Creating Pairwise"
                    }

                    self.createPairwise(exchangeRequest: exchangeRequest, exchangeResponse: exchangeResponse) { pairwise in
                        DispatchQueue.main.async {
                            self.dismiss(animated: true) {
                                self.performSegue(withIdentifier: "returnToWallet", sender: self)
                            }
                        }
                    }
                }
            }
        }
    }

    private func onFailure(_ message: String, error: Error?) {
        DispatchQueue.main.async {
            if self.presentedActivityAlert != nil {
                self.dismiss(animated: true) {
                    self.presentErrorAlert(message: message, error: error)
                }
            } else {
                self.presentErrorAlert(message: message, error: error)
            }
        }
    }

    private func generateInvitationString(onSuccess: @escaping (Invitation, Data, String, String) -> Void) {
        let mediatorPostboxId = UUID().uuidString
        let serviceEndpoint = Dependencies.firebaseRelay.serviceEndpoint(forPostboxId: mediatorPostboxId)

        Dependencies.sudoDecentralizedIdentityClient.invitation(
            walletId: walletId,
            myDid: localDid.did,
            serviceEndpoint: serviceEndpoint,
            label: self.connectionName,
            imageURL: "https://sudoplatform.com/wp-content/themes/sudo-2020/content/dropdown/sudo-identity-menu.png"
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let invitation):
                    let invitationJson: Data
                    do {
                        let encoder = JSONEncoder()
                        encoder.outputFormatting = [.withoutEscapingSlashes]
                        invitationJson = try encoder.encode(invitation)
                    } catch let error {
                        self.onFailure("Failed to encode invitation", error: error)
                        return
                    }

                    // Encode the invitation JSON using the Standard Invitation Encoding:
                    // https://github.com/hyperledger/aries-rfcs/tree/master/features/0023-did-exchange#standard-invitation-encoding
                    // The base URL here is arbitrary - we don't have iOS Associated Domains set up anyway.
                    var invitationURL = URLComponents(string: "https://ssisample.sudoplatform.com")!
                    invitationURL.queryItems = [URLQueryItem(name: "c_i", value: invitationJson.base64URLEncodedString())]

                    guard let invitationURLString = invitationURL.string else {
                        self.onFailure("Failed to encode invitation URL", error: nil)
                        return
                    }

                    onSuccess(invitation, invitationJson, invitationURLString, mediatorPostboxId)
                case .failure(let error):
                    self.onFailure("Failed to create invitation", error: error)
                }
            }
        }
    }

    private func waitForExchangeRequest(from invitation: Invitation, at mediatorPostboxId: String, onSuccess: @escaping (ExchangeRequest) -> Void) {

        Dependencies.firebaseRelay.waitForMessage(atPostboxId: mediatorPostboxId, timeout: 3600) { result in
            switch result {
            case .success(let encryptedRequestJson):
                Dependencies.sudoDecentralizedIdentityClient.unpackMessage(
                    walletId: self.walletId,
                    message: encryptedRequestJson
                ) { result in
                    switch result {
                    case .success(let decryptedRequestData):
                        let exchangeRequest: ExchangeRequest
                        do {
                            exchangeRequest = try JSONDecoder().decode(ExchangeRequest.self, from: Data(decryptedRequestData.message.utf8))
                        } catch let error {
                            self.onFailure("Failed to decode exchange request", error: error)
                            return
                        }

                        onSuccess(exchangeRequest)
                    case .failure(let error):
                        self.onFailure("Failed to decrypt exchange request", error: error)
                    }
                }
            case .failure(let error):
                self.onFailure("Failed to receive exchange request", error: error)
            }
        }
    }

    private func createAndTransmitExchangeResponse(to exchangeRequest: ExchangeRequest, onSuccess: @escaping (ExchangeResponse) -> Void) {
        // Create a new DID for the response to allow the peer to connect with us multiple times.
        // This isn't required by the spec.
        Dependencies.sudoDecentralizedIdentityClient.createDid(
            walletId: walletId,
            label: "ForPairwise-\(exchangeRequest.id)"
        ) { result in
            switch result {
            case .success(let did):
                // Create a new service endpoint for chatting.
                let chatPostboxId = UUID().uuidString
                let chatServiceEndpoint = Dependencies.firebaseRelay.serviceEndpoint(forPostboxId: chatPostboxId)

                let unsignedExchangeResponse = Dependencies.sudoDecentralizedIdentityClient.exchangeResponse(
                    did: did,
                    serviceEndpoint: chatServiceEndpoint,
                    label: self.connectionName,
                    exchangeRequest: exchangeRequest
                )

                Dependencies.sudoDecentralizedIdentityClient.signExchangeResponse(
                    walletId: self.walletId,
                    exchangeResponse: unsignedExchangeResponse
                ) { result in
                    switch result {
                    case .success(let signedExchangeResponse):
                        let signedResponseJson: Data
                        do {
                            let encoder = JSONEncoder()
                            encoder.outputFormatting = [.withoutEscapingSlashes]
                            signedResponseJson = try encoder.encode(signedExchangeResponse)
                        } catch let error {
                            self.onFailure("Failed to encode exchange response", error: error)
                            return
                        }

                        // Attempt to find a public key from the sender's DID Doc.
                        // TODO: We may need to be smarter about finding the right key in the future.
                        let recipientVerkeys: [String] = exchangeRequest.connection.didDoc.publicKey.compactMap { key -> String? in
                            guard case .ed25519VerificationKey2018 = key.type else {
                                return nil
                            }
                            return key.specifier
                        }

                        guard !recipientVerkeys.isEmpty else {
                            self.onFailure("No verkeys found in recipient's DID Doc", error: nil)
                            return
                        }

                        // Attempt to find an endpoint from the sender's DID Doc.
                        // TODO: We may need to be smarter about finding the right endpoint in the future.
                        guard let recipientService = exchangeRequest.connection.didDoc.service
                            .first(where: { ["http", "https"].contains(URL(string: $0.endpoint)?.scheme) }) else {
                                self.onFailure("No supported service endpoint found in recipient's DID Doc", error: nil)
                                return
                        }

                        Dependencies.sudoDecentralizedIdentityClient.packMessage(
                            walletId: self.walletId,
                            message: signedResponseJson,
                            recipientVerkeys: recipientVerkeys,
                            senderVerkey: did.verkey
                        ) { result in
                            switch result {
                            case .success(let responseEncryptedForRecipient):
                                DecentralizedIdentityExample.encryptForRoutingKeys(
                                    walletId: self.walletId,
                                    message: responseEncryptedForRecipient,
                                    to: recipientVerkeys[0],
                                    routingKeys: ArraySlice(recipientService.routingKeys)
                                ) { result in
                                    switch result {
                                    case .success(let encryptedResponse):
                                        let encryptedResponseJson: Data
                                        do {
                                            let encoder = JSONEncoder()
                                            encoder.outputFormatting = [.withoutEscapingSlashes]
                                            encryptedResponseJson = try encoder.encode(encryptedResponse)
                                        } catch let error {
                                            self.onFailure("Failed to encode packed data", error: error)
                                            return
                                        }

                                        DIDCommTransports.transmit(
                                            data: encryptedResponseJson,
                                            to: recipientService.endpoint
                                        ) { result in
                                            switch result {
                                            case .success:
                                                onSuccess(unsignedExchangeResponse)
                                            case .failure(let error):
                                                self.onFailure("Failed to transmit exchange response", error: error)
                                            }
                                        }
                                    case .failure(let error):
                                        self.onFailure("Failed to encrypt response for routing keys", error: error)
                                    }
                                }
                            case .failure(let error):
                                self.onFailure("Failed to encrypt exchange response", error: error)
                            }
                        }
                    case .failure(let error):
                        self.onFailure("Failed to sign exchange response", error: error)
                    }
                }
            case .failure(let error):
                self.onFailure("Failed to create new DID", error: error)
            }
        }
    }

    private func createPairwise(exchangeRequest: ExchangeRequest, exchangeResponse: ExchangeResponse, onSuccess: @escaping (Pairwise) -> Void) {
        DecentralizedIdentityExample.createPairwise(
            walletId: walletId,
            label: exchangeRequest.label,
            myDid: exchangeResponse.connection.did,
            myDidDoc: exchangeResponse.connection.didDoc,
            theirDid: exchangeRequest.connection.did,
            theirDidDoc: exchangeRequest.connection.didDoc,
            onSuccess: onSuccess,
            onFailure: self.onFailure
        )
    }

    // MARK: View

    @IBOutlet weak var connectionNameLabel: UILabel!
    @IBOutlet weak var qrCodeImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        qrCodeImageView.layer.magnificationFilter = .nearest
        connectionNameLabel.text = connectionName

        createInvitationCode()
    }

    @IBAction func copyRawInvitation() {
        UIPasteboard.general.string = currentInvitationJson.flatMap { String(data: $0, encoding: .utf8) }
    }
}
