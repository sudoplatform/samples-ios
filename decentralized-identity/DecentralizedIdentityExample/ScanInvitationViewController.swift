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

    // MARK: Connection Establishment

    func handleInvitationObtained(_ invitationString: String) {
        // deserialize the invitation data
        guard let invitationJson = invitationString.data(using: .utf8),
            let invitation = try? JSONDecoder().decode(Invitation.self, from: invitationJson) else {
                DispatchQueue.main.async {
                    self.presentErrorAlert(message: "Failed to decode invitation")
                }
                return
        }

        // create an exchange request
        createAndUploadExchangeRequest(for: invitation) { exchangeRequest, newDid in
            self.waitForExchangeResponse(to: exchangeRequest) { response in
                self.acknowledgeExchangeResponse(response, did: newDid)
                self.createPairwise(exchangeRequest: exchangeRequest, exchangeResponse: response, invitation: invitation) { pairwise in
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "returnToWallet", sender: self)
                    }
                }
            }
        }
    }

    private func createAndUploadExchangeRequest(for invitation: Invitation, onSuccess: @escaping (ExchangeRequest, Did) -> Void) {
        let destinationEndpointUri = URLComponents(string: invitation.serviceEndpoint)!
        assert(destinationEndpointUri.scheme == "samplefirebase")

        // The invitee will provision a new DID according to the DID method spec.
        Dependencies.sudoDecentralizedIdentityClient.createDid(
            walletId: walletId,
            label: "ForPairwise-\(invitation.id)"
        ) { result in
            switch result {
            case .success(let did):
                let exchangeRequest = Dependencies.sudoDecentralizedIdentityClient.exchangeRequest(
                    did: did,
                    serviceEndpoint: invitation.serviceEndpoint,
                    label: self.connectionName,
                    invitation: invitation
                )

                guard let plaintextRequestJson = try? JSONEncoder().encode(exchangeRequest) else {
                    DispatchQueue.main.async {
                        self.presentErrorAlert(message: "Failed to encode exchange request")
                    }
                    return
                }

                Dependencies.sudoDecentralizedIdentityClient.encryptMessage(
                    walletId: self.walletId,
                    verkey: invitation.recipientKeys[0],
                    message: plaintextRequestJson
                ) { result in
                    switch result {
                    case .success(let encryptedRequestJson):
                        let transport: ExchangeRequestTransport = FirebaseExchangeRequestTransport()
                        transport.sendExchangeRequest(at: destinationEndpointUri.path, request: encryptedRequestJson) { result in
                            switch result {
                            case .success:
                                onSuccess(exchangeRequest, did)
                            case .failure(let error):
                                DispatchQueue.main.async {
                                    self.presentErrorAlert(message: "Failed to upload exchange request", error: error)
                                }
                            }
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.presentErrorAlert(message: "Failed to encrypt exchange request", error: error)
                        }
                        return
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.presentErrorAlert(message: "Failed to create new DID", error: error)
                }
            }
        }
    }

    private func waitForExchangeResponse(to exchangeRequest: ExchangeRequest, onSuccess: @escaping (ExchangeResponse) -> Void) {
        let serviceEndpointUri = URLComponents(string: exchangeRequest.connection.didDoc.serviceEndpoint)!
        assert(serviceEndpointUri.scheme == "samplefirebase")

        let transport: ExchangeRequestTransport = FirebaseExchangeRequestTransport()
        transport.waitForExchangeResponse(at: serviceEndpointUri.path) { result in
            switch result {
            case .success(let encryptedResponseJson):
                Dependencies.sudoDecentralizedIdentityClient.decryptMessage(
                    walletId: self.walletId,
                    verkey: exchangeRequest.connection.didDoc.verKey,
                    message: encryptedResponseJson
                ) { result in
                    switch result {
                    case .success(let decryptedResponseData):
                        guard let exchangeResponse = try? JSONDecoder().decode(ExchangeResponse.self, from: decryptedResponseData) else {
                                DispatchQueue.main.async {
                                    self.presentErrorAlert(message: "Failed to decode exchange response")
                                }
                                return
                        }

                        onSuccess(exchangeResponse)
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.presentErrorAlert(message: "Failed to decrypt exchange response", error: error)
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

    private func acknowledgeExchangeResponse(_ exchangeResponse: ExchangeResponse, did: Did) {
        let ack = Dependencies.sudoDecentralizedIdentityClient.acknowledgement(
            did: did,
            serviceEndpoint: exchangeResponse.connection.didDoc.serviceEndpoint,
            exchangeResponse: exchangeResponse
        )
        // TODO: send the acknowledgement to the inviter.
    }

    private func createPairwise(exchangeRequest: ExchangeRequest, exchangeResponse: ExchangeResponse, invitation: Invitation, onSuccess: @escaping (Pairwise) -> Void) {
        let myDid = exchangeRequest.connection.didDoc.did
        let theirDid = exchangeResponse.connection.didDoc.did
        let label = invitation.label

        // The final service endpoint is a new endpoint where chats will be exchanged.
        let finalServiceEndpoint = exchangeResponse.connection.didDoc.serviceEndpoint

        Dependencies.sudoDecentralizedIdentityClient.createPairwise(
            walletId: walletId,
            theirDid: theirDid,
            theirVerkey: exchangeResponse.connection.didDoc.verKey,
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
                self.openPhotoPicker()
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
