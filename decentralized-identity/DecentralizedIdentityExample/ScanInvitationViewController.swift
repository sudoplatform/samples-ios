//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import AVFoundation
import MobileCoreServices
import SudoDecentralizedIdentity

class ScanInvitationViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var walletId: String!
    var localDid: Did!
    var connectionName: String!

    private var presentedActivityAlert: UIAlertController?

    // MARK: Connection Establishment

    func handleInvitationObtained(_ invitationURLString: String) {
        // parse the invitation URL to retrieve invitation data
        guard let uri = URLComponents(string: invitationURLString),
            let base64URLEncodedInvitationData = uri.queryItems?.first(where: { $0.name == "c_i" })?.value,
            let invitationData = Data(base64URLEncoded: base64URLEncodedInvitationData) else {
                self.onFailure("Failed to decode invitation URL", error: nil)
                return
        }

        // deserialize the invitation data
        let invitation: Invitation
        do {
            invitation = try JSONDecoder().decode(Invitation.self, from: invitationData)
        } catch let error {
            self.onFailure("Failed to decode invitation", error: error)
            return
        }

        // create an exchange request
        DispatchQueue.main.async {
            self.presentedActivityAlert = self.presentActivityAlert(message: "Sending Request")
        }

        createAndTransmitExchangeRequest(inResponseTo: invitation) { exchangeRequest, newDid in
            DispatchQueue.main.async {
                self.presentedActivityAlert?.message = "Waiting for Response"
            }

            self.waitForExchangeResponse(to: exchangeRequest) { response in
                DispatchQueue.main.async {
                    self.presentedActivityAlert?.message = "Creating Pairwise"
                }

                self.acknowledgeExchangeResponse(response, did: newDid)
                self.createPairwise(exchangeRequest: exchangeRequest, exchangeResponse: response, invitation: invitation) { pairwise in
                    DispatchQueue.main.async {
                        self.dismiss(animated: true) {
                            self.performSegue(withIdentifier: "returnToWallet", sender: self)
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

    private func createAndTransmitExchangeRequest(inResponseTo invitation: Invitation, onSuccess: @escaping (ExchangeRequest, Did) -> Void) {
        // Provision a service endpoint to receive responses at.
        let relayPostboxId = UUID().uuidString
        let ourServiceEndpoint = Dependencies.firebaseRelay.serviceEndpoint(forPostboxId: relayPostboxId)

        // The invitee will provision a new DID according to the DID method spec.
        Dependencies.sudoDecentralizedIdentityClient.createDid(
            walletId: walletId,
            label: "ForPairwise-\(invitation.id)"
        ) { result in
            switch result {
            case .success(let did):
                let exchangeRequest = Dependencies.sudoDecentralizedIdentityClient.exchangeRequest(
                    did: did,
                    serviceEndpoint: ourServiceEndpoint,
                    label: self.connectionName,
                    invitation: invitation
                )

                let plaintextRequestJson: Data
                do {
                    plaintextRequestJson = try JSONEncoder().encode(exchangeRequest)
                } catch let error {
                    self.onFailure("Failed to encode exchange request", error: error)
                    return
                }

                Dependencies.sudoDecentralizedIdentityClient.packMessage(
                    walletId: self.walletId,
                    message: plaintextRequestJson,
                    recipientVerkeys: [invitation.recipientKeys[0]],
                    senderVerkey: did.verkey
                ) { result in
                    switch result {
                    case .success(let encryptedRequestJson):
                        DIDCommTransports.transmit(
                            data: encryptedRequestJson,
                            to: invitation.serviceEndpoint
                        ) { result in
                            switch result {
                            case .success:
                                onSuccess(exchangeRequest, did)
                            case .failure(let error):
                                self.onFailure("Failed to transmit exchange request", error: error)
                            }
                        }
                    case .failure(let error):
                        self.onFailure("Failed to encrypt exchange request", error: error)
                        return
                    }
                }
            case .failure(let error):
                self.onFailure("Failed to create new DID", error: error)
            }
        }
    }

    private func waitForExchangeResponse(to exchangeRequest: ExchangeRequest, onSuccess: @escaping (ExchangeResponse) -> Void) {
        let postboxId = Dependencies.firebaseRelay.postboxId(fromServiceEndpoint: exchangeRequest.connection.didDoc.service[0].endpoint)!
        Dependencies.firebaseRelay.waitForMessage(atPostboxId: postboxId, timeout: 300) { result in
            switch result {
            case .success(let encryptedResponseJson):
                Dependencies.sudoDecentralizedIdentityClient.unpackMessage(
                    walletId: self.walletId,
                    message: encryptedResponseJson
                ) { result in
                    switch result {
                    case .success(let decryptedResponseData):
                        let signedExchangeResponse: SignedExchangeResponse
                        do {
                            signedExchangeResponse = try JSONDecoder().decode(SignedExchangeResponse.self, from: Data(decryptedResponseData.message.utf8))
                        } catch let error {
                            self.onFailure("Failed to decode exchange response", error: error)
                            return
                        }

                        Dependencies.sudoDecentralizedIdentityClient.verifySignedExchangeResponse(
                            signedExchangeResponse
                        ) { result in
                            switch result {
                            case .success((let exchangeResponse, let timestamp)):
                                onSuccess(exchangeResponse)
                            case .failure(let error):
                                self.onFailure("Failed to verify signed exchange response", error: error)
                            }
                        }
                    case .failure(let error):
                        self.onFailure("Failed to decrypt exchange response", error: error)
                    }
                }
            case .failure(let error):
                self.onFailure("Failed to receive exchange response", error: error)
            }
        }
    }

    private func acknowledgeExchangeResponse(_ exchangeResponse: ExchangeResponse, did: Did) {
        let ack = Dependencies.sudoDecentralizedIdentityClient.acknowledgement(
            did: did,
            serviceEndpoint: "",
            exchangeResponse: exchangeResponse
        )
        // TODO: send the acknowledgement to the inviter.
    }

    private func createPairwise(exchangeRequest: ExchangeRequest, exchangeResponse: ExchangeResponse, invitation: Invitation, onSuccess: @escaping (Pairwise) -> Void) {
        let myDidDoc = exchangeRequest.connection.didDoc
        let theirDidDoc = exchangeResponse.connection.didDoc
        let label = invitation.label

        do {
            try KeychainDIDDocStorage().store(doc: myDidDoc, for: myDidDoc.id)
            try KeychainDIDDocStorage().store(doc: theirDidDoc, for: theirDidDoc.id)
        } catch let error {
            self.onFailure("Failed to persist DID doc", error: error)
            return
        }

        // Attempt to find a public key from the sender's DID Doc.
        // TODO: We may need to be smarter about finding the right key in the future.
        guard let recipientVerkey: String = exchangeResponse.connection.didDoc.publicKey
            .first(where: { key in
                if case .ed25519VerificationKey2018 = key.type {
                    return true
                }
                return false
            })?.specifier else {
                self.onFailure("No verkey found in recipient's DID Doc", error: nil)
                return
        }

        Dependencies.sudoDecentralizedIdentityClient.createPairwise(
            walletId: walletId,
            theirDid: theirDidDoc.id,
            theirVerkey: recipientVerkey,
            label: label,
            myDid: myDidDoc.id
        ) { result in
            switch result {
            case .success:
                Dependencies.sudoDecentralizedIdentityClient.listPairwise(walletId: self.walletId) { result in
                    switch result {
                    case .success(let pairwiseConnections):
                        guard let pairwiseConnection = pairwiseConnections.first(where: {
                            $0.myDid == myDidDoc.id && $0.theirDid == theirDidDoc.id
                        }) else {
                            self.onFailure("Failed to retrieve pairwise connection", error: nil)
                            return
                        }

                        onSuccess(pairwiseConnection)
                    case .failure(let error):
                        self.onFailure("Failed to retrieve pairwise connection", error: error)
                    }
                }
            case .failure(let error):
                self.onFailure("Failed to create pairwise connection", error: error)
            }
        }
    }

    // MARK: AVFoundation Configuration

    private let captureSessionQueue = DispatchQueue(label: "com.sudoplatform.DecentralizedIdentityExample.capturesession")
    private let metadataQueue = DispatchQueue(label: "com.sudoplatform.DecentralizedIdentityExample.capturemetadata")
    private let captureSession = AVCaptureSession()

    func startCaptureSession() -> Bool {
        let metadataOutput = AVCaptureMetadataOutput()

        guard let captureDevice = AVCaptureDevice.default(for: .video),
            let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice),
            captureSession.canAddInput(captureDeviceInput),
            captureSession.canAddOutput(metadataOutput) else {
                return false
        }

        captureSession.beginConfiguration()

        captureSession.addInput(captureDeviceInput)
        captureSession.addOutput(metadataOutput)

        guard metadataOutput.availableMetadataObjectTypes.contains(.qr) else {
            return false
        }

        metadataOutput.metadataObjectTypes = [.qr]
        metadataOutput.setMetadataObjectsDelegate(self, queue: metadataQueue)

        captureSession.commitConfiguration()

        captureSession.startRunning()

        return true
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let readableObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let string = readableObject.stringValue else {
                NSLog("Warning: Received capture metadata output but could not read string value.")
                return
        }

        captureSession.removeOutput(output)

        captureSessionQueue.async {
            self.captureSession.stopRunning()
        }

        handleInvitationObtained(string)
    }

    func requestCameraAuthorization(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined: fallthrough
        @unknown default:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
        }
    }

    // MARK: UIImagePickerController Configuration

    private func openPhotoPicker() {
        let pickerController = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            pickerController.sourceType = .camera
        } else {
            pickerController.sourceType = .photoLibrary
        }
        pickerController.mediaTypes = [kUTTypeImage as String]
        pickerController.delegate = self
        present(pickerController, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)

        guard let pickedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
            self.presentErrorAlert(message: "Failed to retrieve selected image", error: NSError())
            return
        }

        previewImageView.image = pickedImage

        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]),
            let ciImage = CIImage(image: pickedImage),
            let qrCodeFeature = (detector.features(in: ciImage).compactMap { $0 as? CIQRCodeFeature }).first,
            let string = qrCodeFeature.messageString else {
                self.presentErrorAlert(message: "Could not obtain QR code data from the selected image", error: NSError())
                return
        }

        handleInvitationObtained(string)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: View

    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var previewView: VideoCapturePreviewView!
    var hasInitializedCapture = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if hasInitializedCapture { return }
        hasInitializedCapture = true

        requestCameraAuthorization { granted in
            guard granted else {
                // fall back to a photo picker if not authorized
                DispatchQueue.main.async {
                    self.openPhotoPicker()
                }
                return
            }

            self.captureSessionQueue.async {
                let startedCaptureSession = self.startCaptureSession()
                DispatchQueue.main.async {
                    if startedCaptureSession {
                        self.previewView.isHidden = false
                        self.previewImageView.isHidden = true
                        self.previewView.session = self.captureSession
                    } else {
                        // fall back to a photo picker if capture session setup failed
                        self.openPhotoPicker()
                    }
                }
            }
        }
    }

    @IBAction func enterURLTapped(_ sender: UIBarButtonItem) {
        // Present an alert that allows the user to paste an invitation URL directly.
        let alert = UIAlertController(title: "Paste an invitation URL", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textField in })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Connect", style: .default) { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
                self.handleInvitationObtained(text)
            }
        })
        present(alert, animated: true, completion: nil)
    }
}

class VideoCapturePreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    var session: AVCaptureSession? {
        get {
            return (layer as! AVCaptureVideoPreviewLayer).session
        }
        set {
            (layer as! AVCaptureVideoPreviewLayer).session = newValue
        }
    }
}
