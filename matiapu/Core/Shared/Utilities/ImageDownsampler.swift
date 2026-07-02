//
//  ImageDownsampler.swift
//  matiapu
//

import ImageIO
import UIKit

enum ImageDownsampler {
    static func maxPixelSize(for pointSize: CGSize, scale: CGFloat) -> Int {
        let maxDimension = max(pointSize.width, pointSize.height)
        guard maxDimension.isFinite, maxDimension > 0 else { return 0 }
        return Int((maxDimension * scale).rounded(.up))
    }

    static func displayPixelSize(data: Data) -> CGSize? {
        pixelSize(from: CGImageSourceCreateWithData(data as CFData, imageSourceOptions()))
    }

    static func downsample(image: UIImage, maxPixelSize: Int) -> UIImage? {
        guard maxPixelSize > 0 else { return image }
        guard let data = image.jpegData(compressionQuality: 0.92) else { return nil }
        return downsample(data: data, maxPixelSize: maxPixelSize)
    }

    static func downsample(data: Data, maxPixelSize: Int) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, imageSourceOptions()) else {
            return nil
        }

        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    private static func imageSourceOptions() -> CFDictionary {
        [kCGImageSourceShouldCache: false] as CFDictionary
    }

    private static func pixelSize(from source: CGImageSource?) -> CGSize? {
        guard let source,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, imageSourceOptions()) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0 else {
            return nil
        }

        let pixelWidth = CGFloat(width)
        let pixelHeight = CGFloat(height)

        if let orientationRaw = properties[kCGImagePropertyOrientation] as? UInt32,
           let orientation = CGImagePropertyOrientation(rawValue: orientationRaw) {
            switch orientation {
            case .left, .leftMirrored, .right, .rightMirrored:
                return CGSize(width: pixelHeight, height: pixelWidth)
            default:
                break
            }
        }

        return CGSize(width: pixelWidth, height: pixelHeight)
    }
}
