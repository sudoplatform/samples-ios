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

    // MARK: Connection Establishment

    func createInvitationCode() {
        generateInvitationString { invitation, invitationString in
            let qrCodeImage = UIImage.qrCode(from: invitationString)

            self.qrCodeImageView.image = qrCodeImage

            self.waitForExchangeRequest(from: invitation, at: invitation.serviceEndpoint) { exchangeRequest in
                self.createAndUploadExchangeResponse(to: exchangeRequest) { exchangeResponse in
                    // TODO: wait for "Exchange Complete" message.
                    self.createPairwise(exchangeRequest: exchangeRequest, exchangeResponse: exchangeResponse) { pairwise in
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "returnToWallet", sender: self)
                        }
                    }
                }
            }
        }
    }

    private func generateInvitationString(onSuccess: @escaping (Invitation, String) -> Void) {
        let serviceEndpoint = "samplefirebase:\(UUID().uuidString)"

        Dependencies.sudoDecentralizedIdentityClient.invitation(
            walletId: walletId,
            myDid: localDid.did,
            serviceEndpoint: serviceEndpoint,
            label: self.connectionName
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let invitation):
                    guard let invitationJson = try? JSONEncoder().encode(invitation),
                        let invitationString = String(data: invitationJson, encoding: .utf8) else {
                            self.presentErrorAlert(message: "Failed to encode invitation")
                            return
                    }

                    onSuccess(invitation, invitationString)
                case .failure(let error):
                    self.presentErrorAlert(message: "Failed to create invitation", error: error)
                }
            }
        }
    }

    private func waitForExchangeRequest(from invitation: Invitation, at serviceEndpoint: String, onSuccess: @escaping (ExchangeRequest) -> Void) {
        let serviceEndpointUri = URLComponents(string: serviceEndpoint)!
        assert(serviceEndpointUri.scheme == "samplefirebase")

        let transport: ExchangeRequestTransport = FirebaseExchangeRequestTransport()
        transport.waitForExchangeRequest(at: serviceEndpointUri.path) { result in
            switch result {
            case .success(let encryptedRequestJson):
                Dependencies.sudoDecentralizedIdentityClient.decryptMessage(
                    walletId: self.walletId,
                    verkey: invitation.recipientKeys[0],
                    message: encryptedRequestJson
                ) { result in
                    switch result {
                    case .success(let decryptedRequestData):
                        guard let exchangeRequest = try? JSONDecoder().decode(ExchangeRequest.self, from: decryptedRequestData) else {
                            DispatchQueue.main.async {
                                self.presentErrorAlert(message: "Failed to decode exchange request")
                            }
                            return
                        }

                        onSuccess(exchangeRequest)
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.presentErrorAlert(message: "Failed to decrypt exchange request", error: error)
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.presentErrorAlert(message: "Failed to receive exchange response", error: error)
                }
            }
        }
    }

    private func createAndUploadExchangeResponse(to exchangeRequest: ExchangeRequest, onSuccess: @escaping (ExchangeResponse) -> Void) {
        let destinationEndpointUri = URLComponents(string: exchangeRequest.connection.didDoc.serviceEndpoint)!
        assert(destinationEndpointUri.scheme == "samplefirebase")

        // Create a new DID for the response to allow the peer to connect with us multiple times.
        // This isn't required by the spec.
        Dependencies.sudoDecentralizedIdentityClient.createDid(
            walletId: walletId,
            label: "ForPairwise-\(exchangeRequest.id)"
        ) { result in
            switch result {
            case .success(let did):
                let newEndpoint = "samplefirebase:\(UUID().uuidString)"

                let exchangeResponse = Dependencies.sudoDecentralizedIdentityClient.exchangeResponse(
                    did: did,
                    serviceEndpoint: newEndpoint,
                    label: self.connectionName,
                    exchangeRequest: exchangeRequest
                )

                guard let plaintextResponseJson = try? JSONEncoder().encode(exchangeResponse) else {
                    DispatchQueue.main.async {
                        self.presentErrorAlert(message: "Failed to encode exchange response")
                    }
                    return
                }

                Dependencies.sudoDecentralizedIdentityClient.encryptMessage(
                    walletId: self.walletId,
                    verkey: exchangeRequest.connection.didDoc.verKey,
                    message: plaintextResponseJson
                ) { result in
                    switch result {
                    case .success(let encryptedResponseJson):
                        let transport: ExchangeRequestTransport = FirebaseExchangeRequestTransport()
                        transport.sendExchangeResponse(at: destinationEndpointUri.path, response: encryptedResponseJson) { result in
                            switch result {
                            case .success:
                                onSuccess(exchangeResponse)
                            case .failure(let error):
                                DispatchQueue.main.async {
                                    self.presentErrorAlert(message: "Failed to upload exchange response", error: error)
                                }
                            }
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.presentErrorAlert(message: "Failed to encrypt exchange response", error: error)
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.presentErrorAlert(message: "Failed to create new DID", error: error)
                }
            }
        }
    }

    private func createPairwise(exchangeRequest: ExchangeRequest, exchangeResponse: ExchangeResponse, onSuccess: @escaping (Pairwise) -> Void) {
        let myDid = exchangeResponse.connection.didDoc.did
        let theirDid = exchangeRequest.connection.didDoc.did
        let label = exchangeRequest.label

        // The final service endpoint is a new endpoint where chats will be exchanged.
        let finalServiceEndpoint = exchangeResponse.connection.didDoc.serviceEndpoint

        Dependencies.sudoDecentralizedIdentityClient.createPairwise(
            walletId: walletId,
            theirDid: theirDid,
            theirVerkey: exchangeRequest.connection.didDoc.verKey,
            label: label,
            myDid: myDid,
            serviceEndpoint: finalServiceEndpoint
        ) { result in
            switch result {
            case .success:
                Dependencies.sudoDecentralizedIdentityClient.listPairwise(walletId: self.walletId) { result in
                    switch result {
                    case .success(let pairwiseConnections):
                        guard let pairwiseConnection = pairwiseConnections.first(where: {
                            $0.myDid == myDid && $0.theirDid == theirDid
                        }) else {
                            DispatchQueue.main.async {
                                self.presentErrorAlert(message: "Failed to retrieve pairwise connection")
                            }
                            return
                        }

                        onSuccess(pairwiseConnection)
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.presentErrorAlert(message: "Failed to retrieve pairwise connection", error: error)
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.presentErrorAlert(message: "Failed to create pairwise connection", error: error)
                }
            }
        }
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
}
