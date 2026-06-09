import CoreGraphics
import Foundation
import UIKit

struct MockPlantDiseaseDetector: PlantDiseaseDetectorProtocol {
    func predict(image: UIImage) async throws -> PlantDiseasePrediction {
        let metrics = image.leafColorMetrics()
        let greenAdvantage = metrics.green - max(metrics.red, metrics.blue)
        let brownBias = metrics.red - metrics.green * 0.55

        if abs(greenAdvantage) < 0.03 && abs(brownBias) < 0.03 {
            return PlantDiseasePrediction(
                label: "unknown_or_low_confidence",
                confidence: 0.42,
                runtime: .mockFallback
            )
        }

        if greenAdvantage >= brownBias {
            let confidence = min(max(0.60 + Double(greenAdvantage) * 1.8, 0.60), 0.96)
            return PlantDiseasePrediction(label: "healthy", confidence: confidence, runtime: .mockFallback)
        } else {
            let confidence = min(max(0.60 + Double(brownBias) * 1.6, 0.60), 0.94)
            return PlantDiseasePrediction(label: "unhealthy", confidence: confidence, runtime: .mockFallback)
        }
    }
}

private struct RGBMetrics {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
}

private extension UIImage {
    func leafColorMetrics() -> RGBMetrics {
        guard let cgImage = self.cgImage else {
            return RGBMetrics(red: 0.33, green: 0.33, blue: 0.33)
        }

        let width = 32
        let height = 32
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let totalBytes = height * bytesPerRow
        var pixels = [UInt8](repeating: 0, count: totalBytes)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return RGBMetrics(red: 0.33, green: 0.33, blue: 0.33)
        }

        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var redTotal: CGFloat = 0
        var greenTotal: CGFloat = 0
        var blueTotal: CGFloat = 0

        for offset in stride(from: 0, to: pixels.count, by: bytesPerPixel) {
            redTotal += CGFloat(pixels[offset]) / 255.0
            greenTotal += CGFloat(pixels[offset + 1]) / 255.0
            blueTotal += CGFloat(pixels[offset + 2]) / 255.0
        }

        let sampleCount = CGFloat(width * height)
        return RGBMetrics(
            red: redTotal / sampleCount,
            green: greenTotal / sampleCount,
            blue: blueTotal / sampleCount
        )
    }
}
