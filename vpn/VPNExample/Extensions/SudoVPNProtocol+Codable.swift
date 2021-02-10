//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoVPN

extension SudoVPNProtocol: RawRepresentable, Codable {

    public typealias RawValue = String

    public init?(rawValue: String) {
        switch rawValue {
        case "l2tp":
            self = .l2tp
        case "pptp":
            self = .pptp
        case "ipsec":
            self = .ipsec
        case "ikev2":
            self = .ikev2
        case "openVpnUdp":
            self = .openVpnUdp
        case "openVpnTcp":
            self = .openVpnTcp
        case "wireGuard":
            self = .wireGuard
        default:
            self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .l2tp:
            return "l2tp"
        case .pptp:
            return "pptp"
        case .ipsec:
            return "ipsec"
        case .ikev2:
            return "ikev2"
        case .openVpnUdp:
            return "openVpnUdp"
        case .openVpnTcp:
            return "openVpnTcp"
        case .wireGuard:
            return "wireGuard"
        case .unknown(let string):
            return string ?? "unknown"
        }
    }
}
