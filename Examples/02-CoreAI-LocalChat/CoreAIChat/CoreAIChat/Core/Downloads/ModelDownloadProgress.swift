import Foundation

struct ModelDownloadProgress: Equatable, Sendable {
    let bytesReceived: Int64
    let totalBytes: Int64?

    var fractionCompleted: Double {
        guard let totalBytes, totalBytes > 0 else { return 0 }
        return min(1, max(0, Double(bytesReceived) / Double(totalBytes)))
    }

    static let starting = ModelDownloadProgress(bytesReceived: 0, totalBytes: nil)
}
