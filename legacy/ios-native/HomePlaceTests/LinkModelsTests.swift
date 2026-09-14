import XCTest
@testable import HomePlace

final class LinkModelsTests: XCTestCase {
    func testSupportedProtocolRange() {
        let info = ServerInfo(
            product: "HomePlace",
            server: LinkServer(id: "9d55059f-5a47-4f23-a778-5714c6744907", name: "Our Home"),
            protocol: LinkProtocolRange(min: 1, max: 2),
            serverTime: "2026-09-13T12:00:00Z",
            features: LinkFeatures(pairing: false, realtime: false)
        )

        XCTAssertTrue(info.supportsClient)
    }

    func testUnsupportedProtocolRange() {
        let info = ServerInfo(
            product: "HomePlace",
            server: LinkServer(id: "9d55059f-5a47-4f23-a778-5714c6744907", name: "Our Home"),
            protocol: LinkProtocolRange(min: 2, max: 3),
            serverTime: "2026-09-13T12:00:00Z",
            features: LinkFeatures(pairing: false, realtime: false)
        )

        XCTAssertFalse(info.supportsClient)
    }

    func testDecodesCanonicalLinkInfo() throws {
        let json = """
        {"product":"HomePlace","server":{"id":"9d55059f-5a47-4f23-a778-5714c6744907","name":"Our Home"},"protocol":{"min":1,"max":1},"serverTime":"2026-09-13T12:00:00Z","features":{"pairing":false,"realtime":false}}
        """.data(using: .utf8)!

        let info = try JSONDecoder().decode(ServerInfo.self, from: json)

        XCTAssertTrue(info.supportsClient)
        XCTAssertEqual(info.serverName, "Our Home")
    }
}
