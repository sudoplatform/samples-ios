//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import AVFoundation
import MobileCoreServices
import SudoDIRelay

class ScanInvitationViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Properties
    
    var postboxId: String!
    let relayClient: SudoDIRelayClient = AppDelegate.dependencies.sudoDIRelayClient

    // MARK: - Outlets

    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var previewView: VideoCapturePreviewView!
    
    // MARK: - Connection Establishment
    
    ///  Attempts to decode invitation data from the scanned URL, then generates an Invitation to send back to the peer.
    ///  Stores the peer's key and connection ID to the relevant data stores.
    ///  Once completed, segues to the connection view.
    ///
    ///  Called after the user scans a QR code.
    ///
    /// - Parameter invitationString: The string retrieved from the QR code.
    func handleInvitationObtained(_ invitationString: String) {
        // Retrieve invitation data from the scanned URL
        retrieveInvitation(invitationString: invitationString) { result in
            switch result {
            case .success(let invitation):
                guard let myConnectionDetails = self.generateDetailsToSend() else {
                    self.onFailure("Unable to generate connection details", error: nil)
                    return
                }
                
                DispatchQueue.main.async {
                    self.presentActivityAlert(message: "Sending Request")
                }
                self.storePeerPublicKeyToVault(invitation: invitation)
                self.storePeerConnectionIdToCache(peerConnectionId: invitation.connectionId)
                self.postToPeerEndpoint(detailsToPost: myConnectionDetails, peerConnectionId: invitation.connectionId) { result in
                    switch result {
                    case .success():
                        DispatchQueue.main.async {
                            self.dismiss(animated: true) {
                                self.performSegue(withIdentifier: "navigateToConnection", sender: self)
                            }
                        }
                    case .failure(let error):
                        let title = "Unable to send details"
                        self.onFailure(title, error: error)
                    }
                }
            case .failure(let error):
                let title = "Failed to parse invitation"
                self.onFailure(title, error: error)
            }
        }
    }

    /// Create an object to send to peer.
    /// Generates a public key pair via KeyManager, then creates an `Invitation` containing this connection ID and the
    /// newly generated public key.
    ///
    /// Displays an error alert if unable to generate the public key pair or retrieve the public key.
    ///
    /// - Returns: An invitation containing our connection ID and public key.
    private func generateDetailsToSend() -> Invitation? {
        // Generate and store public key pair
        do {
            try KeyManagement().createKeyPairForConnection(connectionId: postboxId)
        } catch {
            onFailure("Failed to generate public key pair", error: error)
            return nil
        }
        
        
        guard let myPublicKey = try? KeyManagement().getPublicKeyForConnection(connectionId: postboxId) else {
            onFailure("Failed to retrieve public key pair", error: nil)
            return nil
        }
        
        // Create a new Invitation object to transmit
        return Invitation(connectionId: postboxId, publicKey: myPublicKey)
    }
    
    /// Attempt to HTTP POST the `detailsToPost` containing our connection ID and public key  to the peer's endpoint.
    /// Encodes the invitation and encrypts the result before posting.
    /// Posts `detailsToPost` as base64 representation of the encrypted encoded data.
    ///
    /// Display an error alert if this is unsuccessful.
    ///
    /// - Parameters:
    ///   - detailsToPost: An Invitation containing our connection ID and public key.
    ///   - peerConnectionId: The peer's connection ID contained in the endpoint to POST to.
    ///   - completion: Resolves to a `Result`containing `Void` on .success and an `Error` on failure.
    private func postToPeerEndpoint(
        detailsToPost: Invitation,
        peerConnectionId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let invitationAsJson = try? JSONEncoder().encode(detailsToPost) else {
            onFailure("Failed to encode details to send to peer", error: nil)
            return
        }
        guard let jsonString = String(data: invitationAsJson, encoding: .utf8) else {
            return
        }
        
        guard let encryptedPayload = try? KeyManagement().packEncryptedMessageForPeer(
            peerConnectionId: peerConnectionId,
            message: jsonString
        ) else {
            onFailure("Failed to encrypt details to send to peer", error: nil)
            return
        }
        let encryptedMessageAsData = encryptedPayload.data(using: .utf8)

        guard let url = relayClient.getPostboxEndpoint(withConnectionId: peerConnectionId) else {
            onFailure("Unable to fetch peer's postbox endpoint", error: nil)
            return
        }

        // Post to endpoint
        HTTPTransports.transmit(
            data:  encryptedMessageAsData ?? invitationAsJson,
            to: url
        ) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                self.onFailure("Failed to transmit exchange request", error: error)
            }
        }
    }

    /// Attempts to retrieve an `Invitation` from the provided URL string.
    ///
    /// - Parameter invitationString: The invitation string to decode..
    /// - Parameter completion: Completion handler.
    private func retrieveInvitation(
        invitationString: String,
        completion: @escaping (Result<Invitation, ParseInvitationStringError>) -> Void
    ) {
        /// Parses a Invitation object
        do {
            guard let invitationAsData = invitationString.data(using: .utf8) else {
                return completion(.failure(.failedToDecodeInvitation(nil)))
            }
            let invitation = try JSONDecoder().decode(Invitation.self, from: invitationAsData)
            completion(.success(invitation))
        } catch {
            completion(.failure(.failedToDecodeInvitation(error)))
        }
    }


    // MARK: - AVFoundation Configuration

    private let captureSessionQueue = DispatchQueue(label: "com.sudoplatform.DIRelayExample.capturesession")
    private let metadataQueue = DispatchQueue(label: "com.sudoplatform.DIRelayExample.capturemetadata")
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

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
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

    // MARK: - UIImagePickerController Configuration

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

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        dismiss(animated: true, completion: nil)

        guard let pickedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
            presentErrorAlert(message: "Failed to retrieve selected image", error: nil)
            return
        }

        previewImageView.image = pickedImage

        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]),
            let ciImage = CIImage(image: pickedImage),
            let qrCodeFeature = (detector.features(in: ciImage).compactMap { $0 as? CIQRCodeFeature }).first,
            let string = qrCodeFeature.messageString else {
                presentErrorAlert(message: "Could not obtain QR code data from the selected image", error: nil)
                return
        }

        handleInvitationObtained(string)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - View

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
    
    /// Present an error alert containing `message` and the `error`.
    ///
    /// - Parameters:
    ///   - message: Message to display.
    ///   - error: Error containing a `localizedDescription` to display.
    private func onFailure(_ message: String, error: Error?) {
        DispatchQueue.main.async {
            if self.presentedViewController != nil {
                self.dismiss(animated: true) {
                    self.presentErrorAlert(message: message, error: error)
                }
            } else {
                self.presentErrorAlert(message: message, error: error)
            }
        }
    }
    
    // MARK: - Errors
    
    /// An error returned from `retrieveInvitation(_:)`.
    enum ParseInvitationStringError: Error, LocalizedError {
        /// The provided string was not a valid Connection object.
        case invalidConnection

        /// Failed to decode the discovered invitation query parameter.
        case failedToDecodeInvitation(Error?)

        var errorDescription: String? {
            switch self {
            case .invalidConnection:
                return "Invalid connection data received"
            case .failedToDecodeInvitation(let error):
                if let description = error?.localizedDescription {
                    return "Failed to decode invitation: " + description
                } else {
                    return  "Failed to decode invitation."
                }
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToConnection":
            let destination = segue.destination as! ConnectionViewController
            destination.myPostboxId = postboxId
        default:
            break
        }
    }
    
    // MARK: - Key Management
    
    /// Attempt to store the `peerConnectionId` in the KeychainConnectionStorage.
    /// Displays an error alert if unsuccessful.
    ///
    /// - Parameter peerConnectionId: Peer connection ID to store.
    private func storePeerConnectionIdToCache(peerConnectionId: String) {
        do {
            try KeychainConnectionStorage().store(peerConnectionId: peerConnectionId, for: postboxId)
        } catch {
            onFailure("Failed to store peer key pair to cache", error: error)
        }
    }
    
    /// Attempt to store the peer public key given by `invitation` via KeyManager.
    /// Display an errort alert if unsuccessful.
    ///
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
}

// MARK: - Video Capture

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
