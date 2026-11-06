# Sudo Telephony Sample App

## Overview

This project provides examples for interacting with the Sudo Telephony iOS SDK on the [Sudo Platform](https://sudoplatform.com/).

## Version Support

| Technology             | Supported version |
| ---------------------- | ----------------- |
| iOS Deployment Target  | 18.0+             |
| Swift language version | 5.0               |
| Xcode version          | 26.0+             |

## Getting Started

To build this app you first need to obtain a client config file and add it to the project. The app supports signing in with either a TEST registration key or Federated Single Sign-On (FSSO), depending on the configuration of your Sudo Platform environment.

1. Follow the steps in the [Getting Started guide](https://docs.sudoplatform.com/guides/getting-started) to obtain a config file (sudoplatformconfig.json) and place it in the following location:

```
${PROJECT_DIR}/config/sudoplatformconfig.json
```

Choose how to sign in on the app's first screen: Test Keys uses a TEST registration key, Federated Sign In uses FSSO if your environment supports it.

2. If your environment uses TEST registration keys, follow the steps in [User Registration](https://docs.sudoplatform.com/guides/users/registration) to obtain a TEST registration key and place it in the following location:

```
${PROJECT_DIR}/config/register_key.private
```

3. Create a text file containing the test registration key ID at the following location:

```
${PROJECT_DIR}/config/register_key.id
```

4. Build the app

## Moving to Another Device

The keys that decrypt a user's Sudos and the messages sent to their phone numbers are kept on the device. To use the same account on another device, back the keys up on the first device and restore them on the second.

1. Sign in with Federated Sign In. Key backup isn't available with a TEST registration key, as each device that registers with one becomes a different user.
2. On the Home screen, open **Import/Export Keys** under Account and choose **Export**. Enter a password, then save or share the backup file.
3. On the other device, sign in as the same user, open **Import/Export Keys** and choose **Import**. Pick the backup file and enter its password.

The backup contains the user's Sudo keys and the keys for their phone numbers. It's protected only by its password, so keep the file and password safe. Importing a backup replaces the keys on the device it's imported on.

## More Documentation

Refer to the following documents for more information:

- [Getting Started on Sudo Platform](https://docs.sudoplatform.com/guides/getting-started)
- [User Registration](https://docs.sudoplatform.com/guides/users/registration)
- [Understanding Sudo Digital Identities](https://docs.sudoplatform.com/concepts/sudo-digital-identities)

## Issues and Support

File issues you find with this sample app in this Github repository. Ensure that you do not include any Personally Identifiable Information (PII), API keys, custom endpoints, etc. when reporting an issue.

For general questions about the Sudo Platform please contact [partners@sudoplatform.com](mailto:partners@sudoplatform.com)
