import XCTest
@testable import ykoath

final class YKDerivedKeyTest: XCTestCase {
    let data = Data([0x0, 0xfa, 0xff, 0xae, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07])

    func testRawDataInit() {
        XCTAssertEqual(data, YKDerivedKey(data).keyData)
    }

    func testDerivedKey() {
        let key = YKDerivedKey(salt: data, password: "this is test password")
        let expected = Data([
            0xfb, 0xc6, 0xbc, 0x12, 0x6d, 
            0x89, 0x6d, 0x81, 0xd4, 0xa1,
            0x68, 0xe8, 0x97, 0x5f, 0xe8, 
            0xb2
        ])
        XCTAssertEqual(expected, key.keyData)
    }
}
