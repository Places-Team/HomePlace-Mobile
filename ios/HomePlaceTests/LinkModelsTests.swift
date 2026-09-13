import XCTest
@testable import HomePlace

final class LinkModelsTests: XCTestCase {
    func testSupportedProtocolRange() {
        let info = ServerInfo(
            serverId: "home-01",
            serverName: "Our Home",
            protocolMin: 1,
            protocolMax: 2,
            serverTime: nil
        )

        XCTAssertTrue(info.supportsClient)
    }

    func testUnsupportedProtocolRange() {
        let info = ServerInfo(
            serverId: "home-01",
            serverName: "Our Home",
            protocolMin: 2,
            protocolMax: 3,
            serverTime: nil
        )

        XCTAssertFalse(info.supportsClient)
    }
}
