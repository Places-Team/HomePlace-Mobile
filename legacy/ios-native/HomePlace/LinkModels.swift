import Foundation

let supportedLinkProtocol = 1

struct ServerInfo: Codable, Equatable {
    let product: String
    let server: LinkServer
    let `protocol`: LinkProtocolRange
    let serverTime: String
    let features: LinkFeatures

    var serverId: String { server.id }
    var serverName: String { server.name }
    var protocolMin: Int { `protocol`.min }
    var protocolMax: Int { `protocol`.max }

    var supportsClient: Bool {
        product == "HomePlace" &&
            UUID(uuidString: server.id) != nil &&
            !server.name.isEmpty &&
            `protocol`.min <= `protocol`.max &&
            (`protocol`.min...`protocol`.max).contains(supportedLinkProtocol)
    }
}

struct LinkServer: Codable, Equatable {
    let id: String
    let name: String
}

struct LinkProtocolRange: Codable, Equatable {
    let min: Int
    let max: Int
}

struct LinkFeatures: Codable, Equatable {
    let pairing: Bool
    let realtime: Bool
}

struct Capability: Codable, Equatable {
    let name: String
    let version: Int
    let constraints: [String: String]
}
