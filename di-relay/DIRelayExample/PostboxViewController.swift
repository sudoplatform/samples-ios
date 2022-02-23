//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoDIRelay
import SudoUser

class PostboxViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties

    var postboxIds: [String] = []
    var currentRegistrationMethod: ChallengeType = .unknown
    private var presentedActivityAlert: UIAlertController?

    // MARK: - Properties: Computed

    var relayClient: SudoDIRelayClient {
        return AppDelegate.dependencies.sudoDIRelayClient
    }

    var sudoUserClient: SudoUserClient {
        return AppDelegate.dependencies.sudoUserClient
    }

    // MARK: - Outlets

    @IBOutlet weak var tableView: UITableView!

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }

    // MARK: - Table View

    /// Return the number of table rows.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postboxIds.count + 1
    }

    /// Return the title of the table.
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Active Postboxes"
    }

    /// Return a table cell either containing the button to create a postbox or a label containing the postbox ID.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "createPostboxCell", for: indexPath)
        } else {
            let postBoxId = postboxIds[indexPath.row - 1]
            let cell = tableView.dequeueReusableCell(withIdentifier: "postboxCell", for: indexPath)
            cell.textLabel?.text = postBoxId
            return cell
        }
    }
    
    /// After tapping on a row, if the `Create Postbox` button was tapped, attempt to provision a new postbox.
    /// If a postbox ID was tapped, either navigate to creating a new connection, or to the connection conversation screen.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.row == 0 {
            /// Clicked Create Postbox.
            createPostBoxAndSaveToCache()
            
        } else {
            // Clicked on an existing Postbox ID
            let postboxId = postboxIds[indexPath.row - 1]

            if let _ = try? KeyManagement().getPublicKeyForConnection(connectionId: postboxId) {
                // Peer has been connected
                performSegue(withIdentifier: "navigateToConnection", sender: postboxId)
            } else {
                // New connection
                performSegue(withIdentifier: "navigateToCreateConnection", sender: postboxId)
            }
        }
    }
    
    /// Swipe on an existing postbox ID to delete postbox.
    /// If swiping on the `Create Postbox` button, do nothing.
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.row > 0 {
            let postBoxId = postboxIds[indexPath.row - 1]
            let action = UIContextualAction(
                style: .normal,
                title: "Delete"
            ) { [weak self] (action, view, completionHandler) in
                self?.deletePostboxFromRelayAndCache(postBoxId: postBoxId)
                completionHandler(true)
            }
            action.backgroundColor = .systemRed
            return UISwipeActionsConfiguration(actions: [action])
        }
        return nil
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToConnection":
            let destination = segue.destination as! ConnectionViewController
            destination.myPostboxId = sender as? String ?? ""
        case "navigateToCreateConnection":
            let destination = segue.destination as! CreateConnectionViewController
            destination.postboxId = sender as? String
        case "unwindToWelcome":
            let destination = segue.destination as! WelcomeViewController
            // Propagate previous registration method to next registration/ sign in
            destination.previousRegistrationMethod = self.currentRegistrationMethod
        default:
            break
        }
    }

    // MARK: - Actions

    /// Create an alert allowing the user to choose whether to sign out, deregister, or cancel.
    ///
    /// Unknown registration method does not require deregistration.
    /// DeviceCheck, TEST and FSSO registration methods permit both deregistration and sign out.
    /// 
    /// Note that for FSSO deregistration, the user MUST still be signed in.
    ///
    /// - Parameter sender: Exit button.
    @IBAction func didTapExitButton(_ sender: Any) {
        let alert = UIAlertController(
            title: "Sign out or deregister",
            message: "Choose to sign out or deregister. Certain registration types may not require deregistration. \n The current registration method is \(currentRegistrationMethod).",
            preferredStyle: .actionSheet
        )
        let signOutOption = UIAlertAction(title: "Sign out", style: .default, handler: doSignOutAlertAction.self)
        let deregisterOption = UIAlertAction(title: "Deregister", style: .default, handler: doDeregisterAlertAction.self)

        // Disable for unknown registration
        switch currentRegistrationMethod {
        case .unknown:
            deregisterOption.isEnabled = false
        default:
            break
        }

        alert.addAction(signOutOption)
        alert.addAction(deregisterOption)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }

    // MARK: - Helpers
    
    /// Attempt to create a postbox via the `SudoDIRelayClient`, using a UUID4 generated `connectionId`.
    /// If successful, store the `connectionId` to the postbox ID storage cache.
    /// If unsuccessful, display the an error alert on the UI.
    func createPostBoxAndSaveToCache() {
        presentActivityAlert(message: "Creating postbox...")
        let connectionId = UUID().uuidString

        relayClient.createPostbox(withConnectionId: connectionId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    do {
                        try KeychainPostboxIdStorage().store(postboxId: connectionId)
                        self?.dismiss(animated: true) {
                            self?.updatePostboxView()
                        }
                    } catch {
                        self?.dismiss(animated: true) {
                            self?.presentErrorAlert(message: "Failed to store postbox id in cache", error: error)
                        }
                        return
                    }
                case let .failure(error):
                    self?.dismiss(animated: true) {
                        self?.presentErrorAlert(message: "Failed to create postbox in relay", error: error)
                    }
                }
            }
        }
    }
    
    /// Attempt to retrieve an updated list of the postbox IDs and refresh the table.
    /// If unsuccessful, does not refresh the table.
    func updatePostboxView() {
        guard let updatedPostboxIds = retrievePostboxIdsOrAlert() else { return }
        postboxIds = updatedPostboxIds
        tableView.reloadData()
    }
    
    /// Attempt to retrieve the list of postboxes from the postbox ID storage.
    /// If unsuccessful, display an error alert on the UI.
    ///
    /// - Returns: List of postbox IDs or  nil.
    func retrievePostboxIdsOrAlert() -> [String]? {
        switch Result(catching: {
            try KeychainPostboxIdStorage().retrieve()
        }) {
        case .success(.some(let ids)):
            return ids
        case .success(.none):
            self.dismiss(animated: true) {
                self.presentErrorAlert(message: "Failed to retrieve postboxes from cache:\nNot found")
            }
            return nil
        case .failure(let error):
            self.dismiss(animated: true) {
                self.presentErrorAlert(message: "Failed to retrieve postboxes in relay", error: error)
            }
            return nil
        }
    }
    
    /// Delete postbox in the relay via the `SudoDIRelayClient` and resent an activity alert on the UI.
    /// If unsuccessful, present an error alert.
    ///
    /// - Parameter postBoxId: postbox ID to delete.
    func deletePostboxFromRelayAndCache(postBoxId: String) {
        presentActivityAlert(message: "Deleting postbox...")
        relayClient.deletePostbox(withConnectionId: postBoxId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    KeychainPostboxIdStorage().delete(postBoxId: postBoxId)
                    self?.dismiss(animated: true) {
                        self?.updatePostboxView()
                    }
                case let .failure(error):
                    self?.dismiss(animated: true) {
                        self?.presentErrorAlert(message: "Failed to delete postbox from relay", error: error)
                    }
                }
            }
        }
    }

    // MARK: - Deregistration and Sign Out

    /// Proceed to sign out the user depending on registration method.
    ///
    /// - Parameter sender: Sign out option.
    func doSignOutAlertAction(sender: UIAlertAction) {
        switch currentRegistrationMethod {
        case .fsso:
            // Federated users should be signed out using the Federated UI
            fssoSignOut { fssoSignOutResult in
                switch fssoSignOutResult {
                case .success:
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "unwindToWelcome", sender: self)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.presentErrorAlert(message: "Could not sign out using federated account.", error: error)
                    }
                }
            }
        case .test:
            // Invalidate TEST registration keys to sign out
            self.signOutIfSignedIn { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "unwindToWelcome", sender: self)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.presentErrorAlert(message: "Could not sign out.", error: error)
                    }
                }
            }
        case .unknown, .deviceCheck:
            // Should not be able to sign out with DeviceCheck, but unwind to start
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "unwindToWelcome", sender: self)
            }
        }
    }

    /// Proceed to deregister the user depending on reigstration method.
    /// Delete postboxes from cache and backend upon deregistration.
    ///
    /// - Parameter sender: Deregister option.
    /// 
    func doDeregisterAlertAction(sender: UIAlertAction) {
        switch currentRegistrationMethod {
        case .deviceCheck, .fsso, .test:

            // Delete postboxes concurrently and only show error alert once done
            let dispatchGroup = DispatchGroup()
            var deleteErrors: [Error] = []
            postboxIds.forEach { postboxId in
                dispatchGroup.enter()
                relayClient.deletePostbox(withConnectionId: postboxId) { result in
                    if case .failure(let error) = result {
                        deleteErrors.append(error)
                    }
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) { [weak self] in
                if let error = deleteErrors.first {
                    self?.presentErrorAlert(message: "Could not delete all postboxes from backend.", error: error)
                }
            }

            KeychainPostboxIdStorage().deleteAllPostboxes()

            // Note: federated users should not ideally be deregistered in the Sudo Platform
            do {
                try self.sudoUserClient.deregister { deregisterResult in
                    switch deregisterResult {
                    case .success:
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "unwindToWelcome", sender: self)
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.presentErrorAlert(message: "Could not deregister.", error: error)
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.presentErrorAlert(message: "Could not deregister.", error: error)
                }
            }
        case .unknown:
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "unwindToWelcome", sender: self)
            }
        }
    }

    /// Present FSSO sign out window.
    ///
    /// - Parameter completion: `Void` upon success to sign out, `Error` upon failure.
    private func fssoSignOut(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            guard let presentationAnchor = self.view?.window else {
                fatalError("No window for \(String(describing: self))")
            }
            try sudoUserClient.presentFederatedSignOutUI(presentationAnchor: presentationAnchor) { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            // An error may be thrown if the backend is unable to perform
            // requested operation due to availability or security issues.
            // An error might be also be thrown for unrecoverable circumstances arising
            // from programmatic error or configuration error.
            completion(.failure(error))
        }
    }

    /// Check whether user is signed in. If signed in, sign out of all devices.
    ///
    /// - Parameter completion: `Void` upon successful sign out, `Error` upon failure.
    private func signOutIfSignedIn(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            guard try sudoUserClient.isSignedIn() else {
                // Was already signed out
                completion(.success(()))
                return
            }
            try sudoUserClient.globalSignOut { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            // Could not query whether signed in
            completion(.failure(error))
        }
    }
}
