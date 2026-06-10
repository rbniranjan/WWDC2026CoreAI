import CoreGraphics

enum BoundingBoxMapper {
    static func aspectFitRect(for imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, containerSize.width > 0, containerSize.height > 0 else {
            return .zero
        }

        let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        let fittedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let origin = CGPoint(
            x: (containerSize.width - fittedSize.width) / 2,
            y: (containerSize.height - fittedSize.height) / 2
        )
        return CGRect(origin: origin, size: fittedSize)
    }

    static func mapNormalizedRect(
        _ normalizedRect: CGRect,
        imageSize: CGSize,
        containerSize: CGSize
    ) -> CGRect {
        let imageRect = aspectFitRect(for: imageSize, in: containerSize)
        return CGRect(
            x: imageRect.origin.x + normalizedRect.origin.x * imageRect.width,
            y: imageRect.origin.y + normalizedRect.origin.y * imageRect.height,
            width: normalizedRect.width * imageRect.width,
            height: normalizedRect.height * imageRect.height
        )
    }
}

