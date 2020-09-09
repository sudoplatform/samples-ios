# Sudo Telephony Sample App

## Overview

This project provides examples for interacting with the Sudo Telephony iOS SDK on the [Sudo Platform](https://sudoplatform.com/).

## Version Support

| Technology             | Supported version |
| ---------------------- | ----------------- |
| iOS Deployment Target  | 13.2+             |
| Swift language version | 5.0               |
| Xcode version          | 11.0+             |

## Getting Started

To build this app you first need to obtain test keys and a client config file and add them to the project.

1. Follow the steps in the [Getting Started guide](https://docs.sudoplatform.com/guides/getting-started) and in [User Registration](https://docs.sudoplatform.com/guides/users/registration) to obtain a config file (sudoplatformconfig.json) and a TEST registration key, respectively

2. Place both files in the following location with these names:

```
${PROJECT_DIR}/config/sudoplatformconfig.json
${PROJECT_DIR}/config/register_key.private
```

3. Create a text file containing the test registration key ID at the following location:

```
${PROJECT_DIR}/config/register_key.id
```

4. Run `pod install` from the project root<br>
*Optional:* To avoid CocoaPods version conflicts, install bundler and use `bundle install && bundle exec pod install` instead.

## Running the app

App will build and run on the simulator out of the box.  There are additional steps required to run on a physical device. Some features, e.g. incoming calls, require a physical device and additional setup. If you would like to enable this functionality, contact your solutions engineer to assist you in configuring your environments with push credentials for your applications.

## Running on a physical device:

* Change the bundle identifier, e.g. "com.yourCompany.sudoTelephonyExample" so that Xcode can automatically create provisioning profiles. The existing bundle ID is owned by the sudo platform and cannot be used on another developer account.
* Set the development team. From the project navigator, choose the "TelephonyExample" target and select the "Signing and Capabilities" tab. You must be signed into your developer account through Xcode (About -> Preferences -> Account tab). Some of the capabilities for incoming calls require a paid developer account. You can try out some features in the sample app with a personal account, however you must remove the "Push Notifications" capability (below Background modes section).
* Note: If using a personal account, the app may fail to run on the device if it's not trusted. In the settings app navigate to General -> Device Management -> Select developer account, e.g. "Apple development: yourEmail@yourDomain.com". From this screen you can trust the app and attempt to run again.

## Setup for incoming calls:

As mentioned previously, incoming calls require a paid developer account, along with some additional setup

* When selecting your development team, select your paid developer account
* Generate a voip push certificate

#### Generating a voip push certificate.
1. Ensure your app id in the Apple Developer Center has the "Push Notifications" capability under "Certificates, Identifiers & Profiler" (Xcode may have created this for you, if not you can manually create an app id)
2. Create a voip push certificate. See the section ["Prepare to Receive VoIP Push Notifications"](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/OptimizeVoIP.html) from Apple.
3. Provide push certificate and private key to your solutions engineer



## More Documentation

Refer to the following documents for more information:

- [Sudo Telephony Docs](https://docs.sudoplatform.com/guides/telephony)
- [Getting Started on Sudo Platform](https://docs.sudoplatform.com/guides/getting-started)
- [Understanding Sudo Digital Identities](https://docs.sudoplatform.com/concepts/sudo-digital-identities)

## Issues and Support

File issues you find with this sample app in this Github repository. Ensure that you do not include any Personally Identifiable Information (PII), API keys, custom endpoints, etc. when reporting an issue.

For general questions about the Sudo Platform please contact [partners@sudoplatform.com](mailto:partners@sudoplatform.com)
