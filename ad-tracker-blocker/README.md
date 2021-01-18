# Sudo Ad/Tracker Blocker iOS SDK

## Overview

This project provides examples for interacting with the Sudo Ad/Tracker Blocker SDK on the [Sudo Platform](https://sudoplatform.com/).

## Version Support

| Technology             | Supported version |
| ---------------------- | ----------------- |
| iOS Deployment Target  | 13.2+             |
| Swift language version | 5.0               |
| Xcode version          | 12.0+             |

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

## Running the app

App will build and run on the simulator out of the box, and physical devices will require some minor setup.

## Running on a physical device:

* Change the bundle identifier, e.g. "com.yourCompany.appName" so that Xcode can automatically create provisioning profiles. The existing bundle ID is owned by the sudo platform and cannot be used on another developer account.
* Set the development team. From the project navigator, choose the app target and select the "Signing and Capabilities" tab. You must be signed into your developer account through Xcode (About -> Preferences -> Account tab).
* Note: If using a personal account, the app may fail to run on the device if it's not trusted. In the settings app navigate to General -> Device Management -> Select developer account, e.g. "Apple development: yourEmail@yourDomain.com". From this screen you can trust the app and attempt to run again.

## More Documentation

Refer to the following documents for more information:

- [Getting Started on Sudo Platform](https://docs.sudoplatform.com/guides/getting-started)

## Issues and Support

File issues you find with this sample app in this Github repository. Ensure that you do not include any Personally Identifiable Information (PII), API keys, custom endpoints, etc. when reporting an issue.

For general questions about the Sudo Platform please contact [partners@sudoplatform.com](mailto:partners@sudoplatform.com)
