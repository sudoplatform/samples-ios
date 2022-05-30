//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoDIRelay

fileprivate extension UIImage {

    /// Generate a QR code from given string `string`.
    /// - Parameter string: The string to create a QR code from.
    /// - Returns: The QR code as a UIImage or nil if unsuccessful.
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
    
    // MARK: - Supplementary

    var connectionName: String = ""
    var myPostboxId: String = ""

    private var currentInvitationJson: Data?    
    private var peerInvitation: Invitation?
    private var relayMessagesReceived: [RelayMessage] = []
    private var messageLog: [PresentableMessage] = []
    private var onMessagesReceivedToken: SubscriptionToken?
    private var invitationMessageId: String?


    // MARK: - Properties: Computed

    var relayClient: SudoDIRelayClient {
        return AppDelegate.dependencies.sudoDIRelayClient
    }

    // MARK: - Outlets

    @IBOutlet weak var qrCodeImageView: UIImageView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        qrCodeImageView.layer.magnificationFilter = .nearest
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Task {
            await self.createInvitationCode()
        }
    }


    // MARK: - Connection Establishment

    /// Create the invitation code and listen for a response in own postbox.
    func createInvitationCode() async {
        guard let (_, invitationAsData, invitationAsString) = generateInvitation() else {
            return
        }

        let qrCodeImage = UIImage.qrCode(from: invitationAsString)

        // Store to copy later
        currentInvitationJson = invitationAsData
        qrCodeImageView.image = qrCodeImage

        await listenForResponseInPostbox {  result in
            switch result {
            case .success(let invitation):
                self.storePeerConnectionIdToCache(peerConnectionId: invitation.connectionId)
                self.storePeerPublicKeyToVault(invitation: invitation)
                self.onMessagesReceivedToken?.cancel()
                self.performSegue(withIdentifier: "navigateToConnection", sender: self)

            case .failure(let error):
                self.presentErrorAlertOnMain("Error thrown when waiting for response.", error: error)
            }
        }
    }

    ///  Generate a new public key pair via KeyManager and create an invitation containing `this.connectionId` and the newly generated public key.
    ///  When completed, return the invitation in 3 data types - Invitation, Data and as a String.
    /// - Returns: The invitation as an Invitation, Data and a String, or nil on failure

    private func generateInvitation() -> (Invitation, Data, String)? {
        do {
            try KeyManagement().createKeyPairForConnection(connectionId: myPostboxId)
            guard let publicKey = try KeyManagement().getPublicKeyForConnection(connectionId: myPostboxId) else {
                onFailure("Unable to generate public key pair for connection", error: nil)
                return nil
            }
            let invitation = Invitation(connectionId: myPostboxId, publicKey: publicKey)

            let invitationAsData = try JSONEncoder().encode(invitation)
            guard let invitationAsString = String(data: invitationAsData, encoding: .utf8) else {
                onFailure("Unable convert invitation", error: nil)
                return nil
            }
            return (invitation, invitationAsData, invitationAsString)
        } catch {
            onFailure("Unable to generate invitation to send", error: error)
            return nil
        }
    }

    /// Set up a subscription in own postbox to listen for response from peer.
    /// The peer will scan the QR code and send a HTTP POST to our postbox with their connectionId and publicKey.
    /// - Parameters:
    ///   - completion: Resolves to an Invitation if received, or nil if subscription or Invitation creation failed.
    private func listenForResponseInPostbox(completion: @escaping (Result<Invitation, Error>) -> ()) async {
        do {
        onMessagesReceivedToken = try await relayClient.subscribeToMessagesReceived(withConnectionId: myPostboxId) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let message):
                    // Must keep a strong reference to the message to keep subscription connection open
                    self.relayMessagesReceived.append(message)

                    // Attempt to decrypt cipherText and replace it with its plaintext
                    var messageCopy = message
                    let decryptedMessage = self.decryptMessageOrPresentError(packedMessage: messageCopy.cipherText)
                    messageCopy.cipherText = decryptedMessage ?? ""
                    let invitationString = messageCopy.cipherText

                    // Attempt to coerce to an Invitation object
                    guard let invitationAsData = invitationString.data(using: .utf8),
                          let invitation = try? JSONDecoder().decode(Invitation.self, from: invitationAsData) else {

                        self.presentErrorAlert(message: "Unable to decode received message", error: nil)
                        return
                    }
                    self.peerInvitation = invitation

                    // Store the message ID of this invitation, as we don't want to display it in the conversation later
                    self.invitationMessageId = message.messageId

                    completion(.success(invitation))
                case let .failure(error):
                    self.presentErrorAlert(message: "MessagesReceived subscription failure", error: error)
                    completion(.failure(error))
                }
            }
        } catch {
                self.presentErrorAlert(message: "MessagesReceived subscription failure", error: error)
            completion(.failure(error))
        }
    }

    // MARK: - Key Management

    /// Attempt to get the peer public key from the keychain corresponding to `peerConnectionId`.
    /// Display an error alert if unsuccessful.
    /// - Parameter peerConnectionId: Peer connection ID.
    /// - Returns: Peer public key or nil.
    private func getPeerPublicKeyFromVault(peerConnectionId: String) -> String? {
        guard let publicKey = try? KeyManagement().getPublicKeyForConnection(connectionId: peerConnectionId) else {
            onFailure("Failed to retrieve peer's public key pair", error: nil)
            return nil
        }
        return publicKey
    }

    /// Attempt to store the `peerConnectionId` in the KeychainConnectionStorage.
    /// Displays an error alert if unsuccessful.
    /// - Parameter peerConnectionId: Peer connection ID to store.
    private func storePeerConnectionIdToCache(peerConnectionId: String) {
        do {
            try KeychainConnectionStorage().store(peerConnectionId: peerConnectionId, for: myPostboxId)
        } catch {
            onFailure("Failed to store peer key pair to cache", error: error)
        }
    }

    /// Attempt to store the peer public key given by `invitation` via KeyManager.
    /// Display an errort alert if unsuccessful.
    /// - Parameter invitation: Invitation containing the peer's connectionId and publicKey.
    private func storePeerPublicKeyToVault(invitation: Invitation) {
        do {
            // peer connection id is wrong
            try KeyManagement().storePublicKeyOfPeer(
                peerConnectionId: invitation.connectionId,
                base64PublicKey: invitation.publicKey
            )
        } catch {
            onFailure("Failed to store peer key pair to vault", error: error)
        }
    }

    /// Attempt to decrypt `cipherText` using own private key stored via KeyManager, and the embedded AES key.
    /// Displays an error alert if unsuccessful.
    /// - Parameter packedMessage: Packed messge as a string.
    /// - Returns: The decrypted text or nil.
    func decryptMessageOrPresentError(packedMessage: String) -> String? {
        do {
            // The message was sent as a string representation of the data
            return try KeyManagement().unpackEncryptedMessageForConnection(
                connectionId: myPostboxId,
                encryptedPayloadString: packedMessage
            )
        } catch {
            presentErrorAlertOnMain("Unable to decrypt received message", error: error)
            return nil
        }
    }

    // MARK: - View

    /// Present an error alert containing `message` and the `error`.
    /// - Parameters:
    ///   - message: Message to display.
    ///   - error: Error containing a `localizedDescription` to display.
    private func onFailure(_ message: String, error: Error?) {
        if self.presentedViewController != nil {
            self.dismiss(animated: true) {
                self.presentErrorAlert(message: message, error: error)
            }
        } else {
            self.presentErrorAlert(message: message, error: error)
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToConnection":
            /// Subscription is closed upon segue due to no more strong references
            let destination = segue.destination as! ConnectionViewController
            destination.myPostboxId = myPostboxId
            destination.messageLog = messageLog
            destination.invitationMessageId = invitationMessageId
        default:
            break
        }
    }
}
