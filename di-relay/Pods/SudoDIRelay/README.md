# Sudo Decentralized Identity Relay iOS

SDK for interfacing with Sudo Platform Decentralized Identity Relay Service in iOS applications.

### Pod install

``` bash
$ bundle exec pod install
```

### Update GraphQL
To get the latest GraphQL schema from AWS, run the following command:
``` bash
$ ./get-latest-graphql-from-aws.sh -a <API_ID> [-r <REGION>]
```

Where API_ID is the AppSync API_ID. Then run:
``` bash
$ ./generate-client-graphql.sh
```
