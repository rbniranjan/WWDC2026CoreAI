import CoreGraphics
import UIKit

struct ImagePreprocessor {
    struct ColorSignature {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let contrast: CGFloat
    }

    func colorSignature(for image: UIImage) -> ColorSignature {
        guard let cgImage = image.cgImage else {
            return ColorSignature(red: 0.33, green: 0.33, blue: 0.33, contrast: 0.15)
        }

        let width = 24
        let height = 24
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return ColorSignature(red: 0.33, green: 0.33, blue: 0.33, contrast: 0.15)
        }

        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var redTotal: CGFloat = 0
        var greenTotal: CGFloat = 0
        var blueTotal: CGFloat = 0
        var minLuma: CGFloat = 1
        var maxLuma: CGFloat = 0

        for offset in stride(from: 0, to: pixels.count, by: bytesPerPixel) {
            let red = CGFloat(pixels[offset]) / 255.0
            let green = CGFloat(pixels[offset + 1]) / 255.0
            let blue = CGFloat(pixels[offset + 2]) / 255.0
            redTotal += red
            greenTotal += green
            blueTotal += blue
            let luma = red * 0.2126 + green * 0.7152 + blue * 0.0722
            minLuma = min(minLuma, luma)
            maxLuma = max(maxLuma, luma)
        }

        let count = CGFloat(width * height)
        return ColorSignature(
            red: redTotal / count,
            green: greenTotal / count,
            blue: blueTotal / count,
            contrast: maxLuma - minLuma
        )
    }
}

