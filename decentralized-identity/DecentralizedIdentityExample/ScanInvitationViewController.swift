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
        // Retrieve invitation data from the scanned the URL.
        retrieveInvitation(fromURLString: invitationURLString) { result in
            switch result {
            case .success(let invitation):
                // create an exchange request
                DispatchQueue.main.async {
                    self.presentedActivityAlert = self.presentActivityAlert(message: "Sending Request")
                }

                self.createAndTransmitExchangeRequest(inResponseTo: invitation) { exchangeRequest, newDid in
                    DispatchQueue.main.async {
                        self.presentedActivityAlert?.message = "Waiting for Response"
                    }

                    // wait for an exchange response
                    self.waitForExchangeResponse(to: exchangeRequest) { response in
                        DispatchQueue.main.async {
                            self.presentedActivityAlert?.message = "Creating Pairwise"
                        }

                        // acknowledge the response
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
            case .failure(let error):
                let title = "Failed to parse invitation URI"

                if case .invitationParameterNotPresent(.some(let url)) = error {
                    // if we didn't find an invitation but the URL is valid,
                    // ask the user to open the URL in Safari
                    self.presentOpenURLInSafari(
                        title: title,
                        message: error.localizedDescription,
                        url: url
                    )
                } else {
                    self.onFailure(title, error: error)
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

    /// An error returned from `retrieveInvitation(fromURLString:)`
    enum ParseInvitationURLStringError: Error, LocalizedError {
        /// The provided string was not a valid URI.
        case invalidURI

        /// Neither the provided URI nor any redirects from it contain an invitation query parameter.
        case invitationParameterNotPresent(URL?)

        /// Failed to decode the discovered invitation query parameter.
        case failedToDecodeInvitation(Error)

        var errorDescription: String? {
            switch self {
            case .invalidURI:
                return "Invalid URI"
            case .invitationParameterNotPresent:
                return "Invitation parameter not present"
            case .failedToDecodeInvitation(let error):
                return "Failed to decode invitation: \(error.localizedDescription)"
            }
        }
    }

    /// Attempts to retrieve an `Invitation` from the provided URL string.
    ///
    /// - Parameter urlString: URL string to decode.
    /// - Parameter resolvingRedirects: If this parameter is true and an invitation is not found within the given URL, will attempt to follow HTTP redirects from the URL to discover an invitation.
    /// - Parameter completion: Completion handler.
    private func retrieveInvitation(
        fromURLString urlString: String,
        resolvingRedirects: Bool = true,
        completion: @escaping (Result<Invitation, ParseInvitationURLStringError>) -> Void
    ) {
        guard let uri = URLComponents(string: urlString) else {
            return completion(.failure(.invalidURI))
        }

        /// Parses a URL encoded according to Aries RFC 0160 Standard Invitation Encoding.
        ///
        /// # Reference
        /// [Aries RFC 0160](https://github.com/hyperledger/aries-rfcs/tree/master/features/0160-connection-protocol#standard-invitation-encoding)
        let invitationFromURI: (URLComponents) -> Result<Invitation, ParseInvitationURLStringError>? = { uri in
            return uri.queryItems?
                .first(where: { $0.name == "c_i" })?
                .value
                .flatMap(Data.init(base64URLEncoded:))
                .map { invitationData in
                    // deserialize the invitation data
                    do {
                        let invitation = try JSONDecoder().decode(Invitation.self, from: invitationData)
                        return Result.success(invitation)
                    } catch let error {
                        return Result.failure(.failedToDecodeInvitation(error))
                    }
                }
        }

        // If the URI we're given contains an invitation parameter, attempt to decode it.
        if let invitationDataResult = invitationFromURI(uri) {
            return completion(invitationDataResult)
        }

        // Otherwise, assume the URI is an HTTP URL that redirects to an invitation URI.
        guard resolvingRedirects, ["http", "https"].contains(uri.scheme), let url = uri.url else {
            return completion(.failure(.invitationParameterNotPresent(nil)))
        }

        /// `URLSessionTaskDelegate` that calls a provided callback upon HTTP redirection.
        class BlockRedirectHandlingDelegate: NSObject, URLSessionTaskDelegate {
            let onRedirect: (URLRequest) -> Bool

            init(onRedirect: @escaping (URLRequest) -> Bool) {
                self.onRedirect = onRedirect
            }

            func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
                if onRedirect(request) {
                    completionHandler(request)
                } else {
                    completionHandler(nil)
                }
            }
        }

        var obtainedInvitation = false

        // Fire off an HTTP request that checks if we're redirected to an invitation URI.
        let session = URLSession(
            configuration: .default,
            delegate: BlockRedirectHandlingDelegate { request in
                if let newURL = request.url?.absoluteString,
                    let newURI = URLComponents(string: newURL),
                    let invitationDataResult = invitationFromURI(newURI) {

                    obtainedInvitation = true
                    completion(invitationDataResult)
                    return false
                } else {
                    return true
                }
            },
            delegateQueue: nil
        )

        let task = session.dataTask(with: url) { data, response, error in
            if !obtainedInvitation {
                completion(.failure(.invitationParameterNotPresent(url)))
            }
        }

        task.resume()
    }

    private func presentOpenURLInSafari(title: String, message: String, url: URL) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Open in Safari", style: .default) { action in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            })
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
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
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .withoutEscapingSlashes
                    plaintextRequestJson = try encoder.encode(exchangeRequest)
                } catch let error {
                    self.onFailure("Failed to encode exchange request", error: error)
                    return
                }

                guard !invitation.recipientKeys.isEmpty else {
                    self.onFailure("No recipient keys present in invitation", error: nil)
                    return
                }

                Dependencies.sudoDecentralizedIdentityClient.packMessage(
                    walletId: self.walletId,
                    message: plaintextRequestJson,
                    recipientVerkeys: invitation.recipientKeys,
                    senderVerkey: did.verkey
                ) { result in
                    switch result {
                    case .success(let encryptedForRecipientRequest):
                        DecentralizedIdentityExample.encryptForRoutingKeys(
                            walletId: self.walletId,
                            message: encryptedForRecipientRequest,
                            to: invitation.recipientKeys[0],
                            routingKeys: ArraySlice(invitation.routingKeys ?? [])
                        ) { result in
                            switch result {
                            case .success(let encryptedRequest):
                                let encryptedRequestJson: Data
                                do {
                                    let encoder = JSONEncoder()
                                    encoder.outputFormatting = [.withoutEscapingSlashes]
                                    encryptedRequestJson = try encoder.encode(encryptedRequest)
                                } catch let error {
                                    DispatchQueue.main.async {
                                        self.presentErrorAlert(message: "Failed to encode packed message", error: error)
                                    }
                                    return
                                }

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
                                self.onFailure("Failed to encrypt exchange request for intermediate routers", error: error)
                            }
                        }
                    case .failure(let error):
                        self.onFailure("Failed to encrypt exchange request", error: error)
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
        DecentralizedIdentityExample.createPairwise(
            walletId: walletId,
            label: invitation.label,
            myDid: exchangeRequest.connection.did,
            myDidDoc: exchangeRequest.connection.didDoc,
            theirDid: exchangeResponse.connection.did,
            theirDidDoc: exchangeResponse.connection.didDoc,
            onSuccess: onSuccess,
            onFailure: self.onFailure
        )
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
