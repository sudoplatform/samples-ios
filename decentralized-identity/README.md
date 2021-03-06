# Sudo Decentralized Identity Sample App

## Overview
This project provides examples for interacting with the [Sudo Decentralized Identity iOS SDK](https://github.com/sudoplatform/sudo-decentralized-identity-ios) on the [Sudo Platform](https://sudoplatform.com/).

## Version Support
| Technology             | Supported version |
| ---------------------- | ----------------- |
| iOS Deployment Target  | 13.2+             |
| Swift language version | 5.0               |
| Xcode version          | 11.2+             |

## Getting Started
1. Run `pod install` from the project root.<br>
*Optional:* To avoid CocoaPods version conflicts, install bundler and use `bundle install && bundle exec pod install` instead.
2. Open `DecentralizedIdentityExample.xcworkspace` in Xcode.
3. In Project Settings > DecentralizedIdentityExample Target > Signing & Capabilities, choose a unique bundle identifier, e.g. `yourname.DecentralizedIdentityExample`.
3. If building to a physical device, select a Development Team from the same menu.
4. Run the app.
   - *Note:* When running the app on a physical device for the first time, you will be instructed to trust your developer account in the iOS settings app.
   - *Note:* Due to a bug only present in iOS 13.3.1, running the app on a physical device without a paid developer account will display a linker error at runtime. To avoid this, run the app on a device with iOS 13.3.0 or iOS 13.4+.

## Using the App
The sample app allows two devices to send encrypted messages back and forth.

One device creates an invitation in the form of a QR code, while the second device scans this invitation and initiates a handshake.

Creating an invitation requires providing a publicly accessible location for the _invitee_ device to upload data.
Likewise, scanning an invitation requires providing a publicly accessible location for the _inviter_ device to upload its response.

Currently, the sample app provisions these locations using a Firebase cloud function.

**You must manually configure a Firebase backend in order to create and scan invitations.**

### Creating and Configuring a Firebase Backend

1. Navigate to the [Firebase console](https://console.firebase.google.com/) and create a new project. Note that the "Spark" free plan can no longer be used to deploy this project's Cloud Functions.
2. Select the "Database" section of this new project and create a Cloud Firestore database.
   - Create this database in "Test Mode". Access control will be automatically configured as part of the deployment process.
3. Select the "Authentication" section and enable the "Anonymous" sign-in method.
4. Install the [Firebase CLI](https://firebase.google.com/docs/cli), e.g. via `npm install -g firebase-tools`.
5. Run `firebase login`. Authenticate using the same account used to create the Firebase project.
6. From the `firebase-agent` folder in the project root, run `firebase use --add`. Select the Firebase project you created.
7. Run `firebase deploy`. The deployment process may take a couple minutes.
   - *Note:* If this process fails, you may need to run `npm install` from the `firebase-agent/functions` directory.
8. In the Firebase console,  select the "Project Overview" section and configure a new iOS app within this project.
9. Enter the bundle ID you plan to use when running the app. For example, `yourname.DecentralizedIdentityExample`.
10. Download the generated `GoogleService-Info.plist` file and drag it into the `DecentralizedIdentityExample` folder in the Xcode project navigator.
<br>Ensure the `DecentralizedIdentityExample` target is checked in the "Add to targets" list when adding this file.
<br>You can bypass the remainder of the Firebase app creation flow.
11. Re-run the app. Your app is now configured to receive connection information.

### Establishing an Encrypted Connection

Follow these steps in order to establish a pairwise connection between two instances of the sample app running on different devices.

1. Follow the steps above to configure a Firebase backend. This is necessary to allow the devices to receive connection information.
   - The two devices used in the connection may each be using a different Firebase backend.
2. On one device, tap the "Get Started" button to create a new wallet and view an (initially empty) list of pairwise connections.
3. From the wallet screen, tap the "Create Pairwise Connection" button.
4. Select "Create Invitation". Provide a label that will be used to identify this device.
5. On a second device, select "Scan Invitation".
6. Provide a label that will identify this second device.
7. Scan the QR code that was generated by the first device.

A pairwise connection will then be negotiated between the two devices. This may take up to a minute.

Selecting this pairwise connection from the connection list will display a list of chat messages between the devices, and allow composing new encrypted messages.

### Establishing an Encrypted Connection with ACA-Py

Follow these steps in order to establish a pairwise connection between an instance of the sample app and an instance of ACA-Py.

1. Follow the installation instructions for [Hyperledger Aries Cloud Agent - Python](https://github.com/hyperledger/aries-cloudagent-python)
2. Run ACA-Py with support for inbound and outbound HTTP requests, as well as the Admin Controller. For example:
```
aca-py start --inbound-transport http 0.0.0.0 8000 \
             --outbound-transport http \
             --admin 0.0.0.0 8001 \
             --admin-insecure-mode \
             --log-level debug \
             --endpoint http://localhost:8000
```
3. Follow the above steps to create an invitation QR code in the sample app.
4. Instead of scanning this QR code on another device, tap the "Copy Raw Invitation" button.
   - *Note:* If using an iOS simulator, use the Edit > Get Pasteboard menu option to transfer the copied text to your computer.
5. Navigate to the ACA-Py Admin Controller in a web browser. In the above example, this would be http://localhost:8001.
6. In the ACA-Py Admin Controller, expand the `/connections/receive-invitation` menu. Click "Try it out".
7. Replace the contents of the "body" parameter with the invitation contents copied from the sample app.
8. Set the `auto_accept` parameter to false, then click "Execute".
9. Copy the value inside the quotes for the `connection_id` field displayed in the response body.
10. Expand `/connections/{conn_id}/accept-invitation` and click "Try it out". Use the copied connection ID as the `connection_id`.
<br>Enter a label that will identify this connection as the value for the `my_label` parameter, then click "Execute".
11. A pairwise connection will then be negotiated between the two agents. The sample app will return to the connection list screen.
12. Using the same connection ID from step 9, you can now send encrypted messages from ACA-Py to the sample app.
<br>Expand the `/connections/{conn-id}/send-message` menu under the `basicmessage` heading.
    - *Note:* ACA-Py does not appear to have support for displaying the basic messages it receives.
    <br>To test outgoing messages, try establishing a connection with another instance of the sample app as described above.

Note that ACA-Py separates the roles of the Agent (the entity receiving Agent-to-Agent messages) from the Controller (the interface that allows the user to direct the agent's behavior).
A similar separation is present in this sample app. The agent protocols are largely implemented in the Sudo Decentralized Identity iOS SDK, while the sample app provides a user-facing controller for those protocols.

In addition to creating an invitation that ACA-Py can accept, the sample app supports accepting an invitation generated by ACA-Py.

1. In the ACA-Py Admin Controller, expand `/connections/create-invitation`. Click "Try it out".
<br>Set the `auto_accept` parameter to either `true` or `false`, enter a label/`alias`, then click "Execute".
2. Copy the value inside the quotes for the `invitation_url` field displayed in the response body.
3. In the sample app, navigate to the "Scan Invitation" screen. Instead of scanning a QR code, tap the "Enter URL" button.
   - *Note:* If using an iOS simulator, use the Edit > Send Pasteboard menu option to transfer the copied text to the simulator.
4. Tap "Connect".
5. If the `auto_accept` parameter was set to `false`, accept the incoming connection request in the ACA-Py Controller.
   1. Expand the `/connections` menu, click "Try it out", then click "Execute".
   2. Look through the response body for a connection record in the "request" state.
   3. Copy the value inside the quotes for the `connection_id` field of this record.
   4. Use this connection ID to execute the `/connections/{conn_id}/accept-request` endpoint.
6. A pairwise connection will then be negotiated between the two agents. Messages can be sent from ACA-Py and viewed in the sample app as described above.

## More Documentation
Refer to the following documents for more information:

* [Sudo Platform Developer Docs](https://docs.sudoplatform.com)
* [Sudo Decentralized Identity iOS SDK](https://github.com/sudoplatform/sudo-decentralized-identity-ios)

## Issues and Support
File issues you find with this sample app in this GitHub repository. Ensure that you do not include any Personally Identifiable Information (PII), API keys, custom endpoints, etc. when reporting an issue.

For general questions about the Sudo Platform please contact [partners@sudoplatform.com](mailto:partners@sudoplatform.com)
