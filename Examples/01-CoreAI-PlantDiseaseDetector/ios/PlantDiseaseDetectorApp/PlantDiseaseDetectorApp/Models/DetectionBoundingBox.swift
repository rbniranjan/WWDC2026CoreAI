import CoreGraphics
import Foundation

struct DetectionBoundingBox: Hashable {
    let normalizedRect: CGRect

    init(normalizedRect: CGRect) {
        let originX = min(max(normalizedRect.origin.x, 0), 1)
        let originY = min(max(normalizedRect.origin.y, 0), 1)
        let width = min(max(normalizedRect.size.width, 0), 1 - originX)
        let height = min(max(normalizedRect.size.height, 0), 1 - originY)
        self.normalizedRect = CGRect(x: originX, y: originY, width: width, height: height)
    }

    var summary: String {
        let x = normalizedRect.origin.x.formatted(.number.precision(.fractionLength(2)))
        let y = normalizedRect.origin.y.formatted(.number.precision(.fractionLength(2)))
        let width = normalizedRect.size.width.formatted(.number.precision(.fractionLength(2)))
        let height = normalizedRect.size.height.formatted(.number.precision(.fractionLength(2)))
        return "x:\(x) y:\(y) w:\(width) h:\(height) normalized"
    }
}

