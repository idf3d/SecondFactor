import Foundation
import CommonCrypto

enum CryptoAlgorithm {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512

    init(ykAlgo: YKAlgorithm) {
        switch ykAlgo {
        case .HMACSHA1:
            self = .SHA1
        case .HMACSHA256:
            self = .SHA256
        case .HMACSHA512:
            self = .SHA512
        }
    }

    var HMACAlgorithm: CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:      result = kCCHmacAlgMD5
        case .SHA1:     result = kCCHmacAlgSHA1
        case .SHA224:   result = kCCHmacAlgSHA224
        case .SHA256:   result = kCCHmacAlgSHA256
        case .SHA384:   result = kCCHmacAlgSHA384
        case .SHA512:   result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }

    var digestLength: Int {
        var result: Int32 = 0
        switch self {
        case .MD5:      result = CC_MD5_DIGEST_LENGTH
        case .SHA1:     result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:   result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:   result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:   result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:   result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}

extension Data {
    static func random(length: Int) -> Data {
        var result = Data()

        for _ in 0..<length {
            let r = arc4random_uniform(UInt32(UInt8.max))
            let b = UInt8(r)
            result.append(contentsOf: [b])
        }

        return result
    }

    static func timeChallenge(date: Date = Date(), interval: Int = 30) -> Data {
        let tRaw = date.timeIntervalSince1970 / Double(interval)
        let t = Int(round(tRaw)).bigEndian

        return withUnsafePointer(to: t) {
            Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
        }
    }

    init?(hexString: String) {
        self = Data(capacity: hexString.count / 2)
        var bString = ""

        for c in hexString {
            bString.append(c)
            if bString.count < 2 {
                continue
            }
            guard let byte = UInt8(bString, radix: 16) else {
                return nil
            }
            bString = ""
            self.append(byte)
        }

        if self.count == 0 {
            return nil
        }
    }

    func hmac(withKey key: Data, using algorithm: CryptoAlgorithm) -> Data {
        // Get data pointers
        var bytes = [UInt8](repeating:0, count: self.count)
        self.copyBytes(to: &bytes, count: self.count)

        var keyBytes = [UInt8](repeating:0, count:key.count)
        key.copyBytes(to: &keyBytes, count: key.count)

        var result = [UInt8](repeating: 0, count: Int(algorithm.digestLength))

        CCHmac(algorithm.HMACAlgorithm, keyBytes, key.count, bytes, self.count, &result)

        return Data(result)
    }

    func hexString() -> String {
        var bytes = [UInt8](repeating: 0, count: self.count)
        self.copyBytes(to: &bytes, count: self.count)

        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }

        return hexString
    }
}
