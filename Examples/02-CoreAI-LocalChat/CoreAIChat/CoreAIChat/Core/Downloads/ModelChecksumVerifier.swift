import CryptoKit
import Foundation

struct ModelChecksumVerifier {
    enum VerificationError: Error, LocalizedError {
        case mismatch(expected: String, actual: String)

        var errorDescription: String? {
            switch self {
            case .mismatch(let expected, let actual):
                "Checksum mismatch. Expected \(expected), got \(actual)."
            }
        }
    }

    func sha256Hex(for data: Data) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }

    func verify(data: Data, expectedSHA256: String?) throws -> String {
        let actual = sha256Hex(for: data)
        guard let expectedSHA256, !expectedSHA256.isEmpty else {
            return actual
        }

        guard actual.lowercased() == expectedSHA256.lowercased() else {
            throw VerificationError.mismatch(expected: expectedSHA256, actual: actual)
        }

        return actual
    }

    func verify(fileURL: URL, expectedSHA256: String?) throws -> String {
        try verify(data: Data(contentsOf: fileURL), expectedSHA256: expectedSHA256)
    }
}
