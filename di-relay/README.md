# Sudo Decentralized Identity Relay Sample App
## Overview

This project provides examples for interacting with the Sudo DI Relay iOS SDK on the [Sudo Platform](https://sudoplatform.com/).

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

4. Run `pod install` from the project root

5. Build the app

## More Documentation

Refer to the following documents for more information:

- [Sudo Decentralized Identity Relay Docs](https://docs.sudoplatform.com/sudo-labs/decentralized-identity/relay-sdk)
- [Getting Started on Sudo Platform](https://docs.sudoplatform.com/guides/getting-started)
- [Understanding Decentralized Identity on Sudo Platform](https://docs.sudoplatform.com/sudo-labs/decentralized-identity)

## Issues and Support

File issues you find with this sample app in this Github repository. Ensure that you do not include any Personally Identifiable Information (PII), API keys, custom endpoints, etc. when reporting an issue.

For general questions about the Sudo Platform please contact [partners@sudoplatform.com](mailto:partners@sudoplatform.com).
