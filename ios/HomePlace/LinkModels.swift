import Foundation

let supportedLinkProtocol = 1

struct ServerInfo: Codable, Equatable {
    let serverId: String
    let serverName: String
    let protocolMin: Int
    let protocolMax: Int
    let serverTime: String?

    var supportsClient: Bool {
        !serverId.isEmpty &&
            !serverName.isEmpty &&
            (protocolMin...protocolMax).contains(supportedLinkProtocol)
    }
}

struct Capability: Codable, Equatable {
    let name: String
    let version: Int
    let constraints: [String: String]
}
